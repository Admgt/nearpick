importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCkX3Urt8XKngrn-rP8drgsZBDoLSV03ds",
  authDomain: "nearpick-c0fea.firebaseapp.com",
  projectId: "nearpick-c0fea",
  storageBucket: "nearpick-c0fea.firebasestorage.app",
  messagingSenderId: "864369516764",
  appId: "1:864369516764:web:aad02dd9ef0aeec9f65419",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  self.registration.showNotification(
    payload.notification?.title ?? "NearPick",
    { body: payload.notification?.body ?? "" }
  );
});
