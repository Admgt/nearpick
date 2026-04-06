const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {
  assertArchivableProduct,
  assertCancelableReservation,
  assertCompletableReservation,
  assertExpirableReservation,
  assertRefundManageableReservation,
  assertReviewableReservation,
  assertRepriceableProduct,
  assertReservableProduct,
  buildPickupToken,
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
const {resolveNotificationSegment} = require("./notification_segments");

admin.initializeApp();

const VALID_CANCELLATION_REASON_CODES = new Set([
  "changed_mind",
  "pickup_time_issue",
  "found_other_offer",
  "ordered_by_mistake",
  "other",
]);

const VALID_REFUND_STATUSES = new Set([
  "not_requested",
  "pending",
  "approved",
  "rejected",
  "completed",
  "not_required",
]);

const MIN_REVIEW_COMMENT_LENGTH = 3;
const MAX_REVIEW_COMMENT_LENGTH = 280;

function normalizeOptionalText(value, {maxLength = 250} = {}) {
  if (typeof value !== "string") {
    return "";
  }

  const trimmed = value.trim();
  if (!trimmed) {
    return "";
  }

  return trimmed.slice(0, maxLength);
}

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
    case "invalid-pickup-code":
      return new HttpsError(
          "failed-precondition",
          "Ervenytelen atveteli kod.",
          details,
      );
    case "expired-reservation":
      return new HttpsError(
          "failed-precondition",
          "A foglalas mar lejart.",
          details,
      );
    case "not-expired-yet":
      return new HttpsError(
          "failed-precondition",
          "A foglalas meg nem jarhat le.",
          details,
      );
    case "permission-denied":
      return new HttpsError("permission-denied", "Nincs jogosultsag.", details);
    case "already-reviewed":
      return new HttpsError(
          "failed-precondition",
          "Ehhez a foglalashoz mar erkezett ertekeles.",
          details,
      );
    case "missing-pricing-recommendation":
      return new HttpsError(
          "failed-precondition",
          "Ehhez a termekhez nincs alkalmazhato arazasi javaslat.",
          details,
      );
    case "invalid-cancel-reason":
      return new HttpsError(
          "invalid-argument",
          "Ervenytelen lemondasi ok.",
          details,
      );
    case "invalid-refund-status":
      return new HttpsError(
          "invalid-argument",
          "Ervenytelen refund statusz.",
          details,
      );
    case "invalid-quantity":
      return new HttpsError(
          "invalid-argument",
          "Ervenytelen foglalasi mennyiseg.",
          details,
      );
    case "insufficient-quantity":
      return new HttpsError(
          "failed-precondition",
          "A kert mennyiseg nem erheto el.",
          details,
      );
    default:
      return new HttpsError("internal", "Varatlan szerverhiba.", details);
  }
}

async function expireDueReservations({limit = 50, contextId}) {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const query = await db
      .collection("reservations")
      .where("status", "==", "reserved")
      .where("expiresAt", "<=", now)
      .limit(limit)
      .get();

  if (query.empty) {
    return {expiredCount: 0};
  }

  let expiredCount = 0;
  for (const doc of query.docs) {
    try {
      await db.runTransaction(async (tx) => {
      const reservationRef = doc.ref;
      const reservationSnap = await tx.get(reservationRef);
      const reservation = reservationSnap.data();
      assertExpirableReservation({...reservation, id: reservationRef.id});

        const productId = reservation.productId;
        if (typeof productId !== "string" || productId.trim().length === 0) {
          tx.update(reservationRef, {
            status: "expired",
            expiredAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          return;
        }

        const productRef = db.collection("products").doc(productId.trim());
        const productSnap = await tx.get(productRef);
        const product = productSnap.data();
        if (!product || product.isDeleted === true) {
          tx.update(reservationRef, {
            status: "expired",
            expiredAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          return;
        }

        const currentAvailable =
          Number.isInteger(product.quantityAvailable) ?
            product.quantityAvailable :
            Number.isInteger(product.quantity) ? product.quantity : 0;
        const incrementBy = Number.isInteger(reservation.qty) ? reservation.qty : 1;
        const newAvailable = currentAvailable + incrementBy;
        const productExpiresAt =
          typeof product.expiresAt?.toDate === "function" ?
            product.expiresAt.toDate() :
            null;
        const nextStatus =
          productExpiresAt && productExpiresAt.getTime() <= Date.now() ?
            "expired" :
            newAvailable > 0 ? "active" : (product.status ?? "active");

        tx.update(productRef, {
          quantity: newAvailable,
          quantityAvailable: newAvailable,
          status: nextStatus,
        });
        tx.update(reservationRef, {
          status: "expired",
          expiredAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      expiredCount += 1;
    } catch (error) {
      logWarn("reservation.expire.skipped", {
        contextId,
        reservationId: doc.id,
      }, error);
    }
  }

  logInfo("reservation.expire.completed", {
    contextId,
    expiredCount,
  });
  return {expiredCount};
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
  const quantity = request.data?.quantity;
  if (typeof productId !== "string" || productId.trim().length === 0) {
    logWarn("reservation.reserve.invalid_argument", {contextId});
    throw new HttpsError("invalid-argument", "Ervenytelen productId.", {
      contextId,
    });
  }
  if (!Number.isInteger(quantity) || quantity <= 0) {
    logWarn("reservation.reserve.invalid_quantity", {
      contextId,
      productId,
      quantity,
    });
    throw new HttpsError("invalid-argument", "Ervenytelen mennyiseg.", {
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
      const {ownerId, quantityAvailable, requestedQuantity} =
        assertReservableProduct(product, buyerId, quantity);

      const newQty = quantityAvailable - requestedQuantity;
      const expiresAt = admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 60 * 1000),
      );
      const pickupCode = generatePickupCode(6);
      let merchantName =
        typeof product.merchantName === "string" ? product.merchantName.trim() : "";
      if (!merchantName) {
        const merchantSnap = await tx.get(db.collection("users").doc(ownerId));
        const merchantProfile = merchantSnap.data() ?? {};
        merchantName = normalizeOptionalText(
            merchantProfile.companyName ||
              merchantProfile.displayName ||
              merchantProfile.email,
            {maxLength: 120},
        );
      }

      const productSnapshot = {
        category: product.category ?? "",
        discountedPrice: Number.isInteger(product.discountedPrice) ?
          product.discountedPrice :
          0,
        expiresAt: product.expiresAt ?? null,
        imageUrl: typeof product.imageUrl === "string" ? product.imageUrl : null,
        merchantName,
        name: typeof product.name === "string" ? product.name : "",
        originalPrice: Number.isInteger(product.originalPrice) ?
          product.originalPrice :
          0,
        pickupEndAt: product.pickupEndAt ?? null,
        pickupStartAt: product.pickupStartAt ?? null,
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
        cancelReasonCode: null,
        cancelReasonNote: "",
        cancelledBy: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt,
        merchantId: ownerId,
        pickupCode,
        pickupToken: buildPickupToken(reservationRef.id, pickupCode),
        productId: trimmedProductId,
        productSnapshot,
        qty: requestedQuantity,
        refundCompletedAt: null,
        refundRequestedAt: null,
        refundReviewedAt: null,
        refundReviewedBy: null,
        refundStatus: "not_requested",
        reviewSubmittedAt: null,
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
    quantity,
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
  const pickupInput = request.data?.pickupInput;
  if (typeof reservationId !== "string" || reservationId.trim().length === 0) {
    logWarn("reservation.complete.invalid_argument", {contextId});
    throw new HttpsError("invalid-argument", "Ervenytelen reservationId.", {
      contextId,
    });
  }
  if (typeof pickupInput !== "string" || pickupInput.trim().length === 0) {
    logWarn("reservation.complete.invalid_pickup_input", {contextId});
    throw new HttpsError("invalid-argument", "Ervenytelen atveteli kod.", {
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

      assertCompletableReservation(
          {...reservation, id: reservationRef.id},
          merchantId,
          pickupInput,
      );

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

exports.cancelReservation = onCall(async (request) => {
  const contextId = createContextId(request);
  logInfo("reservation.cancel.started", {contextId});

  if (!request.auth) {
    logWarn("reservation.cancel.unauthenticated", {contextId});
    throw new HttpsError("unauthenticated", "Bejelentkezes szukseges.", {
      contextId,
    });
  }

  const reservationId = request.data?.reservationId;
  const reasonCode = request.data?.reasonCode;
  const reasonNote = normalizeOptionalText(request.data?.reasonNote);
  const refundRequested = request.data?.refundRequested === true;
  if (typeof reservationId !== "string" || reservationId.trim().length === 0) {
    logWarn("reservation.cancel.invalid_argument", {contextId});
    throw new HttpsError("invalid-argument", "Ervenytelen reservationId.", {
      contextId,
    });
  }
  if (!VALID_CANCELLATION_REASON_CODES.has(reasonCode)) {
    logWarn("reservation.cancel.invalid_reason", {contextId});
    throw asHttpsError(new Error("invalid-cancel-reason"), contextId);
  }

  const db = admin.firestore();
  const buyerId = request.auth.uid;

  try {
    await db.runTransaction(async (tx) => {
      const reservationRef = db.collection("reservations").doc(reservationId.trim());
      const reservationSnap = await tx.get(reservationRef);
      const reservation = reservationSnap.data();

      assertCancelableReservation(reservation, buyerId);

      const productId = reservation.productId;
      if (typeof productId !== "string" || productId.trim().length === 0) {
        tx.update(reservationRef, {
          cancelReasonCode: reasonCode,
          cancelReasonNote: reasonNote,
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
          cancelledBy: "buyer",
          refundCompletedAt: null,
          refundRequestedAt: refundRequested ?
            admin.firestore.FieldValue.serverTimestamp() :
            null,
          refundReviewedAt: null,
          refundReviewedBy: null,
          refundStatus: refundRequested ? "pending" : "not_requested",
          status: "cancelled",
        });
        return;
      }

      const productRef = db.collection("products").doc(productId.trim());
      const productSnap = await tx.get(productRef);
      const product = productSnap.data();
      if (!product || product.isDeleted === true) {
        tx.update(reservationRef, {
          cancelReasonCode: reasonCode,
          cancelReasonNote: reasonNote,
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
          cancelledBy: "buyer",
          refundCompletedAt: null,
          refundRequestedAt: refundRequested ?
            admin.firestore.FieldValue.serverTimestamp() :
            null,
          refundReviewedAt: null,
          refundReviewedBy: null,
          refundStatus: refundRequested ? "pending" : "not_requested",
          status: "cancelled",
        });
        return;
      }

      const currentAvailable =
        Number.isInteger(product.quantityAvailable) ?
          product.quantityAvailable :
          Number.isInteger(product.quantity) ? product.quantity : 0;
      const incrementBy = Number.isInteger(reservation.qty) ? reservation.qty : 1;
      const newAvailable = currentAvailable + incrementBy;
      const productExpiresAt =
        typeof product.expiresAt?.toDate === "function" ?
          product.expiresAt.toDate() :
          null;
      const nextStatus =
        productExpiresAt && productExpiresAt.getTime() <= Date.now() ?
          "expired" :
          newAvailable > 0 ? "active" : (product.status ?? "active");

      tx.update(productRef, {
        quantity: newAvailable,
        quantityAvailable: newAvailable,
        status: nextStatus,
      });
      tx.update(reservationRef, {
        cancelReasonCode: reasonCode,
        cancelReasonNote: reasonNote,
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        cancelledBy: "buyer",
        refundCompletedAt: null,
        refundRequestedAt: refundRequested ?
          admin.firestore.FieldValue.serverTimestamp() :
          null,
        refundReviewedAt: null,
        refundReviewedBy: null,
        refundStatus: refundRequested ? "pending" : "not_requested",
        status: "cancelled",
      });
    });
  } catch (error) {
    logError("reservation.cancel.failed", {
      contextId,
      reservationId: reservationId.trim(),
      userId: buyerId,
    }, error);
    throw asHttpsError(error, contextId);
  }

  logInfo("reservation.cancel.completed", {
    contextId,
    reservationId: reservationId.trim(),
    userId: buyerId,
  });
  return {
    cancelled: true,
    contextId,
  };
});

exports.updateRefundStatus = onCall(async (request) => {
  const contextId = createContextId(request);
  logInfo("reservation.refund_update.started", {contextId});

  if (!request.auth) {
    logWarn("reservation.refund_update.unauthenticated", {contextId});
    throw new HttpsError("unauthenticated", "Bejelentkezes szukseges.", {
      contextId,
    });
  }

  const reservationId = request.data?.reservationId;
  const refundStatus = normalizeOptionalText(request.data?.refundStatus, {
    maxLength: 32,
  });
  if (typeof reservationId !== "string" || reservationId.trim().length === 0) {
    logWarn("reservation.refund_update.invalid_argument", {contextId});
    throw new HttpsError("invalid-argument", "Ervenytelen reservationId.", {
      contextId,
    });
  }
  if (!VALID_REFUND_STATUSES.has(refundStatus)) {
    logWarn("reservation.refund_update.invalid_status", {contextId});
    throw asHttpsError(new Error("invalid-refund-status"), contextId);
  }

  const db = admin.firestore();
  const merchantId = request.auth.uid;

  try {
    await db.runTransaction(async (tx) => {
      const reservationRef = db.collection("reservations").doc(reservationId.trim());
      const reservationSnap = await tx.get(reservationRef);
      const reservation = reservationSnap.data();

      assertRefundManageableReservation(
          reservation,
          merchantId,
          refundStatus,
      );

      tx.update(reservationRef, {
        refundCompletedAt: refundStatus === "completed" ?
          admin.firestore.FieldValue.serverTimestamp() :
          null,
        refundReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        refundReviewedBy: merchantId,
        refundStatus,
      });
    });
  } catch (error) {
    logError("reservation.refund_update.failed", {
      contextId,
      reservationId: reservationId.trim(),
      refundStatus,
      userId: merchantId,
    }, error);
    throw asHttpsError(error, contextId);
  }

  logInfo("reservation.refund_update.completed", {
    contextId,
    reservationId: reservationId.trim(),
    refundStatus,
    userId: merchantId,
  });
  return {
    contextId,
    refundStatus,
    updated: true,
  };
});

exports.submitReview = onCall(async (request) => {
  const contextId = createContextId(request);
  logInfo("review.submit.started", {contextId});

  if (!request.auth) {
    logWarn("review.submit.unauthenticated", {contextId});
    throw new HttpsError("unauthenticated", "Bejelentkezes szukseges.", {
      contextId,
    });
  }

  const reservationId = request.data?.reservationId;
  const rating = request.data?.rating;
  const comment = normalizeOptionalText(request.data?.comment, {
    maxLength: MAX_REVIEW_COMMENT_LENGTH,
  });

  if (typeof reservationId !== "string" || reservationId.trim().length === 0) {
    logWarn("review.submit.invalid_reservation_id", {contextId});
    throw new HttpsError("invalid-argument", "Ervenytelen reservationId.", {
      contextId,
    });
  }

  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    logWarn("review.submit.invalid_rating", {contextId, rating});
    throw new HttpsError("invalid-argument", "Az ertekeles 1 es 5 kozotti egesz szam legyen.", {
      contextId,
    });
  }

  if (comment.length < MIN_REVIEW_COMMENT_LENGTH) {
    logWarn("review.submit.invalid_comment", {contextId});
    throw new HttpsError(
        "invalid-argument",
        "Az ertekeles megjegyzese legalabb 3 karakter legyen.",
        {contextId},
    );
  }

  const db = admin.firestore();
  const buyerId = request.auth.uid;
  const trimmedReservationId = reservationId.trim();

  try {
    await db.runTransaction(async (tx) => {
      const reservationRef = db.collection("reservations").doc(trimmedReservationId);
      const reviewRef = db.collection("reviews").doc(trimmedReservationId);
      const buyerRef = db.collection("users").doc(buyerId);
      const reservationSnap = await tx.get(reservationRef);
      const reviewSnap = await tx.get(reviewRef);
      const buyerSnap = await tx.get(buyerRef);
      const reservation = reservationSnap.data();
      const buyerProfile = buyerSnap.data() ?? {};

      assertReviewableReservation(reservation, buyerId);
      if (reviewSnap.exists) {
        throw new Error("already-reviewed");
      }

      const merchantId =
        typeof reservation.merchantId === "string" ? reservation.merchantId.trim() : "";
      if (!merchantId) {
        throw new Error("invalid-owner");
      }

      const merchantStatsRef = db.collection("merchantStats").doc(merchantId);
      const merchantStatsSnap = await tx.get(merchantStatsRef);
      const merchantStats = merchantStatsSnap.data() ?? {};
      const currentReviewCount =
        Number.isInteger(merchantStats.reviewCount) ? merchantStats.reviewCount : 0;
      const currentRatingTotal =
        Number.isInteger(merchantStats.ratingTotal) ? merchantStats.ratingTotal : 0;
      const nextReviewCount = currentReviewCount + 1;
      const nextRatingTotal = currentRatingTotal + rating;
      const buyerDisplayName = normalizeOptionalText(
          buyerProfile.displayName,
          {maxLength: 80},
      );
      const productName = normalizeOptionalText(
          reservation.productSnapshot?.name,
          {maxLength: 120},
      );

      tx.set(reviewRef, {
        buyerId,
        buyerDisplayName,
        comment,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        merchantId,
        productId: typeof reservation.productId === "string" ?
          reservation.productId.trim() :
          "",
        productName,
        rating,
        reservationId: trimmedReservationId,
      });

      tx.update(reservationRef, {
        reviewSubmittedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.set(merchantStatsRef, {
        averageRating: nextRatingTotal / nextReviewCount,
        ratingTotal: nextRatingTotal,
        reviewCount: nextReviewCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    });
  } catch (error) {
    logError("review.submit.failed", {
      contextId,
      reservationId: trimmedReservationId,
      userId: buyerId,
    }, error);
    throw asHttpsError(error, contextId);
  }

  logInfo("review.submit.completed", {
    contextId,
    reservationId: trimmedReservationId,
    userId: buyerId,
  });
  return {
    contextId,
    submitted: true,
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

exports.expireReservations = onSchedule("every 5 minutes", async (event) => {
  const contextId = createContextId(event);
  logInfo("reservation.expire.started", {contextId});

  try {
    await expireDueReservations({contextId, limit: 50});
  } catch (error) {
    logError("reservation.expire.failed", {contextId}, error);
    throw error;
  }
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

      const tokensBySegment = new Map();
      const segmentCounts = {};
      for (const userDoc of usersSnap.docs) {
        const uid = userDoc.id;
        if (uid === ownerId) continue;

        const [implicitPrefsSnap, negativePrefsSnap, tokenSnap] = await Promise.all([
          admin.firestore().collection("userImplicitPrefs").doc(uid).get(),
          admin.firestore().collection("userNegativePrefs").doc(uid).get(),
          admin
              .firestore()
              .collection("users")
              .doc(uid)
              .collection("fcmTokens")
              .get(),
        ]);

        const audience = resolveNotificationSegment({
          category,
          implicitPrefs: implicitPrefsSnap.data(),
          negativePrefs: negativePrefsSnap.data(),
          now: new Date(),
          userProfile: userDoc.data(),
        });
        if (!audience.eligible || !audience.segment) {
          continue;
        }

        segmentCounts[audience.segment] =
          (segmentCounts[audience.segment] ?? 0) + 1;
        const tokens = tokensBySegment.get(audience.segment) ?? [];
        tokenSnap.forEach((t) => {
          const token = t.data().token;
          if (token) tokens.push(token);
        });
        if (tokens.length > 0) {
          tokensBySegment.set(audience.segment, tokens);
        }
      }

      const tokenCount = Array.from(tokensBySegment.values())
          .reduce((sum, chunk) => sum + chunk.length, 0);

      if (tokenCount === 0) {
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
      for (const [segment, tokens] of tokensBySegment.entries()) {
        for (let i = 0; i < tokens.length; i += chunkSize) {
          const chunk = tokens.slice(i, i + chunkSize);
          const res = await admin.messaging().sendEachForMulticast({
            ...messageBase,
            data: {
              ...messageBase.data,
              segment,
            },
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
            segment,
          });
        }
      }

      logInfo("notification.product_created.completed", {
        category,
        contextId,
        ownerId,
        productId,
        segmentCounts,
        tokenCount,
      });
    },
);
