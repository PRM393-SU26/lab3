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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.syncOpenAlexTrends = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firebase_functions_1 = require("firebase-functions");
const admin = __importStar(require("firebase-admin"));
const node_fetch_1 = __importDefault(require("node-fetch"));
// Initialize Firebase Admin (idempotent — safe to call multiple times).
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
const OPENALEX_BASE = "https://api.openalex.org";
const OPENALEX_EMAIL = "thait5236@gmail.com";
/**
 * Default seed topics used when no user interests exist yet.
 * These cover broadly popular research areas to bootstrap the system.
 */
const SEED_TOPICS = [
    "Machine Learning",
    "Artificial Intelligence",
    "Deep Learning",
    "Natural Language Processing",
    "Computer Vision",
    "Quantum Computing",
    "Climate Change",
    "CRISPR",
    "Renewable Energy",
    "Blockchain",
    "Cybersecurity",
    "Biotechnology",
    "Robotics",
    "Data Science",
    "Neuroscience",
];
/**
 * syncOpenAlexTrends
 *
 * Runs every 6 hours. For each tracked topic:
 *   1. Queries OpenAlex for total works count and yearly breakdown
 *   2. Computes a trendScore based on volume, growth, and recency
 *   3. Writes a snapshot to `trend_snapshots/{date}_{topicNormalized}`
 *   4. Compares with previous snapshot to detect significant changes
 */
exports.syncOpenAlexTrends = (0, scheduler_1.onSchedule)({
    schedule: "every 6 hours",
    timeZone: "Asia/Ho_Chi_Minh",
    retryCount: 2,
    memory: "512MiB",
    timeoutSeconds: 300,
}, async () => {
    firebase_functions_1.logger.info("syncOpenAlexTrends: starting trend sync");
    // Collect topics to track: seed list ∪ top user interests.
    const topics = new Set(SEED_TOPICS);
    try {
        // Read top user interests across all users (collection group query).
        const interestsSnap = await db
            .collectionGroup("interests")
            .where("type", "==", "topic")
            .where("score", ">=", 0.3)
            .orderBy("score", "desc")
            .limit(50)
            .get();
        for (const doc of interestsSnap.docs) {
            const name = doc.data().displayName;
            if (name)
                topics.add(name);
        }
    }
    catch (err) {
        firebase_functions_1.logger.warn("Could not read user interests, using seed topics only", err);
    }
    firebase_functions_1.logger.info(`syncOpenAlexTrends: tracking ${topics.size} topics`);
    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
    const currentYear = new Date().getFullYear();
    for (const topic of topics) {
        try {
            await syncSingleTopic(topic, today, currentYear);
            // Small delay to respect OpenAlex rate limits.
            await sleep(500);
        }
        catch (err) {
            firebase_functions_1.logger.error(`Failed to sync topic "${topic}"`, err);
        }
    }
    firebase_functions_1.logger.info("syncOpenAlexTrends: completed");
});
async function syncSingleTopic(topic, today, currentYear) {
    const normalized = topic.toLowerCase().replace(/[^\w\s]/g, "").trim();
    const docId = `${today}_${normalized.replace(/\s+/g, "-")}`;
    // 1. Get yearly publication counts (group_by).
    const groupByUrl = `${OPENALEX_BASE}/works?search=${encodeURIComponent(topic)}&group_by=publication_year&per_page=200&mailto=${OPENALEX_EMAIL}`;
    const groupByResp = await (0, node_fetch_1.default)(groupByUrl);
    if (!groupByResp.ok) {
        throw new Error(`OpenAlex group_by request failed: ${groupByResp.status}`);
    }
    const groupByData = (await groupByResp.json());
    const totalWorks = groupByData.meta?.count ?? 0;
    const yearCounts = new Map();
    for (const g of groupByData.group_by ?? []) {
        const year = parseInt(g.key, 10);
        if (!isNaN(year) && year <= currentYear) {
            yearCounts.set(year, g.count);
        }
    }
    // 2. Compute metrics.
    const thisYearCount = yearCounts.get(currentYear) ?? 0;
    const lastYearCount = yearCounts.get(currentYear - 1) ?? 1; // avoid /0
    const recentGrowth = lastYearCount > 0
        ? (thisYearCount - lastYearCount) / lastYearCount
        : 0;
    // Sum of last 2 years as "recent" proxy.
    const recentWorksCount = thisYearCount + (yearCounts.get(currentYear - 1) ?? 0);
    // 3. Compute trend score (0–100).
    const volumeScore = Math.min(totalWorks / 100000, 1.0) * 30;
    const growthScore = Math.min(Math.max(recentGrowth, 0), 1.0) * 50;
    const recencyScore = totalWorks > 0 ? (recentWorksCount / totalWorks) * 20 : 0;
    const trendScore = Math.round((volumeScore + growthScore + recencyScore) * 100) / 100;
    // 4. Read previous snapshot for delta comparison.
    let previousTrendScore = 0;
    try {
        const prevSnaps = await db
            .collection("trend_snapshots")
            .where("topicNormalized", "==", normalized)
            .orderBy("snapshotDate", "desc")
            .limit(1)
            .get();
        if (!prevSnaps.empty) {
            previousTrendScore = prevSnaps.docs[0].data().trendScore ?? 0;
        }
    }
    catch {
        // First time — no previous snapshot.
    }
    // 5. Write snapshot.
    await db.collection("trend_snapshots").doc(docId).set({
        topic,
        topicNormalized: normalized,
        snapshotDate: admin.firestore.FieldValue.serverTimestamp(),
        source: "openalex",
        metrics: {
            totalWorks,
            recentWorksCount,
            growthRate: Math.round(recentGrowth * 10000) / 100, // percentage
            avgCitations: 0, // TODO: enrich in Phase 2
            topAuthor: "",
        },
        trendScore,
        previousTrendScore,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    firebase_functions_1.logger.info(`Synced trend: "${topic}" → score=${trendScore}, growth=${(recentGrowth * 100).toFixed(1)}%`);
}
function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
//# sourceMappingURL=syncOpenAlexTrends.js.map