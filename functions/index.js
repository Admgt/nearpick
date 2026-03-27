const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const {
  assertArchivableProduct,
  assertCompletableReservation,
  assertRepriceableProduct,
  assertReservableProduct,
  generatePickupCode,
  getSafeArchiveImagePath,
} = require("./security_helpers");
const {
  buildHealthPayload,
  createContextId,
  logError,
  logInfo,
  logWarn,
} = require("./observability");

admin.initializeApp();

function asHttpsError(error, contextId) {
  const details = {contextId};
  switch (error.message) {
    case "not-found":
      return new HttpsError(
          "not-found",
          "A keresett eroforras nem talalhato.",
          details,
      );
    case "sold-out":
      return new HttpsError("failed-precondition", "Elfogyott.", details);
    case "unavailable":
      return new HttpsError(
          "failed-precondition",
          "A termek mar nem erheto el.",
          details,
      );
    case "invalid-owner":
      return new HttpsError(
          "failed-precondition",
          "A termekhez nem tartozik ervenyes kereskedo.",
          details,
      );
    case "self-reservation":
      return new HttpsError(
          "failed-precondition",
          "A kereskedo nem foglalhatja a sajat termeket.",
          details,
      );
    case "invalid-status":
      return new HttpsError(
          "failed-precondition",
          "A foglalas allapota nem engedi a muveletet.",
          details,
      );
    case "permission-denied":
      return new HttpsError("permission-denied", "Nincs jogosultsag.", details);
    case "missing-pricing-recommendation":
      return new HttpsError(
          "failed-precondition",
          "Ehhez a termekhez nincs alkalmazhato arazasi javaslat.",
          details,
      );
    default:
      return new HttpsError("internal", "Varatlan szerverhiba.", details);
  }
}

exports.healthcheck = onRequest(async (request, response) => {
  const contextId = createContextId(request);
  const startedAt = Date.now();
  let firestoreStatus = "ok";
  let status = "ok";
  let httpStatus = 200;

  try {
    await admin.firestore().collection("_healthcheck").limit(1).get();
  } catch (error) {
    firestoreStatus = "error";
    status = "degraded";
    httpStatus = 503;
    logError("healthcheck.firestore_unavailable", {
      component: "firestore",
      contextId,
    }, error);
  }

  const payload = buildHealthPayload({
    contextId,
    firestoreStatus,
    latencyMs: Date.now() - startedAt,
    status,
  });
  logInfo("healthcheck.completed", payload);
  response.status(httpStatus).json(payload);
});

exports.reserveProduct = onCall(async (request) => {
  const contextId = createContextId(request);
  logInfo("reservation.reserve.started", {contextId});

  if (!request.auth) {
    logWarn("reservation.reserve.unauthenticated", {contextId});
    throw new HttpsError("unauthenticated", "Bejelentkezes szukseges.", {
      contextId,
    });
  }

  const productId = request.data?.productId;
  if (typeof productId !== "string" || productId.trim().length === 0) {
    logWarn("reservation.reserve.invalid_argument", {contextId});
    throw new HttpsError("invalid-argument", "Ervenytelen productId.", {
      contextId,
    });
  }

  const db = admin.firestore();
  const buyerId = request.auth.uid;
  const trimmedProductId = productId.trim();
  const reservationRef = db.collection("reservations").doc();

  try {
    await db.runTransaction(async (tx) => {
      const productRef = db.collection("products").doc(trimmedProductId);
      const productSnap = await tx.get(productRef);
      const product = productSnap.data();
      const {ownerId, quantityAvailable} =
        assertReservableProduct(product, buyerId);

      const newQty = quantityAvailable - 1;
      const expiresAt = admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 60 * 1000),
      );

      const productSnapshot = {
        category: product.category ?? "",
        discountedPrice: Number.isInteger(product.discountedPrice) ?
          product.discountedPrice :
          0,
        expiresAt: product.expiresAt ?? null,
        imageUrl: typeof product.imageUrl === "string" ? product.imageUrl : null,
        name: typeof product.name === "string" ? product.name : "",
        originalPrice: Number.isInteger(product.originalPrice) ?
          product.originalPrice :
          0,
      };

      const productUpdates = {
        quantity: newQty,
        quantityAvailable: newQty,
      };
      if (newQty === 0) {
        productUpdates.status = "sold_out";
        productUpdates.soldOutAt = admin.firestore.FieldValue.serverTimestamp();
      }

      tx.update(productRef, productUpdates);
      tx.set(reservationRef, {
        buyerId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt,
        merchantId: ownerId,
        pickupCode: generatePickupCode(6),
        productId: trimmedProductId,
        productSnapshot,
        qty: 1,
        status: "reserved",
      });

      const statsRef = db.collection("merchantStats").doc(ownerId);
      const statsUpdate = {
        reservedCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (newQty === 0) {
        statsUpdate.soldOutCount = admin.firestore.FieldValue.increment(1);
      }
      tx.set(statsRef, statsUpdate, {merge: true});
    });
  } catch (error) {
    logError("reservation.reserve.failed", {
      contextId,
      productId: trimmedProductId,
      userId: buyerId,
    }, error);
    throw asHttpsError(error, contextId);
  }

  logInfo("reservation.reserve.completed", {
    contextId,
    productId: trimmedProductId,
    reservationId: reservationRef.id,
    userId: buyerId,
  });
  return {
    contextId,
    reservationId: reservationRef.id,
  };
});

exports.completeReservation = onCall(async (request) => {
  const contextId = createContextId(request);
  logInfo("reservation.complete.started", {contextId});

  if (!request.auth) {
    logWarn("reservation.complete.unauthenticated", {contextId});
    throw new HttpsError("unauthenticated", "Bejelentkezes szukseges.", {
      contextId,
    });
  }

  const reservationId = request.data?.reservationId;
  if (typeof reservationId !== "string" || reservationId.trim().length === 0) {
    logWarn("reservation.complete.invalid_argument", {contextId});
    throw new HttpsError("invalid-argument", "Ervenytelen reservationId.", {
      contextId,
    });
  }

  const db = admin.firestore();
  const merchantId = request.auth.uid;

  try {
    await db.runTransaction(async (tx) => {
      const reservationRef = db.collection("reservations").doc(reservationId.trim());
      const reservationSnap = await tx.get(reservationRef);
      const reservation = reservationSnap.data();

      assertCompletableReservation(reservation, merchantId);

      tx.update(reservationRef, {
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "completed",
      });

      const statsRef = db.collection("merchantStats").doc(merchantId);
      tx.set(statsRef, {
        completedCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
       }, {merge: true});
    });
  } catch (error) {
    logError("reservation.complete.failed", {
      contextId,
      reservationId: reservationId.trim(),
      userId: merchantId,
    }, error);
    throw asHttpsError(error, contextId);
  }

  logInfo("reservation.complete.completed", {
    contextId,
    reservationId: reservationId.trim(),
    userId: merchantId,
  });
  return {
    completed: true,
    contextId,
  };
});

exports.archiveProduct = onCall(async (request) => {
  const contextId = createContextId(request);
  logInfo("product.archive.started", {contextId});

  if (!request.auth) {
    logWarn("product.archive.unauthenticated", {contextId});
    throw new HttpsError("unauthenticated", "Bejelentkezes szukseges.", {
      contextId,
    });
  }

  const productId = request.data?.productId;
  if (typeof productId !== "string" || productId.trim().length === 0) {
    logWarn("product.archive.invalid_argument", {contextId});
    throw new HttpsError("invalid-argument", "Ervenytelen productId.", {
      contextId,
    });
  }

  const db = admin.firestore();
  const uid = request.auth.uid;
  const trimmedProductId = productId.trim();
  let imagePath = null;

  try {
    await db.runTransaction(async (tx) => {
      const productRef = db.collection("products").doc(trimmedProductId);
      const productSnap = await tx.get(productRef);
      const product = productSnap.data();

      assertArchivableProduct(product, uid);
      imagePath = getSafeArchiveImagePath(product, trimmedProductId, uid);

      tx.update(productRef, {
        archivedAt: admin.firestore.FieldValue.serverTimestamp(),
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        hasImage: false,
        isDeleted: true,
        imagePath: admin.firestore.FieldValue.delete(),
        imageUrl: admin.firestore.FieldValue.delete(),
        status: "archived",
      });
    });

    if (imagePath) {
      await admin.storage().bucket().file(imagePath).delete({ignoreNotFound: true});
    }
  } catch (error) {
    logError("product.archive.failed", {
      contextId,
      productId: trimmedProductId,
      userId: uid,
    }, error);
    throw asHttpsError(error, contextId);
  }

  logInfo("product.archive.completed", {
    contextId,
    productId: trimmedProductId,
    userId: uid,
  });
  return {
    archived: true,
    contextId,
  };
});

exports.repriceProduct = onCall(async (request) => {
  const contextId = createContextId(request);
  logInfo("product.reprice.started", {contextId});

  if (!request.auth) {
    logWarn("product.reprice.unauthenticated", {contextId});
    throw new HttpsError("unauthenticated", "Bejelentkezes szukseges.", {
      contextId,
    });
  }

  const productId = request.data?.productId;
  if (typeof productId !== "string" || productId.trim().length === 0) {
    logWarn("product.reprice.invalid_argument", {contextId});
    throw new HttpsError("invalid-argument", "Ervenytelen productId.", {
      contextId,
    });
  }

  const db = admin.firestore();
  const uid = request.auth.uid;
  const trimmedProductId = productId.trim();
  let recommendedPrice = null;

  try {
    await db.runTransaction(async (tx) => {
      const productRef = db.collection("products").doc(trimmedProductId);
      const productSnap = await tx.get(productRef);
      const product = productSnap.data();

      ({recommendedPrice} = assertRepriceableProduct(product, uid));

      tx.update(productRef, {
        discountedPrice: recommendedPrice,
        "pricingRecommendation.lastAppliedAt":
          admin.firestore.FieldValue.serverTimestamp(),
        "pricingRecommendation.lastAppliedPrice": recommendedPrice,
      });
    });
  } catch (error) {
    logError("product.reprice.failed", {
      contextId,
      productId: trimmedProductId,
      userId: uid,
    }, error);
    throw asHttpsError(error, contextId);
  }

  logInfo("product.reprice.completed", {
    contextId,
    productId: trimmedProductId,
    recommendedPrice,
    userId: uid,
  });
  return {
    contextId,
    discountedPrice: recommendedPrice,
    repriced: true,
  };
});

exports.notifyOnNewProduct = onDocumentCreated(
    "products/{productId}",
    async (event) => {
      const contextId = createContextId(event);
      const snap = event.data;
      if (!snap) {
        logWarn("notification.product_created.missing_snapshot", {contextId});
        return;
      }

      const product = snap.data();
      const productId = event.params.productId;

      const category = product.category;
      const ownerId = product.ownerId;

      const usersSnap = await admin
          .firestore()
          .collection("users")
          .where("role", "==", "consumer")
          .where("favoriteCategories", "array-contains", category)
          .get();

      if (usersSnap.empty) {
        logInfo("notification.product_created.no_recipients", {
          category,
          contextId,
          ownerId,
          productId,
        });
        return;
      }

      const tokens = [];
      for (const userDoc of usersSnap.docs) {
        const uid = userDoc.id;
        if (uid === ownerId) continue;

        const tokenSnap = await admin
            .firestore()
            .collection("users")
            .doc(uid)
            .collection("fcmTokens")
            .get();

        tokenSnap.forEach((t) => {
          const token = t.data().token;
          if (token) tokens.push(token);
        });
      }

      if (tokens.length === 0) {
        logInfo("notification.product_created.no_tokens", {
          category,
          contextId,
          ownerId,
          productId,
          recipientCount: usersSnap.docs.length,
        });
        return;
      }

      const messageBase = {
        notification: {
          title: "Uj ajanlat a NearPicken!",
          body: `${product.name} - ${product.discountedPrice} Ft`,
        },
        data: {
          productId,
          category: category || "",
        },
      };

      const chunkSize = 500;
      for (let i = 0; i < tokens.length; i += chunkSize) {
        const chunk = tokens.slice(i, i + chunkSize);
        const res = await admin.messaging().sendEachForMulticast({
          ...messageBase,
          tokens: chunk,
        });

        const failed = res.responses.filter((r) => !r.success).length;
        logInfo("notification.product_created.chunk_sent", {
          category,
          chunkSize: chunk.length,
          contextId,
          failedCount: failed,
          ownerId,
          productId,
        });
      }

      logInfo("notification.product_created.completed", {
        category,
        contextId,
        ownerId,
        productId,
        tokenCount: tokens.length,
      });
    },
);
