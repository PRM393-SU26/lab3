import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";
import fetch from "node-fetch";

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

interface OpenAlexGroupByResult {
  key: string;
  count: number;
}

/**
 * syncOpenAlexTrends
 *
 * Runs every 6 hours. For each tracked topic:
 *   1. Queries OpenAlex for total works count and yearly breakdown
 *   2. Computes a trendScore based on volume, growth, and recency
 *   3. Writes a snapshot to `trend_snapshots/{date}_{topicNormalized}`
 *   4. Compares with previous snapshot to detect significant changes
 */
export const syncOpenAlexTrends = onSchedule(
  {
    schedule: "every 6 hours",
    timeZone: "Asia/Ho_Chi_Minh",
    retryCount: 2,
    memory: "512MiB",
    timeoutSeconds: 300,
  },
  async () => {
    logger.info("syncOpenAlexTrends: starting trend sync");

    // Collect topics to track: seed list ∪ top user interests.
    const topics = new Set<string>(SEED_TOPICS);

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
        const name = doc.data().displayName as string;
        if (name) topics.add(name);
      }
    } catch (err) {
      logger.warn("Could not read user interests, using seed topics only", err);
    }

    logger.info(`syncOpenAlexTrends: tracking ${topics.size} topics`);

    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
    const currentYear = new Date().getFullYear();

    for (const topic of topics) {
      try {
        await syncSingleTopic(topic, today, currentYear);
        // Small delay to respect OpenAlex rate limits.
        await sleep(500);
      } catch (err) {
        logger.error(`Failed to sync topic "${topic}"`, err);
      }
    }

    logger.info("syncOpenAlexTrends: completed");
  }
);

async function syncSingleTopic(
  topic: string,
  today: string,
  currentYear: number
): Promise<void> {
  const normalized = topic.toLowerCase().replace(/[^\w\s]/g, "").trim();
  const docId = `${today}_${normalized.replace(/\s+/g, "-")}`;

  // 1. Get yearly publication counts (group_by).
  const groupByUrl = `${OPENALEX_BASE}/works?search=${encodeURIComponent(topic)}&group_by=publication_year&per_page=200&mailto=${OPENALEX_EMAIL}`;
  const groupByResp = await fetch(groupByUrl);
  if (!groupByResp.ok) {
    throw new Error(`OpenAlex group_by request failed: ${groupByResp.status}`);
  }
  const groupByData = (await groupByResp.json()) as {
    group_by: OpenAlexGroupByResult[];
    meta: { count: number };
  };

  const totalWorks = groupByData.meta?.count ?? 0;
  const yearCounts = new Map<number, number>();

  for (const g of groupByData.group_by ?? []) {
    const year = parseInt(g.key, 10);
    if (!isNaN(year) && year <= currentYear) {
      yearCounts.set(year, g.count);
    }
  }

  // 2. Compute metrics.
  const thisYearCount = yearCounts.get(currentYear) ?? 0;
  const lastYearCount = yearCounts.get(currentYear - 1) ?? 1; // avoid /0
  const recentGrowth =
    lastYearCount > 0
      ? (thisYearCount - lastYearCount) / lastYearCount
      : 0;

  // Sum of last 2 years as "recent" proxy.
  const recentWorksCount =
    thisYearCount + (yearCounts.get(currentYear - 1) ?? 0);

  // 3. Compute trend score (0–100).
  const volumeScore = Math.min(totalWorks / 100000, 1.0) * 30;
  const growthScore = Math.min(Math.max(recentGrowth, 0), 1.0) * 50;
  const recencyScore =
    totalWorks > 0 ? (recentWorksCount / totalWorks) * 20 : 0;
  const trendScore = Math.round(
    (volumeScore + growthScore + recencyScore) * 100
  ) / 100;

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
  } catch {
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

  logger.info(
    `Synced trend: "${topic}" → score=${trendScore}, growth=${(recentGrowth * 100).toFixed(1)}%`
  );
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
