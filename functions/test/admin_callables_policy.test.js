const test = require("node:test");
const assert = require("node:assert/strict");

process.env.FIREBASE_CONFIG = JSON.stringify({
  projectId: "nearpick-test",
  storageBucket: "nearpick-test.appspot.com",
});

const admin = require("firebase-admin");
const functions = require("../index");

function createFakeFirestore(seed = {}) {
  const docs = new Map(Object.entries(seed));
  const sets = [];
  let nextAutoId = 1;

  const serverTimestampSentinel = {__fieldValue: "serverTimestamp"};
  const deleteSentinel = {__fieldValue: "delete"};

  function applyWrite(path, data, {merge = false, requireExisting = false} = {}) {
    if (requireExisting && !docs.has(path)) {
      throw new Error("not-found");
    }

    const next = merge || requireExisting ? {...(docs.get(path) ?? {})} : {};
    for (const [key, value] of Object.entries(data)) {
      if (value === deleteSentinel) {
        delete next[key];
      } else {
        next[key] = value;
      }
    }
    docs.set(path, next);
  }

  class FakeDocRef {
    constructor(path) {
      this.path = path;
      this.id = path.split("/").pop();
    }

    async get() {
      const data = docs.get(this.path);
      return {
        exists: data !== undefined,
        data: () => data,
      };
    }

    async set(data, options = {}) {
      sets.push({data, options, path: this.path});
      applyWrite(this.path, data, {merge: options.merge === true});
    }

    collection(name) {
      return new FakeCollectionRef(`${this.path}/${name}`);
    }
  }

  class FakeCollectionRef {
    constructor(path) {
      this.path = path;
    }

    doc(id) {
      return new FakeDocRef(`${this.path}/${id ?? `auto-${nextAutoId++}`}`);
    }

    async get() {
      const prefix = `${this.path}/`;
      const snapshots = [];
      for (const [path, data] of docs.entries()) {
        const suffix = path.startsWith(prefix) ? path.slice(prefix.length) : "";
        if (suffix && !suffix.includes("/")) {
          snapshots.push({
            id: suffix,
            data: () => data,
          });
        }
      }
      return {
        docs: snapshots,
        empty: snapshots.length === 0,
      };
    }
  }

  class FakeTransaction {
    async get(ref) {
      return ref.get();
    }

    update(ref, data) {
      applyWrite(ref.path, data, {requireExisting: true});
      return this;
    }
  }

  const firestore = function firestore() {
    return {
      collection: (name) => new FakeCollectionRef(name),
      runTransaction: async (handler) => handler(new FakeTransaction()),
    };
  };
  firestore.FieldValue = {
    delete: () => deleteSentinel,
    serverTimestamp: () => serverTimestampSentinel,
  };

  return {
    deleteSentinel,
    docs,
    firestore,
    serverTimestampSentinel,
    sets,
  };
}

function installAdminFakes(seed = {}, options = {}) {
  const db = createFakeFirestore(seed);
  const state = {
    deletedFiles: [],
    sentMulticasts: [],
    storageDeleteError: options.storageDeleteError,
    updatedUsers: [],
    ...db,
  };

  Object.defineProperty(admin, "firestore", {
    configurable: true,
    value: state.firestore,
  });
  Object.defineProperty(admin, "auth", {
    configurable: true,
    value: () => ({
      updateUser: async (uid, data) => {
        state.updatedUsers.push({data, uid});
      },
    }),
  });
  Object.defineProperty(admin, "messaging", {
    configurable: true,
    value: () => ({
      sendEachForMulticast: async (message) => {
        state.sentMulticasts.push(message);
        return {
          responses: message.tokens.map(() => ({success: true})),
        };
      },
    }),
  });
  Object.defineProperty(admin, "storage", {
    configurable: true,
    value: () => ({
      bucket: () => ({
        file: (path) => ({
          delete: async (options) => {
            state.deletedFiles.push({options, path});
            if (state.storageDeleteError) {
              throw state.storageDeleteError;
            }
          },
        }),
      }),
    }),
  });

  return state;
}

function adminRequest(data = {}) {
  return {
    auth: {
      token: {admin: true},
      uid: "admin-1",
    },
    data,
    headers: {"x-correlation-id": "test-context"},
  };
}

function merchantRequest(data = {}) {
  return {
    auth: {
      token: {admin: false},
      uid: "merchant-1",
    },
    data,
    headers: {"x-correlation-id": "test-context"},
  };
}

function nonAdminRequest(data = {}) {
  return {
    auth: {
      token: {admin: false},
      uid: "merchant-1",
    },
    data,
    headers: {"x-correlation-id": "test-context"},
  };
}

async function assertRejectsWithCode(promise, code) {
  await assert.rejects(promise, (error) => {
    assert.equal(error.code ?? error.details?.code, code);
    return true;
  });
}

test("admin callable-ek permission-denied hibát adnak nem admin hívóra", async () => {
  installAdminFakes({
    "users/merchant-1": {accountStatus: "active", role: "merchant"},
  });

  const cases = [
    [
      functions.setUserAccountStatus,
      {accountStatus: "blocked", userId: "target-1"},
    ],
    [
      functions.sendAdminMessageToMerchant,
      {
        body: "Kerlek frissitsd a termekadatokat.",
        merchantId: "merchant-1",
        subject: "Moderacio",
      },
    ],
    [functions.hideProductForAdmin, {productId: "product-1"}],
    [functions.restoreProductForAdmin, {productId: "product-1"}],
    [functions.deleteProductForAdmin, {productId: "product-1"}],
  ];

  for (const [callable, data] of cases) {
    await assertRejectsWithCode(
        callable.run(nonAdminRequest(data)),
        "permission-denied",
    );
  }
});

test("setUserAccountStatus frissíti az Auth disabled állapotot és a profilt", async () => {
  const state = installAdminFakes({
    "users/admin-1": {accountStatus: "active", role: "admin"},
    "users/merchant-1": {accountStatus: "active", role: "merchant"},
  });

  const result = await functions.setUserAccountStatus.run(adminRequest({
    accountStatus: "blocked",
    userId: "merchant-1",
  }));

  assert.deepEqual(result, {
    accountStatus: "blocked",
    contextId: "test-context",
    updated: true,
  });
  assert.deepEqual(state.updatedUsers, [
    {data: {disabled: true}, uid: "merchant-1"},
  ]);
  assert.deepEqual(state.docs.get("users/merchant-1"), {
    accountStatus: "blocked",
    role: "merchant",
    statusUpdatedAt: state.serverTimestampSentinel,
    statusUpdatedBy: "admin-1",
  });
});

test("setUserAccountStatus nem engedi a saját admin fiók tiltását", async () => {
  installAdminFakes({
    "users/admin-1": {accountStatus: "active", role: "admin"},
  });

  await assertRejectsWithCode(
      functions.setUserAccountStatus.run(adminRequest({
        accountStatus: "blocked",
        userId: "admin-1",
      })),
      "failed-precondition",
  );
});

test("sendAdminMessageToMerchant létrehozza az admin üzenetet push nélkül", async () => {
  const state = installAdminFakes({
    "users/admin-1": {
      accountStatus: "active",
      displayName: "Demo Admin",
      role: "admin",
    },
    "users/merchant-1": {accountStatus: "active", role: "merchant"},
  });

  const result = await functions.sendAdminMessageToMerchant.run(adminRequest({
    body: "Kerlek nezd at a termek fotóját.",
    merchantId: "merchant-1",
    subject: "Termek moderacio",
    topic: "moderation",
  }));

  assert.deepEqual(result, {
    contextId: "test-context",
    messageId: "auto-1",
    notified: false,
    sent: true,
  });
  assert.equal(state.sentMulticasts.length, 0);
  assert.deepEqual(state.docs.get("users/merchant-1/adminMessages/auto-1"), {
    body: "Kerlek nezd at a termek fotóját.",
    createdAt: state.serverTimestampSentinel,
    createdBy: "admin-1",
    createdByLabel: "Demo Admin",
    readAt: null,
    recipientUserId: "merchant-1",
    subject: "Termek moderacio",
    topic: "moderation",
  });
});

test("sendAdminMessageToMerchant FCM push-t küld, ha van token", async () => {
  const state = installAdminFakes({
    "users/admin-1": {accountStatus: "active", email: "admin@test.local"},
    "users/merchant-1": {accountStatus: "active", role: "merchant"},
    "users/merchant-1/fcmTokens/token-1": {token: "fcm-token-1"},
    "users/merchant-1/fcmTokens/token-2": {token: "fcm-token-2"},
  });

  const result = await functions.sendAdminMessageToMerchant.run(adminRequest({
    body: "Rovid admin uzenet",
    merchantId: "merchant-1",
    subject: "Altalanos tajekoztatas",
    topic: "general",
  }));

  assert.equal(result.notified, true);
  assert.equal(state.sentMulticasts.length, 1);
  assert.deepEqual(state.sentMulticasts[0].tokens, [
    "fcm-token-1",
    "fcm-token-2",
  ]);
  assert.deepEqual(state.sentMulticasts[0].data, {
    messageId: "auto-1",
    topic: "general",
    type: "admin_message",
  });
});

test("sendAdminMessageToMerchant csak merchant célprofilra enged üzenetet", async () => {
  installAdminFakes({
    "users/admin-1": {accountStatus: "active", role: "admin"},
    "users/consumer-1": {accountStatus: "active", role: "consumer"},
  });

  await assertRejectsWithCode(
      functions.sendAdminMessageToMerchant.run(adminRequest({
        body: "Nem kereskedo celprofil.",
        merchantId: "consumer-1",
        subject: "Moderacio",
      })),
      "failed-precondition",
  );
});

test("hideProductForAdmin hidden állapotba teszi a terméket", async () => {
  const state = installAdminFakes({
    "products/product-1": {ownerId: "merchant-1", status: "active"},
    "users/admin-1": {accountStatus: "active", role: "admin"},
  });

  const result = await functions.hideProductForAdmin.run(adminRequest({
    productId: "product-1",
  }));

  assert.deepEqual(result, {
    contextId: "test-context",
    hidden: true,
  });
  assert.deepEqual(state.docs.get("products/product-1"), {
    ownerId: "merchant-1",
    status: "hidden",
    statusBeforeHidden: "active",
  });
});

test("restoreProductForAdmin visszaállítja az előző státuszt", async () => {
  const state = installAdminFakes({
    "products/product-1": {
      ownerId: "merchant-1",
      status: "hidden",
      statusBeforeHidden: "active",
    },
    "users/admin-1": {accountStatus: "active", role: "admin"},
  });

  const result = await functions.restoreProductForAdmin.run(adminRequest({
    productId: "product-1",
  }));

  assert.deepEqual(result, {
    contextId: "test-context",
    restored: true,
    status: "active",
  });
  assert.deepEqual(state.docs.get("products/product-1"), {
    ownerId: "merchant-1",
    status: "active",
  });
});

test("archiveProduct sikeres marad Storage keptorlesi hiba eseten", async () => {
  const state = installAdminFakes({
    "products/product-1": {
      hasImage: true,
      imagePath: "products/merchant-1/product-1/main.jpg",
      imageUrl: "https://example.test/main.jpg",
      ownerId: "merchant-1",
      status: "active",
    },
    "users/merchant-1": {accountStatus: "active", role: "merchant"},
  }, {storageDeleteError: new Error("storage-delete-failed")});

  const result = await functions.archiveProduct.run(merchantRequest({
    productId: "product-1",
  }));

  assert.deepEqual(result, {
    archived: true,
    contextId: "test-context",
  });
  assert.deepEqual(state.docs.get("products/product-1"), {
    archivedAt: state.serverTimestampSentinel,
    deletedAt: state.serverTimestampSentinel,
    hasImage: false,
    isDeleted: true,
    ownerId: "merchant-1",
    status: "archived",
  });
  assert.deepEqual(state.deletedFiles, [
    {
      options: {ignoreNotFound: true},
      path: "products/merchant-1/product-1/main.jpg",
    },
  ]);
});

test("deleteProductForAdmin archiválja a terméket és törli a saját képet", async () => {
  const state = installAdminFakes({
    "products/product-1": {
      hasImage: true,
      imagePath: "products/merchant-1/product-1/main.jpg",
      imageUrl: "https://example.test/main.jpg",
      ownerId: "merchant-1",
      status: "active",
    },
    "users/admin-1": {accountStatus: "active", role: "admin"},
  });

  const result = await functions.deleteProductForAdmin.run(adminRequest({
    productId: "product-1",
  }));

  assert.deepEqual(result, {
    archived: true,
    contextId: "test-context",
  });
  assert.deepEqual(state.docs.get("products/product-1"), {
    archivedAt: state.serverTimestampSentinel,
    deletedAt: state.serverTimestampSentinel,
    hasImage: false,
    isDeleted: true,
    ownerId: "merchant-1",
    status: "archived",
  });
  assert.deepEqual(state.deletedFiles, [
    {
      options: {ignoreNotFound: true},
      path: "products/merchant-1/product-1/main.jpg",
    },
  ]);
});

test("deleteProductForAdmin sikeres marad Storage keptorlesi hiba eseten", async () => {
  const state = installAdminFakes({
    "products/product-1": {
      hasImage: true,
      imagePath: "products/merchant-1/product-1/main.jpg",
      imageUrl: "https://example.test/main.jpg",
      ownerId: "merchant-1",
      status: "active",
    },
    "users/admin-1": {accountStatus: "active", role: "admin"},
  }, {storageDeleteError: new Error("storage-delete-failed")});

  const result = await functions.deleteProductForAdmin.run(adminRequest({
    productId: "product-1",
  }));

  assert.deepEqual(result, {
    archived: true,
    contextId: "test-context",
  });
  assert.deepEqual(state.docs.get("products/product-1"), {
    archivedAt: state.serverTimestampSentinel,
    deletedAt: state.serverTimestampSentinel,
    hasImage: false,
    isDeleted: true,
    ownerId: "merchant-1",
    status: "archived",
  });
  assert.deepEqual(state.deletedFiles, [
    {
      options: {ignoreNotFound: true},
      path: "products/merchant-1/product-1/main.jpg",
    },
  ]);
});
