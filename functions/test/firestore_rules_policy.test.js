const test = require("node:test");
const assert = require("node:assert/strict");

function createAuth(uid) {
  return uid ? {uid} : null;
}

function canCreateProduct({auth, productId, data}) {
  const requiredKeys = [
    "archivedAt",
    "category",
    "createdAt",
    "deletedAt",
    "discountedPrice",
    "expiresAt",
    "hasImage",
    "imagePath",
    "imageUrl",
    "interestCount",
    "isDeleted",
    "location",
    "name",
    "originalPrice",
    "ownerId",
    "quantity",
    "quantityAvailable",
    "status",
  ];

  const keys = Object.keys(data).sort();
  return auth != null &&
    JSON.stringify(keys) === JSON.stringify([...requiredKeys].sort()) &&
    data.ownerId === auth.uid &&
    typeof data.name === "string" &&
    typeof data.category === "string" &&
    Number.isInteger(data.originalPrice) &&
    data.originalPrice >= 0 &&
    Number.isInteger(data.discountedPrice) &&
    data.discountedPrice >= 0 &&
    Number.isInteger(data.quantity) &&
    data.quantity > 0 &&
    Number.isInteger(data.quantityAvailable) &&
    data.quantityAvailable === data.quantity &&
    data.interestCount === 0 &&
    data.status === "active" &&
    data.isDeleted === false &&
    data.archivedAt === null &&
    data.deletedAt === null &&
    (
      data.hasImage === false ?
        data.imagePath === undefined && data.imageUrl === undefined :
        typeof data.imagePath === "string" &&
          data.imagePath === `products/${auth.uid}/${productId}/main.jpg` &&
          typeof data.imageUrl === "string"
    );
}

function canUpdateInterestCount({auth, before, after}) {
  const changedKeys = Object.keys(after).filter((key) => after[key] !== before[key]);
  return auth != null &&
    after.ownerId === before.ownerId &&
    JSON.stringify(changedKeys) === JSON.stringify(["interestCount"]) &&
    Number.isInteger(before.interestCount) &&
    Number.isInteger(after.interestCount) &&
    after.interestCount >= 0 &&
    (
      after.interestCount === before.interestCount + 1 ||
      after.interestCount === before.interestCount - 1
    );
}

function canReadReservation({auth, reservation}) {
  return auth != null &&
    (reservation.buyerId === auth.uid || reservation.merchantId === auth.uid);
}

function canReadMerchantStats({auth, merchantId}) {
  return auth != null && auth.uid === merchantId;
}

function canWriteUserDoc({auth, userId}) {
  return auth != null && auth.uid === userId;
}

function canCreateInterest({auth, data}) {
  return auth != null && data.userId === auth.uid;
}

test("product create policy engedi a saját képes termék létrehozását", () => {
  const allowed = canCreateProduct({
    auth: createAuth("merchant-1"),
    productId: "product-1",
    data: {
      archivedAt: null,
      category: "Pekseg",
      createdAt: "timestamp",
      deletedAt: null,
      discountedPrice: 500,
      expiresAt: "timestamp",
      hasImage: true,
      imagePath: "products/merchant-1/product-1/main.jpg",
      imageUrl: "https://example.test/products/merchant-1/product-1/main.jpg",
      interestCount: 0,
      isDeleted: false,
      location: null,
      name: "Bagel",
      originalPrice: 1000,
      ownerId: "merchant-1",
      quantity: 2,
      quantityAvailable: 2,
      status: "active",
    },
  });

  assert.equal(allowed, true);
});

test("product create policy tiltja az idegen ownerId-t", () => {
  const allowed = canCreateProduct({
    auth: createAuth("merchant-1"),
    productId: "product-1",
    data: {
      archivedAt: null,
      category: "Pekseg",
      createdAt: "timestamp",
      deletedAt: null,
      discountedPrice: 500,
      expiresAt: "timestamp",
      hasImage: false,
      interestCount: 0,
      isDeleted: false,
      location: null,
      name: "Bagel",
      originalPrice: 1000,
      ownerId: "merchant-2",
      quantity: 2,
      quantityAvailable: 2,
      status: "active",
    },
  });

  assert.equal(allowed, false);
});

test("reservation olvasás engedett a vásárlónak", () => {
  assert.equal(canReadReservation({
    auth: createAuth("buyer-1"),
    reservation: {buyerId: "buyer-1", merchantId: "merchant-1"},
  }), true);
});

test("reservation olvasás tiltott idegen felhasználónak", () => {
  assert.equal(canReadReservation({
    auth: createAuth("other-user"),
    reservation: {buyerId: "buyer-1", merchantId: "merchant-1"},
  }), false);
});

test("merchantStats olvasás csak saját kereskedőnek engedett", () => {
  assert.equal(canReadMerchantStats({
    auth: createAuth("merchant-1"),
    merchantId: "merchant-1",
  }), true);
  assert.equal(canReadMerchantStats({
    auth: createAuth("merchant-2"),
    merchantId: "merchant-1",
  }), false);
});

test("user dokumentum írás csak saját azonosítóval engedett", () => {
  assert.equal(canWriteUserDoc({
    auth: createAuth("user-1"),
    userId: "user-1",
  }), true);
  assert.equal(canWriteUserDoc({
    auth: createAuth("user-2"),
    userId: "user-1",
  }), false);
});

test("interest létrehozás csak saját userId-vel engedett", () => {
  assert.equal(canCreateInterest({
    auth: createAuth("consumer-1"),
    data: {userId: "consumer-1", productId: "product-1"},
  }), true);
  assert.equal(canCreateInterest({
    auth: createAuth("consumer-2"),
    data: {userId: "consumer-1", productId: "product-1"},
  }), false);
});

test("product create policy denies anonymous creation", () => {
  const allowed = canCreateProduct({
    auth: null,
    productId: "product-1",
    data: {
      archivedAt: null,
      category: "Pekseg",
      createdAt: "timestamp",
      deletedAt: null,
      discountedPrice: 500,
      expiresAt: "timestamp",
      hasImage: false,
      interestCount: 0,
      isDeleted: false,
      location: null,
      name: "Bagel",
      originalPrice: 1000,
      ownerId: "merchant-1",
      quantity: 2,
      quantityAvailable: 2,
      status: "active",
    },
  });

  assert.equal(allowed, false);
});

test("product create policy denies invalid owned image path", () => {
  const allowed = canCreateProduct({
    auth: createAuth("merchant-1"),
    productId: "product-1",
    data: {
      archivedAt: null,
      category: "Pekseg",
      createdAt: "timestamp",
      deletedAt: null,
      discountedPrice: 500,
      expiresAt: "timestamp",
      hasImage: true,
      imagePath: "products/merchant-2/product-1/main.jpg",
      imageUrl: "https://example.test/products/merchant-1/product-1/main.jpg",
      interestCount: 0,
      isDeleted: false,
      location: null,
      name: "Bagel",
      originalPrice: 1000,
      ownerId: "merchant-1",
      quantity: 2,
      quantityAvailable: 2,
      status: "active",
    },
  });

  assert.equal(allowed, false);
});

test("product update policy allows an isolated interestCount increment", () => {
  const allowed = canUpdateInterestCount({
    auth: createAuth("consumer-1"),
    before: {
      ownerId: "merchant-1",
      interestCount: 0,
      status: "active",
    },
    after: {
      ownerId: "merchant-1",
      interestCount: 1,
      status: "active",
    },
  });

  assert.equal(allowed, true);
});

test("product update policy denies extra field changes alongside interestCount", () => {
  const allowed = canUpdateInterestCount({
    auth: createAuth("consumer-1"),
    before: {
      ownerId: "merchant-1",
      interestCount: 0,
      status: "active",
    },
    after: {
      ownerId: "merchant-1",
      interestCount: 1,
      status: "sold_out",
    },
  });

  assert.equal(allowed, false);
});
