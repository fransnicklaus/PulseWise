const APP_FALLBACK_PATH = "/";

function extractNotificationTarget(notification) {
  const data = notification?.data || {};
  const fcmMessage = data?.FCM_MSG || {};
  const fcmData = fcmMessage?.data || {};

  return (
    data?.link ||
    data?.click_action ||
    data?.route ||
    fcmMessage?.fcmOptions?.link ||
    fcmData?.link ||
    fcmData?.click_action ||
    fcmData?.route ||
    fcmMessage?.notification?.click_action ||
    APP_FALLBACK_PATH
  );
}

function normalizeAppUrl(target) {
  try {
    const resolved = new URL(target || APP_FALLBACK_PATH, self.location.origin);

    if (resolved.origin === self.location.origin) {
      return resolved;
    }

    return new URL(
      `${resolved.pathname}${resolved.search}${resolved.hash}`,
      self.location.origin,
    );
  } catch (_) {
    return new URL(APP_FALLBACK_PATH, self.location.origin);
  }
}

async function focusOrOpenApp(targetUrl) {
  const clientList = await clients.matchAll({
    type: "window",
    includeUncontrolled: true,
  });

  let sameOriginClient = null;

  for (const client of clientList) {
    try {
      const clientUrl = new URL(client.url);
      if (clientUrl.origin !== self.location.origin) {
        continue;
      }

      sameOriginClient ??= client;

      if (
        clientUrl.href === targetUrl.href ||
        clientUrl.pathname === targetUrl.pathname
      ) {
        await client.focus();
        if ("navigate" in client && client.url !== targetUrl.href) {
          await client.navigate(targetUrl.href);
        }
        return;
      }
    } catch (_) {
      // Ignore invalid client URLs and keep checking the rest.
    }
  }

  if (sameOriginClient) {
    await sameOriginClient.focus();
    if ("navigate" in sameOriginClient) {
      await sameOriginClient.navigate(targetUrl.href);
    }
    return;
  }

  if (clients.openWindow) {
    await clients.openWindow(targetUrl.href);
  }
}

self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  const targetUrl = normalizeAppUrl(
    extractNotificationTarget(event.notification),
  );

  event.waitUntil(focusOrOpenApp(targetUrl));
});

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
