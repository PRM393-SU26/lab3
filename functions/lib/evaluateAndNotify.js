"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.evaluateAndNotify = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firebase_functions_1 = require("firebase-functions");
const admin = __importStar(require("firebase-admin"));
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
const messaging = admin.messaging();
/** Default thresholds — can be overridden via global_config/notification_settings. */
const DEFAULT_TREND_THRESHOLD = 40;
const DEFAULT_INTEREST_MATCH_THRESHOLD = 0.3;
const DEFAULT_MAX_PER_DAY = 5;
/**
 * evaluateAndNotify
 *
 * Runs every 6 hours (offset 30 min from syncOpenAlexTrends).
 * For each recent high-scoring trend snapshot:
 *   1. Finds users whose interests match the topic
 *   2. Checks notification preferences, dedup, daily cap, quiet hours
 *   3. Sends FCM notification and logs it
 */
exports.evaluateAndNotify = (0, scheduler_1.onSchedule)({
    schedule: "30 */6 * * *", // Every 6 hours at :30
    timeZone: "Asia/Ho_Chi_Minh",
    retryCount: 1,
    memory: "512MiB",
    timeoutSeconds: 300,
}, async () => {
    firebase_functions_1.logger.info("evaluateAndNotify: starting notification evaluation");
    // Load global config thresholds.
    let trendThreshold = DEFAULT_TREND_THRESHOLD;
    let interestThreshold = DEFAULT_INTEREST_MATCH_THRESHOLD;
    let globalMaxPerDay = DEFAULT_MAX_PER_DAY;
    try {
        const configDoc = await db
            .collection("global_config")
            .doc("notification_settings")
            .get();
        if (configDoc.exists) {
            const data = configDoc.data();
            trendThreshold = data.trendScoreThreshold ?? trendThreshold;
            interestThreshold =
                data.interestMatchThreshold ?? interestThreshold;
            globalMaxPerDay =
                data.maxNotificationsPerUserPerDay ?? globalMaxPerDay;
        }
    }
    catch {
        firebase_functions_1.logger.warn("Could not read global_config, using defaults");
    }
    // Find trend snapshots from the last 7 hours with high scores.
    const cutoff = new Date(Date.now() - 7 * 60 * 60 * 1000);
    const trendSnaps = await db
        .collection("trend_snapshots")
        .where("snapshotDate", ">=", cutoff)
        .where("trendScore", ">=", trendThreshold)
        .orderBy("trendScore", "desc")
        .limit(20)
        .get();
    if (trendSnaps.empty) {
        firebase_functions_1.logger.info("evaluateAndNotify: no trending topics above threshold");
        return;
    }
    firebase_functions_1.logger.info(`evaluateAndNotify: found ${trendSnaps.size} trending snapshots`);
    const today = new Date().toISOString().split("T")[0];
    const currentHour = new Date().getHours(); // Server time (UTC+7 configured)
    for (const trendDoc of trendSnaps.docs) {
        const trend = trendDoc.data();
        const topicNormalized = trend.topicNormalized ?? "";
        const topicDisplay = trend.topic ?? topicNormalized;
        const trendScore = trend.trendScore ?? 0;
        const growthRate = trend.metrics?.growthRate ?? 0;
        const recentWorksCount = trend.metrics?.recentWorksCount ?? 0;
        // Find users interested in this topic.
        // We use a collection group query on 'interests' subcollection.
        const matchedInterests = await db
            .collectionGroup("interests")
            .where("type", "==", "topic")
            .where("score", ">=", interestThreshold)
            .get();
        // Filter to interests whose displayName matches the trend topic.
        const matchedUsers = new Set();
        for (const interestDoc of matchedInterests.docs) {
            const interestName = interestDoc.data().displayName.toLowerCase();
            // Fuzzy match: check if the interest name contains the trend topic
            // or vice versa.
            if (interestName.includes(topicNormalized) ||
                topicNormalized.includes(interestName)) {
                // Extract uid from the document path: users/{uid}/interests/{id}
                const pathParts = interestDoc.ref.path.split("/");
                if (pathParts.length >= 2) {
                    matchedUsers.add(pathParts[1]);
                }
            }
        }
        firebase_functions_1.logger.info(`Topic "${topicDisplay}": ${matchedUsers.size} matched users`);
        for (const uid of matchedUsers) {
            try {
                await sendNotificationToUser(uid, {
                    type: "trending_topic",
                    topic: topicDisplay,
                    topicNormalized,
                    trendScore,
                    growthRate,
                    recentWorksCount,
                    today,
                    currentHour,
                    globalMaxPerDay,
                });
            }
            catch (err) {
                firebase_functions_1.logger.error(`Failed to notify user ${uid}`, err);
            }
        }
    }
    firebase_functions_1.logger.info("evaluateAndNotify: completed");
});
async function sendNotificationToUser(uid, params) {
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists)
        return;
    const userData = userDoc.data();
    const prefs = (userData.notification_prefs ?? {});
    // Check master toggle.
    if (prefs.enabled === false)
        return;
    // Check per-type toggle.
    if (params.type === "trending_topic" && prefs.trending_topics === false)
        return;
    if (params.type === "interest_update" && prefs.interest_updates === false)
        return;
    // Check quiet hours.
    const quietStart = prefs.quiet_hours_start ?? 22;
    const quietEnd = prefs.quiet_hours_end ?? 7;
    if (isInQuietHours(params.currentHour, quietStart, quietEnd)) {
        firebase_functions_1.logger.info(`User ${uid}: skipped (quiet hours)`);
        return;
    }
    // Check daily cap.
    const maxPerDay = Math.min(prefs.max_per_day ?? params.globalMaxPerDay, params.globalMaxPerDay);
    const todayNotifs = await db
        .collection("notification_log")
        .where("uid", "==", uid)
        .where("sentAt", ">=", new Date(`${params.today}T00:00:00`))
        .get();
    if (todayNotifs.size >= maxPerDay) {
        firebase_functions_1.logger.info(`User ${uid}: skipped (daily cap ${maxPerDay} reached)`);
        return;
    }
    // Check deduplication.
    const dedupKey = `${uid}_${params.type}_${params.topicNormalized}_${params.today}`;
    const existingNotif = await db
        .collection("notification_log")
        .where("deduplicationKey", "==", dedupKey)
        .limit(1)
        .get();
    if (!existingNotif.empty) {
        firebase_functions_1.logger.info(`User ${uid}: skipped (dedup key exists: ${dedupKey})`);
        return;
    }
    // Get FCM tokens.
    const tokensSnap = await db
        .collection("users")
        .doc(uid)
        .collection("fcm_tokens")
        .get();
    if (tokensSnap.empty) {
        firebase_functions_1.logger.info(`User ${uid}: no FCM tokens found`);
        return;
    }
    // Build notification message.
    const growthPct = Math.abs(params.growthRate).toFixed(0);
    const title = `🔥 "${params.topic}" is trending`;
    const body = params.growthRate > 0
        ? `Publications surged ${growthPct}% recently with ${params.recentWorksCount.toLocaleString()} new papers. Tap to explore.`
        : `${params.recentWorksCount.toLocaleString()} papers published recently. Trend score: ${params.trendScore}. Tap to explore.`;
    // Send to all user devices.
    const tokens = tokensSnap.docs.map((d) => d.data().token);
    const staleTokenIds = [];
    for (let i = 0; i < tokens.length; i++) {
        try {
            await messaging.send({
                token: tokens[i],
                notification: { title, body },
                data: {
                    type: params.type,
                    topic: params.topic,
                    trendScore: params.trendScore.toString(),
                },
                android: {
                    priority: "normal",
                    notification: { channelId: "research_trends" },
                },
            });
        }
        catch (err) {
            const errorMessage = err instanceof Error ? err.message : String(err);
            if (errorMessage.includes("registration-token-not-registered") ||
                errorMessage.includes("invalid-registration-token")) {
                staleTokenIds.push(tokensSnap.docs[i].id);
            }
            firebase_functions_1.logger.warn(`FCM send failed for token ${i}`, err);
        }
    }
    // Clean up stale tokens.
    for (const tokenId of staleTokenIds) {
        await db
            .collection("users")
            .doc(uid)
            .collection("fcm_tokens")
            .doc(tokenId)
            .delete();
        firebase_functions_1.logger.info(`Deleted stale token ${tokenId} for user ${uid}`);
    }
    // Log the notification.
    await db.collection("notification_log").add({
        uid,
        type: params.type,
        topic: params.topic,
        title,
        body,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        deduplicationKey: dedupKey,
        status: staleTokenIds.length < tokens.length ? "sent" : "failed",
    });
    firebase_functions_1.logger.info(`Sent "${params.type}" notification to user ${uid}: ${title}`);
}
function isInQuietHours(currentHour, start, end) {
    if (start <= end) {
        // e.g., 8 to 17 — simple range
        return currentHour >= start && currentHour < end;
    }
    // Overnight range, e.g., 22 to 7
    return currentHour >= start || currentHour < end;
}
//# sourceMappingURL=evaluateAndNotify.js.map