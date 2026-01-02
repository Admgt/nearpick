const admin = require("firebase-admin");
admin.initializeApp();

const { onDocumentCreated } = require("firebase-functions/v2/firestore");

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
      console.log("Nincs releváns user.");
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
        title: "Új ajánlat a NearPicken!",
        body: `${product.name} • ${product.discountedPrice} Ft`,
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
      console.log(`Küldés: ${chunk.length} token, failed: ${failed}`);
    }

    console.log(`Push elküldve összesen ${tokens.length} tokenre.`);
  }
);
