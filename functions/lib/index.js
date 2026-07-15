"use strict";
/**
 * Cloud Functions entry point for Journal Trend Analyzer.
 *
 * Exports scheduled functions that power the personalized notification system:
 *   - syncOpenAlexTrends:  Fetches trend data from OpenAlex API → Firestore
 *   - evaluateAndNotify:   Matches users to trends → sends FCM notifications
 *   - cleanupStaleTokens:  Removes expired FCM tokens from Firestore
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupStaleTokens = exports.evaluateAndNotify = exports.syncOpenAlexTrends = void 0;
var syncOpenAlexTrends_1 = require("./syncOpenAlexTrends");
Object.defineProperty(exports, "syncOpenAlexTrends", { enumerable: true, get: function () { return syncOpenAlexTrends_1.syncOpenAlexTrends; } });
var evaluateAndNotify_1 = require("./evaluateAndNotify");
Object.defineProperty(exports, "evaluateAndNotify", { enumerable: true, get: function () { return evaluateAndNotify_1.evaluateAndNotify; } });
var cleanupStaleTokens_1 = require("./cleanupStaleTokens");
Object.defineProperty(exports, "cleanupStaleTokens", { enumerable: true, get: function () { return cleanupStaleTokens_1.cleanupStaleTokens; } });
//# sourceMappingURL=index.js.map