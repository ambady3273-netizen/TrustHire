/**
 * TrustHire — Firebase Cloud Functions
 *
 * Triggered by Firestore document creation in the `notifications`
 * collection.  Reads the FCM token from the recipient's user doc
 * and delivers a push notification via Firebase Cloud Messaging.
 *
 * Requires the Firebase Blaze (pay-as-you-go) plan because Cloud
 * Functions need outbound network access to reach the FCM API.
 *
 * Deploy:
 *   cd functions && npm install && npm run deploy
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();

const db  = admin.firestore();
const fcm = admin.messaging();

// ─────────────────────────────────────────────────────────────
// TRIGGER: new notification document created
// ─────────────────────────────────────────────────────────────

export const sendPushOnNotification = functions
  .firestore
  .document("notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    const userId:  string = data.userId  ?? "";
    const title:   string = data.title   ?? "TrustHire";
    const body:    string = data.body    ?? "";
    const actionRoute: string | undefined = data.actionRoute;

    if (!userId) {
      console.warn("sendPushOnNotification: no userId on notification", context.params.notifId);
      return null;
    }

    // Fetch the recipient's FCM token from their user document.
    const userSnap = await db.collection("users").doc(userId).get();
    if (!userSnap.exists) {
      console.warn(`sendPushOnNotification: user ${userId} not found`);
      return null;
    }

    const fcmToken: string | undefined = userSnap.data()?.fcmToken;
    if (!fcmToken) {
      // User hasn't granted notification permission or hasn't opened
      // the app yet — this is normal, just skip silently.
      return null;
    }

    // Build the FCM message.
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: { title, body },
      data: {
        notifId:     context.params.notifId,
        actionRoute: actionRoute ?? "",
      },
      android: {
        notification: {
          sound:    "default",
          priority: "high",
          channelId: "trusthire_default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await fcm.send(message);
      console.log(`Push sent to ${userId}: ${response}`);
      return response;
    } catch (err: unknown) {
      // Token is stale — remove it so we don't retry endlessly.
      const errCode = (err as {code?: string}).code;
      if (
        errCode === "messaging/invalid-registration-token" ||
        errCode === "messaging/registration-token-not-registered"
      ) {
        await db.collection("users").doc(userId).update({ fcmToken: admin.firestore.FieldValue.delete() });
        console.warn(`Stale FCM token removed for user ${userId}`);
      } else {
        console.error("FCM send error:", err);
      }
      return null;
    }
  });

// ─────────────────────────────────────────────────────────────
// TRIGGER: escrow funded → notify the seeker
// ─────────────────────────────────────────────────────────────

export const sendPushOnEscrowFunded = functions
  .firestore
  .document("escrows/{escrowId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    if (!data) return null;

    const applicationId: string = data.applicationId ?? "";
    if (!applicationId) return null;

    // Get the seeker from the application.
    const appSnap = await db.collection("applications").doc(applicationId).get();
    if (!appSnap.exists) return null;

    const seekerId: string = appSnap.data()?.seekerId ?? "";
    const jobTitle: string = appSnap.data()?.jobTitle ?? "your job";
    if (!seekerId) return null;

    // Write an in-app notification doc (which will itself trigger sendPushOnNotification).
    await db.collection("notifications").add({
      userId:      seekerId,
      title:       "Escrow Funded 🔒",
      body:        `Payment for "${jobTitle}" is secured in escrow. You can start work!`,
      type:        "escrowFunded",
      isRead:      false,
      actionRoute: "/myApplications",
      createdAt:   admin.firestore.FieldValue.serverTimestamp(),
    });

    return null;
  });
