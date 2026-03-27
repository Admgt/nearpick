importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "<FIREBASE_WEB_API_KEY>",
  authDomain: "<FIREBASE_AUTH_DOMAIN>",
  projectId: "<FIREBASE_PROJECT_ID>",
  storageBucket: "<FIREBASE_STORAGE_BUCKET>",
  messagingSenderId: "<FIREBASE_MESSAGING_SENDER_ID>",
  appId: "<FIREBASE_WEB_APP_ID>",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  self.registration.showNotification(
    payload.notification?.title ?? "NearPick",
    { body: payload.notification?.body ?? "" }
  );
});

