import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

/**
 * cleanupStaleTokens
 *
 * Runs weekly on Sunday at 3:00 AM (Asia/Ho_Chi_Minh).
 * Finds FCM tokens that haven't been refreshed in 60+ days and deletes them.
 * This prevents wasted FCM send attempts and keeps the database clean.
 */
export const cleanupStaleTokens = onSchedule(
  {
    schedule: "0 3 * * 0", // Every Sunday at 3 AM
    timeZone: "Asia/Ho_Chi_Minh",
    retryCount: 1,
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async () => {
    logger.info("cleanupStaleTokens: starting cleanup");

    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 60); // 60 days ago

    let totalDeleted = 0;

    // Query all users to check their fcm_tokens subcollections.
    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      try {
        const tokensSnap = await userDoc.ref
          .collection("fcm_tokens")
          .where("lastRefreshedAt", "<", cutoff)
          .get();

        if (tokensSnap.empty) continue;

        const batch = db.batch();
        for (const tokenDoc of tokensSnap.docs) {
          batch.delete(tokenDoc.ref);
          totalDeleted++;
        }
        await batch.commit();

        logger.info(
          `Deleted ${tokensSnap.size} stale tokens for user ${userDoc.id}`
        );
      } catch (err) {
        logger.error(
          `Failed to clean tokens for user ${userDoc.id}`,
          err
        );
      }
    }

    logger.info(
      `cleanupStaleTokens: completed — deleted ${totalDeleted} stale tokens`
    );
  }
);
