/**
 * Cloud Functions entry point for Journal Trend Analyzer.
 *
 * Exports scheduled functions that power the personalized notification system:
 *   - syncOpenAlexTrends:  Fetches trend data from OpenAlex API → Firestore
 *   - evaluateAndNotify:   Matches users to trends → sends FCM notifications
 *   - cleanupStaleTokens:  Removes expired FCM tokens from Firestore
 */

export { syncOpenAlexTrends } from "./syncOpenAlexTrends";
export { evaluateAndNotify } from "./evaluateAndNotify";
export { cleanupStaleTokens } from "./cleanupStaleTokens";
