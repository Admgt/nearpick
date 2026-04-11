const test = require("node:test");
const assert = require("node:assert/strict");

function createAuth(uid, options = {}) {
  if (!uid) return null;
  return {
    uid,
    token: options.token ?? {},
    profileRole: options.profileRole ?? "consumer",
    accountStatus: options.accountStatus ?? "active",
  };
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
    "hasReservations",
    "imagePath",
    "imageUrl",
    "interestCount",
    "isDeleted",
    "location",
    "merchantName",
    "name",
    "originalPrice",
    "ownerId",
    "pickupEndAt",
    "pickupStartAt",
    "quantity",
    "quantityAvailable",
    "status",
  ];
  const optionalKeys = [
    "imagePath",
    "imageUrl",
    "location",
    "pricingRecommendation",
  ];

  const keys = Object.keys(data).sort();
  return auth != null &&
    auth.profileRole === "merchant" &&
    auth.accountStatus === "active" &&
    requiredKeys.every((key) => keys.includes(key)) &&
    keys.every((key) => [...requiredKeys, ...optionalKeys].includes(key)) &&
    data.ownerId === auth.uid &&
    typeof data.merchantName === "string" &&
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
    data.pickupStartAt === "timestamp" &&
    data.pickupEndAt === "timestamp" &&
    data.interestCount === 0 &&
    data.status === "active" &&
    data.isDeleted === false &&
    data.hasReservations === false &&
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

function canUpdateOwnedProduct({auth, before, after}) {
  return auth != null &&
    before.ownerId === auth.uid &&
    before.hasReservations !== true &&
    after.ownerId === before.ownerId &&
    after.merchantName === before.merchantName &&
    after.createdAt === before.createdAt &&
    after.interestCount === before.interestCount &&
    after.status === before.status &&
    after.isDeleted === before.isDeleted &&
    after.archivedAt === before.archivedAt &&
    after.deletedAt === before.deletedAt &&
    typeof after.name === "string" &&
    typeof after.category === "string" &&
    Number.isInteger(after.originalPrice) &&
    after.originalPrice >= 0 &&
    Number.isInteger(after.discountedPrice) &&
    after.discountedPrice >= 0 &&
    Number.isInteger(after.quantity) &&
    after.quantity > 0 &&
    Number.isInteger(after.quantityAvailable) &&
    after.quantityAvailable === after.quantity &&
    after.expiresAt === "timestamp" &&
    after.pickupStartAt === "timestamp" &&
    after.pickupEndAt === "timestamp" &&
    after.hasReservations === false;
}

function canReadReservation({auth, reservation}) {
  return auth != null &&
    (
      (auth.token.admin === true && auth.accountStatus === "active") ||
      (
        auth.accountStatus === "active" &&
        (reservation.buyerId === auth.uid || reservation.merchantId === auth.uid)
      )
    );
}

function canReadMerchantStats({auth, merchantId}) {
  return auth != null &&
    (
      auth.accountStatus === "active" ||
      (auth.token.admin === true && auth.accountStatus === "active")
    );
}

function canReadReview({auth, review}) {
  return auth != null &&
    (
      auth.accountStatus === "active" ||
      (auth.token.admin === true && auth.accountStatus === "active")
    );
}

function canCreateUserDoc({auth, userId, data}) {
  return auth != null &&
    auth.uid === userId &&
    data.accountStatus === "active" &&
    typeof data.email === "string" &&
    typeof data.displayName === "string" &&
    ["consumer", "merchant"].includes(data.role);
}

function canUpdateOwnUserDoc({auth, userId, before, after}) {
  const changedKeys = Object.keys(after).filter((key) => after[key] !== before[key]);
  return auth != null &&
    auth.uid === userId &&
    auth.accountStatus === "active" &&
    changedKeys.every((key) => [
      "companyLocation",
      "companyName",
      "displayName",
      "favoriteCategories",
      "homeLocation",
      "homeLocationCityId",
      "homeLocationMode",
      "preferredRadiusKm",
    ].includes(key)) &&
    after.email === before.email &&
    after.role === before.role &&
    after.accountStatus === before.accountStatus &&
    after.createdAt === before.createdAt;
}

function canCreateInterest({auth, data}) {
  return auth != null &&
    auth.accountStatus === "active" &&
    data.userId === auth.uid;
}

function canReadAdminMessage({auth, userId}) {
  return auth != null &&
    (
      (auth.token.admin === true && auth.accountStatus === "active") ||
      (auth.uid === userId && auth.accountStatus === "active")
    );
}

function canMarkAdminMessageRead({auth, userId, before, after}) {
  const changedKeys = Object.keys(after).filter((key) => after[key] !== before[key]);
  return auth != null &&
    auth.uid === userId &&
    auth.accountStatus === "active" &&
    JSON.stringify(changedKeys) === JSON.stringify(["readAt"]) &&
    before.readAt === null &&
    after.readAt === "timestamp";
}

test("product create policy engedi a saját képes termék létrehozását", () => {
  const allowed = canCreateProduct({
    auth: createAuth("merchant-1", {profileRole: "merchant"}),
    productId: "product-1",
    data: {
      archivedAt: null,
      category: "Pekseg",
      createdAt: "timestamp",
      deletedAt: null,
      discountedPrice: 500,
      expiresAt: "timestamp",
      hasImage: true,
      hasReservations: false,
      imagePath: "products/merchant-1/product-1/main.jpg",
      imageUrl: "https://example.test/products/merchant-1/product-1/main.jpg",
      interestCount: 0,
      isDeleted: false,
      location: null,
      merchantName: "Penny",
      name: "Bagel",
      originalPrice: 1000,
      ownerId: "merchant-1",
      pickupEndAt: "timestamp",
      pickupStartAt: "timestamp",
      quantity: 2,
      quantityAvailable: 2,
      status: "active",
    },
  });

  assert.equal(allowed, true);
});

test("product create policy tiltja az idegen ownerId-t", () => {
  const allowed = canCreateProduct({
    auth: createAuth("merchant-1", {profileRole: "merchant"}),
    productId: "product-1",
    data: {
      archivedAt: null,
      category: "Pekseg",
      createdAt: "timestamp",
      deletedAt: null,
      discountedPrice: 500,
      expiresAt: "timestamp",
      hasImage: false,
      hasReservations: false,
      interestCount: 0,
      isDeleted: false,
      location: null,
      merchantName: "Penny",
      name: "Bagel",
      originalPrice: 1000,
      ownerId: "merchant-2",
      pickupEndAt: "timestamp",
      pickupStartAt: "timestamp",
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

test("merchantStats olvasás bármely bejelentkezett felhasználónak engedett", () => {
  assert.equal(canReadMerchantStats({
    auth: createAuth("merchant-1", {profileRole: "merchant"}),
    merchantId: "merchant-1",
  }), true);
  assert.equal(canReadMerchantStats({
    auth: createAuth("consumer-1"),
    merchantId: "merchant-1",
  }), true);
  assert.equal(canReadMerchantStats({
    auth: createAuth("admin-1", {
      token: {admin: true},
      accountStatus: "active",
    }),
    merchantId: "merchant-1",
  }), true);
  assert.equal(canReadMerchantStats({
    auth: null,
    merchantId: "merchant-1",
  }), false);
});

test("review olvasás bármely bejelentkezett felhasználónak engedett", () => {
  const review = {
    buyerId: "buyer-1",
    merchantId: "merchant-1",
  };

  assert.equal(canReadReview({
    auth: createAuth("buyer-1"),
    review,
  }), true);
  assert.equal(canReadReview({
    auth: createAuth("merchant-1", {profileRole: "merchant"}),
    review,
  }), true);
  assert.equal(canReadReview({
    auth: createAuth("consumer-2"),
    review,
  }), true);
  assert.equal(canReadReview({
    auth: null,
    review,
  }), false);
});

test("user dokumentum írás csak saját azonosítóval engedett", () => {
  assert.equal(canCreateUserDoc({
    auth: createAuth("user-1"),
    userId: "user-1",
    data: {
      accountStatus: "active",
      createdAt: "timestamp",
      displayName: "User",
      email: "user@example.com",
      role: "consumer",
    },
  }), true);
  assert.equal(canCreateUserDoc({
    auth: createAuth("user-2"),
    userId: "user-1",
    data: {
      accountStatus: "active",
      createdAt: "timestamp",
      displayName: "User",
      email: "user@example.com",
      role: "consumer",
    },
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
      hasReservations: false,
      interestCount: 0,
      isDeleted: false,
      location: null,
      merchantName: "Penny",
      name: "Bagel",
      originalPrice: 1000,
      ownerId: "merchant-1",
      pickupEndAt: "timestamp",
      pickupStartAt: "timestamp",
      quantity: 2,
      quantityAvailable: 2,
      status: "active",
    },
  });

  assert.equal(allowed, false);
});

test("product create policy denies invalid owned image path", () => {
  const allowed = canCreateProduct({
    auth: createAuth("merchant-1", {profileRole: "merchant"}),
    productId: "product-1",
    data: {
      archivedAt: null,
      category: "Pekseg",
      createdAt: "timestamp",
      deletedAt: null,
      discountedPrice: 500,
      expiresAt: "timestamp",
      hasImage: true,
      hasReservations: false,
      imagePath: "products/merchant-2/product-1/main.jpg",
      imageUrl: "https://example.test/products/merchant-1/product-1/main.jpg",
      interestCount: 0,
      isDeleted: false,
      location: null,
      merchantName: "Penny",
      name: "Bagel",
      originalPrice: 1000,
      ownerId: "merchant-1",
      pickupEndAt: "timestamp",
      pickupStartAt: "timestamp",
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
      archivedAt: null,
      createdAt: "timestamp",
      deletedAt: null,
      hasReservations: false,
      ownerId: "merchant-1",
      interestCount: 0,
      isDeleted: false,
      merchantName: "Penny",
      status: "active",
    },
    after: {
      archivedAt: null,
      createdAt: "timestamp",
      deletedAt: null,
      hasReservations: false,
      ownerId: "merchant-1",
      interestCount: 1,
      isDeleted: false,
      merchantName: "Penny",
      status: "active",
    },
  });

  assert.equal(allowed, true);
});

test("product update policy denies extra field changes alongside interestCount", () => {
  const allowed = canUpdateInterestCount({
    auth: createAuth("consumer-1"),
    before: {
      archivedAt: null,
      createdAt: "timestamp",
      deletedAt: null,
      hasReservations: false,
      ownerId: "merchant-1",
      interestCount: 0,
      isDeleted: false,
      merchantName: "Penny",
      status: "active",
    },
    after: {
      archivedAt: null,
      createdAt: "timestamp",
      deletedAt: null,
      hasReservations: false,
      ownerId: "merchant-1",
      interestCount: 1,
      isDeleted: false,
      merchantName: "Penny",
      status: "sold_out",
    },
  });

  assert.equal(allowed, false);
});

test("product owner update policy allows editing before the first reservation", () => {
  const allowed = canUpdateOwnedProduct({
    auth: createAuth("merchant-1", {profileRole: "merchant"}),
    before: {
      archivedAt: null,
      category: "Pekseg",
      createdAt: "timestamp",
      deletedAt: null,
      discountedPrice: 500,
      expiresAt: "timestamp",
      hasImage: false,
      hasReservations: false,
      interestCount: 0,
      isDeleted: false,
      merchantName: "Penny",
      name: "Bagel",
      originalPrice: 1000,
      ownerId: "merchant-1",
      pickupEndAt: "timestamp",
      pickupStartAt: "timestamp",
      quantity: 2,
      quantityAvailable: 2,
      status: "active",
    },
    after: {
      archivedAt: null,
      category: "Pekseg",
      createdAt: "timestamp",
      deletedAt: null,
      discountedPrice: 450,
      expiresAt: "timestamp",
      hasImage: false,
      hasReservations: false,
      interestCount: 0,
      isDeleted: false,
      merchantName: "Penny",
      name: "Bagel Deluxe",
      originalPrice: 1000,
      ownerId: "merchant-1",
      pickupEndAt: "timestamp",
      pickupStartAt: "timestamp",
      quantity: 3,
      quantityAvailable: 3,
      status: "active",
    },
  });

  assert.equal(allowed, true);
});

test("product owner update policy denies editing after reservation history exists", () => {
  const allowed = canUpdateOwnedProduct({
    auth: createAuth("merchant-1", {profileRole: "merchant"}),
    before: {
      archivedAt: null,
      category: "Pekseg",
      createdAt: "timestamp",
      deletedAt: null,
      discountedPrice: 500,
      expiresAt: "timestamp",
      hasImage: false,
      hasReservations: true,
      interestCount: 0,
      isDeleted: false,
      merchantName: "Penny",
      name: "Bagel",
      originalPrice: 1000,
      ownerId: "merchant-1",
      pickupEndAt: "timestamp",
      pickupStartAt: "timestamp",
      quantity: 2,
      quantityAvailable: 2,
      status: "active",
    },
    after: {
      archivedAt: null,
      category: "Pekseg",
      createdAt: "timestamp",
      deletedAt: null,
      discountedPrice: 450,
      expiresAt: "timestamp",
      hasImage: false,
      hasReservations: false,
      interestCount: 0,
      isDeleted: false,
      merchantName: "Penny",
      name: "Bagel Deluxe",
      originalPrice: 1000,
      ownerId: "merchant-1",
      pickupEndAt: "timestamp",
      pickupStartAt: "timestamp",
      quantity: 3,
      quantityAvailable: 3,
      status: "active",
    },
  });

  assert.equal(allowed, false);
});

test("adminMessage olvasas engedett a cimzett kereskedonek es az adminnak", () => {
  assert.equal(canReadAdminMessage({
    auth: createAuth("merchant-1", {profileRole: "merchant"}),
    userId: "merchant-1",
  }), true);
  assert.equal(canReadAdminMessage({
    auth: createAuth("admin-1", {
      token: {admin: true},
      accountStatus: "active",
    }),
    userId: "merchant-1",
  }), true);
  assert.equal(canReadAdminMessage({
    auth: createAuth("other-user"),
    userId: "merchant-1",
  }), false);
});

test("adminMessage read receipt csak a sajat merchant fioknak engedett", () => {
  assert.equal(canMarkAdminMessageRead({
    auth: createAuth("merchant-1", {profileRole: "merchant"}),
    userId: "merchant-1",
    before: {readAt: null, subject: "Teszt"},
    after: {readAt: "timestamp", subject: "Teszt"},
  }), true);
  assert.equal(canMarkAdminMessageRead({
    auth: createAuth("merchant-2", {profileRole: "merchant"}),
    userId: "merchant-1",
    before: {readAt: null, subject: "Teszt"},
    after: {readAt: "timestamp", subject: "Teszt"},
  }), false);
  assert.equal(canMarkAdminMessageRead({
    auth: createAuth("merchant-1", {profileRole: "merchant"}),
    userId: "merchant-1",
    before: {readAt: "timestamp", subject: "Teszt"},
    after: {readAt: "timestamp-2", subject: "Teszt"},
  }), false);
});
