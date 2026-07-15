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
exports.cleanupStaleTokens = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firebase_functions_1 = require("firebase-functions");
const admin = __importStar(require("firebase-admin"));
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
exports.cleanupStaleTokens = (0, scheduler_1.onSchedule)({
    schedule: "0 3 * * 0", // Every Sunday at 3 AM
    timeZone: "Asia/Ho_Chi_Minh",
    retryCount: 1,
    memory: "256MiB",
    timeoutSeconds: 120,
}, async () => {
    firebase_functions_1.logger.info("cleanupStaleTokens: starting cleanup");
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
            if (tokensSnap.empty)
                continue;
            const batch = db.batch();
            for (const tokenDoc of tokensSnap.docs) {
                batch.delete(tokenDoc.ref);
                totalDeleted++;
            }
            await batch.commit();
            firebase_functions_1.logger.info(`Deleted ${tokensSnap.size} stale tokens for user ${userDoc.id}`);
        }
        catch (err) {
            firebase_functions_1.logger.error(`Failed to clean tokens for user ${userDoc.id}`, err);
        }
    }
    firebase_functions_1.logger.info(`cleanupStaleTokens: completed — deleted ${totalDeleted} stale tokens`);
});
//# sourceMappingURL=cleanupStaleTokens.js.map