function generatePickupCode(length = 6) {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let result = "";
  for (let i = 0; i < length; i += 1) {
    result += chars[Math.floor(Math.random() * chars.length)];
  }
  return result;
}

function buildPickupToken(reservationId, pickupCode) {
  return `NEARPICK:${reservationId}:${pickupCode}`;
}

function parsePickupInput(rawInput) {
  const value = typeof rawInput === "string" ? rawInput.trim() : "";
  if (!value) {
    throw new Error("invalid-pickup-code");
  }

  if (!value.startsWith("NEARPICK:")) {
    return {
      pickupCode: value,
      reservationId: null,
    };
  }

  const parts = value.split(":");
  if (parts.length !== 3 || !parts[1] || !parts[2]) {
    throw new Error("invalid-pickup-code");
  }

  return {
    pickupCode: parts[2],
    reservationId: parts[1],
  };
}

function asDate(value) {
  if (!value) {
    return null;
  }

  if (value instanceof Date) {
    return value;
  }

  if (typeof value.toDate === "function") {
    return value.toDate();
  }

  return null;
}

function assertReservableProduct(product, callerUid) {
  if (!product) {
    throw new Error("not-found");
  }

  const status = product.status ?? "active";
  const isDeleted = product.isDeleted === true;
  const quantityAvailable =
    Number.isInteger(product.quantityAvailable) ?
      product.quantityAvailable :
      product.quantity;

  if (status !== "active" || isDeleted) {
    throw new Error("unavailable");
  }

  if (!Number.isInteger(quantityAvailable) || quantityAvailable <= 0) {
    throw new Error("sold-out");
  }

  const ownerId = typeof product.ownerId === "string" ? product.ownerId : "";
  if (!ownerId) {
    throw new Error("invalid-owner");
  }

  if (callerUid && ownerId === callerUid) {
    throw new Error("self-reservation");
  }

  const expiresAt = asDate(product.expiresAt);
  if (expiresAt && expiresAt.getTime() <= Date.now()) {
    throw new Error("unavailable");
  }

  return {
    ownerId,
    quantityAvailable,
  };
}

function assertCompletableReservation(reservation, callerUid, pickupInput) {
  if (!reservation) {
    throw new Error("not-found");
  }

  if (!callerUid || reservation.merchantId !== callerUid) {
    throw new Error("permission-denied");
  }

  if (reservation.status !== "reserved") {
    throw new Error("invalid-status");
  }

  const expiresAt = asDate(reservation.expiresAt);
  if (expiresAt && expiresAt.getTime() <= Date.now()) {
    throw new Error("expired-reservation");
  }

  const parsed = parsePickupInput(pickupInput);
  if (parsed.reservationId && parsed.reservationId !== reservation.id) {
    throw new Error("invalid-pickup-code");
  }
  if (reservation.pickupCode !== parsed.pickupCode) {
    throw new Error("invalid-pickup-code");
  }
}

function assertCancelableReservation(reservation, callerUid) {
  if (!reservation) {
    throw new Error("not-found");
  }

  if (!callerUid || reservation.buyerId !== callerUid) {
    throw new Error("permission-denied");
  }

  if (reservation.status !== "reserved") {
    throw new Error("invalid-status");
  }

  const expiresAt = asDate(reservation.expiresAt);
  if (expiresAt && expiresAt.getTime() <= Date.now()) {
    throw new Error("expired-reservation");
  }
}

function assertExpirableReservation(reservation) {
  if (!reservation) {
    throw new Error("not-found");
  }
  if (reservation.status !== "reserved") {
    throw new Error("invalid-status");
  }

  const expiresAt = asDate(reservation.expiresAt);
  if (!expiresAt || expiresAt.getTime() > Date.now()) {
    throw new Error("not-expired-yet");
  }
}

function assertArchivableProduct(product, callerUid) {
  if (!product) {
    throw new Error("not-found");
  }

  if (!callerUid || product.ownerId !== callerUid) {
    throw new Error("permission-denied");
  }
}

function assertRepriceableProduct(product, callerUid) {
  assertArchivableProduct(product, callerUid);

  const status = product.status ?? "active";
  const isDeleted = product.isDeleted === true;
  const recommendedPrice =
    Number.isInteger(product?.pricingRecommendation?.recommendedPrice) ?
      product.pricingRecommendation.recommendedPrice :
      null;

  if (status !== "active" || isDeleted) {
    throw new Error("unavailable");
  }
  if (!recommendedPrice) {
    throw new Error("missing-pricing-recommendation");
  }

  return {
    recommendedPrice,
  };
}

function getSafeArchiveImagePath(product, productId, callerUid) {
  assertArchivableProduct(product, callerUid);

  const imagePath =
    typeof product.imagePath === "string" ? product.imagePath.trim() : "";
  if (!imagePath) {
    return null;
  }

  const safePrefix = `products/${callerUid}/${productId}/`;
  if (!imagePath.startsWith(safePrefix)) {
    return null;
  }

  const fileName = imagePath.slice(safePrefix.length);
  if (!fileName || fileName.includes("/")) {
    return null;
  }

  return imagePath;
}

module.exports = {
  asDate,
  assertArchivableProduct,
  assertCancelableReservation,
  assertCompletableReservation,
  assertExpirableReservation,
  assertRepriceableProduct,
  assertReservableProduct,
  buildPickupToken,
  generatePickupCode,
  getSafeArchiveImagePath,
  parsePickupInput,
};
