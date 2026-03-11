const test = require("node:test");
const assert = require("node:assert/strict");

const {
  assertArchivableProduct,
  assertCompletableReservation,
  assertReservableProduct,
  getSafeArchiveImagePath,
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
        merchantId: "merchant-1",
        status: "reserved",
      }, "merchant-2"),
      /permission-denied/,
  );
});

test("assertCompletableReservation rejects invalid status transitions", () => {
  assert.throws(
      () => assertCompletableReservation({
        merchantId: "merchant-1",
        status: "completed",
      }, "merchant-1"),
      /invalid-status/,
  );
});

test("assertCompletableReservation allows reserved status for the owner", () => {
  assert.doesNotThrow(() => assertCompletableReservation({
    merchantId: "merchant-1",
    status: "reserved",
  }, "merchant-1"));
});

test("assertArchivableProduct rejects non-owner archive attempts", () => {
  assert.throws(
      () => assertArchivableProduct({
        ownerId: "merchant-1",
      }, "merchant-2"),
      /permission-denied/,
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
