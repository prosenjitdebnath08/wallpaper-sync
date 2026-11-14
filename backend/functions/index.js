const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function: onWallpaperUpdated
 * Triggered whenever the active wallpaper changes for any user.
 * Sends high-priority silent FCM push notifications to all connected devices
 * for that Google account (excluding the device that initiated the change).
 */
exports.onWallpaperUpdated = functions.firestore
  .document("users/{userId}/active_state/current")
  .onWrite(async (change, context) => {
    const afterData = change.after.data();
    if (!afterData || !afterData.url) {
      console.log("No active wallpaper data found.");
      return null;
    }

    const { userId } = context.params;
    const { url, title, sourceDeviceId } = afterData;

    console.log(`Broadcasting wallpaper update for user ${userId} from source device ${sourceDeviceId}`);

    // Fetch all registered devices for this user
    const devicesSnapshot = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("devices")
      .get();

    if (devicesSnapshot.empty) {
      console.log("No registered devices found for user.");
      return null;
    }

    const tokens = [];
    devicesSnapshot.forEach((doc) => {
      const data = doc.data();
      // Skip the source device that triggered the upload
      if (doc.id !== sourceDeviceId && data.fcmToken && data.autoApply !== false) {
        tokens.push(data.fcmToken);
      }
    });

    if (tokens.length === 0) {
      console.log("No external devices to notify.");
      return null;
    }

    console.log(`Sending high-priority sync payload to ${tokens.length} devices.`);

    // High priority data message for background wakeup
    const message = {
      tokens: tokens,
      data: {
        action: "SET_WALLPAPER",
        url: url,
        title: title || "New Wallpaper",
        timestamp: String(Date.now()),
      },
      android: {
        priority: "high",
      },
      apns: {
        headers: {
          "apns-push-type": "background",
          "apns-priority": "5",
        },
        payload: {
          aps: {
            "content-available": 1,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Successfully sent ${response.successCount} messages; ${response.failureCount} failed.`);
      return response;
    } catch (error) {
      console.error("Error sending FCM multicast:", error);
      return null;
    }
  });
