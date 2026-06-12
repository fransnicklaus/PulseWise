importScripts("https://www.gstatic.com/firebasejs/12.9.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/12.9.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyC_zloU6cHVH0Pr6swWTbEAVPTaMBI6RLQ",
  authDomain: "pulse-wise-app.firebaseapp.com",
  projectId: "pulse-wise-app",
  storageBucket: "pulse-wise-app.firebasestorage.app",
  messagingSenderId: "930387576551",
  appId: "1:930387576551:web:043db2513f75abcfc60442",
  measurementId: "G-CJDJ059LSQ",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] onBackgroundMessage", payload);

  if (payload.notification) {
    return;
  }

  const title = payload?.data?.title || "PulseWise";
  const body = payload?.data?.body || "Anda memiliki notifikasi baru.";
  const link =
    payload?.fcmOptions?.link ||
    payload?.data?.link ||
    payload?.data?.click_action ||
    "/";

  self.registration.showNotification(title, {
    body,
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    data: { link },
  });
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  const link = event.notification?.data?.link || "/";

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ("focus" in client) {
          client.navigate(link);
          return client.focus();
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(link);
      }

      return null;
    }),
  );
});
