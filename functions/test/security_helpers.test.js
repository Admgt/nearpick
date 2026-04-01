const test = require("node:test");
const assert = require("node:assert/strict");

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
  getSafeArchiveImagePath,
  parsePickupInput,
} = require("../security_helpers");

test("assertReservableProduct rejects sold out products", () => {
  assert.throws(
      () => assertReservableProduct({
        ownerId: "merchant-1",
        quantityAvailable: 0,
        status: "active",
      }),
      /sold-out/,
  );
});

test("assertReservableProduct accepts active products with stock", () => {
  const result = assertReservableProduct({
    ownerId: "merchant-1",
    quantityAvailable: 2,
    status: "active",
  });

  assert.deepEqual(result, {
    ownerId: "merchant-1",
    quantityAvailable: 2,
  });
});

test("assertReservableProduct rejects expired products", () => {
  assert.throws(
      () => assertReservableProduct({
        expiresAt: new Date(Date.now() - 60_000),
        ownerId: "merchant-1",
        quantityAvailable: 1,
        status: "active",
      }, "buyer-1"),
      /unavailable/,
  );
});

test("assertReservableProduct rejects self reservation attempts", () => {
  assert.throws(
      () => assertReservableProduct({
        ownerId: "merchant-1",
        quantityAvailable: 1,
        status: "active",
      }, "merchant-1"),
      /self-reservation/,
  );
});

test("assertCompletableReservation rejects foreign merchant users", () => {
  assert.throws(
      () => assertCompletableReservation({
        id: "reservation-1",
        merchantId: "merchant-1",
        pickupCode: "ABC123",
        status: "reserved",
      }, "merchant-2", "ABC123"),
      /permission-denied/,
  );
});

test("assertCompletableReservation rejects invalid status transitions", () => {
  assert.throws(
      () => assertCompletableReservation({
        id: "reservation-1",
        merchantId: "merchant-1",
        pickupCode: "ABC123",
        status: "completed",
      }, "merchant-1", "ABC123"),
      /invalid-status/,
  );
});

test("assertCompletableReservation allows reserved status for the owner", () => {
  assert.doesNotThrow(() => assertCompletableReservation({
    id: "reservation-1",
    expiresAt: new Date(Date.now() + 60_000),
    merchantId: "merchant-1",
    pickupCode: "ABC123",
    status: "reserved",
  }, "merchant-1", "ABC123"));
});

test("assertCompletableReservation accepts a full pickup token", () => {
  const token = buildPickupToken("reservation-1", "ABC123");
  assert.doesNotThrow(() => assertCompletableReservation({
    id: "reservation-1",
    expiresAt: new Date(Date.now() + 60_000),
    merchantId: "merchant-1",
    pickupCode: "ABC123",
    status: "reserved",
  }, "merchant-1", token));
});

test("assertCompletableReservation rejects invalid pickup code", () => {
  assert.throws(
      () => assertCompletableReservation({
        id: "reservation-1",
        expiresAt: new Date(Date.now() + 60_000),
        merchantId: "merchant-1",
        pickupCode: "ABC123",
        status: "reserved",
      }, "merchant-1", "WRONG"),
      /invalid-pickup-code/,
  );
});

test("assertArchivableProduct rejects non-owner archive attempts", () => {
  assert.throws(
      () => assertArchivableProduct({
        ownerId: "merchant-1",
      }, "merchant-2"),
      /permission-denied/,
  );
});

test("assertRepriceableProduct returns the recommended price for owned products", () => {
  const result = assertRepriceableProduct({
    ownerId: "merchant-1",
    pricingRecommendation: {recommendedPrice: 650},
    status: "active",
  }, "merchant-1");

  assert.deepEqual(result, {
    recommendedPrice: 650,
  });
});

test("assertRepriceableProduct rejects missing recommendations", () => {
  assert.throws(
      () => assertRepriceableProduct({
        ownerId: "merchant-1",
        status: "active",
      }, "merchant-1"),
      /missing-pricing-recommendation/,
  );
});

test("assertCancelableReservation rejects foreign buyer users", () => {
  assert.throws(
      () => assertCancelableReservation({
        buyerId: "buyer-1",
        status: "reserved",
      }, "buyer-2"),
      /permission-denied/,
  );
});

test("assertCancelableReservation rejects expired reservations", () => {
  assert.throws(
      () => assertCancelableReservation({
        buyerId: "buyer-1",
        expiresAt: new Date(Date.now() - 60_000),
        status: "reserved",
      }, "buyer-1"),
      /expired-reservation/,
  );
});

test("assertRefundManageableReservation rejects non-cancelled reservations", () => {
  assert.throws(
      () => assertRefundManageableReservation({
        merchantId: "merchant-1",
        status: "reserved",
      }, "merchant-1", "pending"),
      /invalid-status/,
  );
});

test("assertRefundManageableReservation accepts cancelled reservations for the owner", () => {
  assert.doesNotThrow(() => assertRefundManageableReservation({
    merchantId: "merchant-1",
    status: "cancelled",
  }, "merchant-1", "approved"));
});

test("assertReviewableReservation rejects foreign buyer users", () => {
  assert.throws(
      () => assertReviewableReservation({
        buyerId: "buyer-1",
        status: "completed",
      }, "buyer-2"),
      /permission-denied/,
  );
});

test("assertReviewableReservation rejects non-completed reservations", () => {
  assert.throws(
      () => assertReviewableReservation({
        buyerId: "buyer-1",
        status: "reserved",
      }, "buyer-1"),
      /invalid-status/,
  );
});

test("assertReviewableReservation rejects already reviewed reservations", () => {
  assert.throws(
      () => assertReviewableReservation({
        buyerId: "buyer-1",
        reviewSubmittedAt: new Date(),
        status: "completed",
      }, "buyer-1"),
      /already-reviewed/,
  );
});

test("assertReviewableReservation accepts completed unreviewed reservations for the buyer", () => {
  assert.doesNotThrow(() => assertReviewableReservation({
    buyerId: "buyer-1",
    reviewSubmittedAt: null,
    status: "completed",
  }, "buyer-1"));
});

test("assertExpirableReservation rejects non-expired reservations", () => {
  assert.throws(
      () => assertExpirableReservation({
        expiresAt: new Date(Date.now() + 60_000),
        status: "reserved",
      }),
      /not-expired-yet/,
  );
});

test("parsePickupInput parses plain pickup codes and tokens", () => {
  assert.deepEqual(parsePickupInput("ABC123"), {
    pickupCode: "ABC123",
    reservationId: null,
  });
  assert.deepEqual(
      parsePickupInput("NEARPICK:reservation-1:ABC123"),
      {
        pickupCode: "ABC123",
        reservationId: "reservation-1",
      },
  );
});

test("getSafeArchiveImagePath accepts owned product image paths", () => {
  const imagePath = getSafeArchiveImagePath({
    imagePath: "products/merchant-1/product-1/main.jpg",
    ownerId: "merchant-1",
  }, "product-1", "merchant-1");

  assert.equal(imagePath, "products/merchant-1/product-1/main.jpg");
});

test("getSafeArchiveImagePath rejects foreign storage paths", () => {
  const imagePath = getSafeArchiveImagePath({
    imagePath: "products/merchant-2/product-9/main.jpg",
    ownerId: "merchant-1",
  }, "product-1", "merchant-1");

  assert.equal(imagePath, null);
});
