const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {
  assertArchivableProduct,
  assertCompletableReservation,
  assertReservableProduct,
  generatePickupCode,
  getSafeArchiveImagePath,
} = require("./security_helpers");

admin.initializeApp();

function asHttpsError(error) {
  switch (error.message) {
    case "not-found":
      return new HttpsError("not-found", "A keresett eroforras nem talalhato.");
    case "sold-out":
      return new HttpsError("failed-precondition", "Elfogyott.");
    case "unavailable":
      return new HttpsError(
          "failed-precondition",
          "A termek mar nem erheto el.",
      );
    case "invalid-owner":
      return new HttpsError(
          "failed-precondition",
          "A termekhez nem tartozik ervenyes kereskedo.",
      );
    case "self-reservation":
      return new HttpsError(
          "failed-precondition",
          "A kereskedo nem foglalhatja a sajat termeket.",
      );
    case "invalid-status":
      return new HttpsError(
          "failed-precondition",
          "A foglalas allapota nem engedi a muveletet.",
      );
    case "permission-denied":
      return new HttpsError("permission-denied", "Nincs jogosultsag.");
    default:
      return new HttpsError("internal", "Varatlan szerverhiba.");
  }
}

exports.reserveProduct = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Bejelentkezes szukseges.");
  }

  const productId = request.data?.productId;
  if (typeof productId !== "string" || productId.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Ervenytelen productId.");
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
    throw asHttpsError(error);
  }

  return {
    reservationId: reservationRef.id,
  };
});

exports.completeReservation = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Bejelentkezes szukseges.");
  }

  const reservationId = request.data?.reservationId;
  if (typeof reservationId !== "string" || reservationId.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Ervenytelen reservationId.");
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
    throw asHttpsError(error);
  }

  return {
    completed: true,
  };
});

exports.archiveProduct = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Bejelentkezes szukseges.");
  }

  const productId = request.data?.productId;
  if (typeof productId !== "string" || productId.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Ervenytelen productId.");
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
    throw asHttpsError(error);
  }

  return {
    archived: true,
  };
});

exports.notifyOnNewProduct = onDocumentCreated(
    "products/{productId}",
    async (event) => {
      const snap = event.data;
      if (!snap) return;

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
        console.log("Nincs relevans user.");
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
        console.log("Nincs FCM token.");
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
        console.log(`Kuldes: ${chunk.length} token, failed: ${failed}`);
      }

      console.log(`Push elkuldve osszesen ${tokens.length} tokenre.`);
    },
);
