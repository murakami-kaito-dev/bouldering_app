import type { MetadataRoute } from "next";
import { env } from "@/lib/env";
import { getAllGyms } from "@/lib/api/gyms";
import { PREFECTURES, PREFECTURE_SLUGS } from "@/lib/gym/prefectures";

/**
 * サイトマップ: 固定ページ ＋ 都道府県ページ ＋ 全ジム詳細。
 * ジム一覧は getAllGyms（1h キャッシュ）。取得に失敗しても固定ページだけは返す。
 */
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = env.siteUrl.replace(/\/$/, "");

  const statics: MetadataRoute.Sitemap = [
    { url: `${base}/`, changeFrequency: "daily", priority: 1 },
    { url: `${base}/gyms`, changeFrequency: "daily", priority: 0.9 },
    { url: `${base}/boul-log`, changeFrequency: "hourly", priority: 0.7 },
    { url: `${base}/about`, changeFrequency: "monthly", priority: 0.3 },
  ];

  let gyms: Awaited<ReturnType<typeof getAllGyms>> = [];
  try {
    gyms = await getAllGyms();
  } catch {
    gyms = [];
  }

  // ジムが 1 件以上ある都道府県だけ（取得失敗時は全都道府県）
  const present = new Set(gyms.map((g) => g.prefecture));
  const areas: MetadataRoute.Sitemap = PREFECTURES.filter((p) => gyms.length === 0 || present.has(p)).map((p) => ({
    url: `${base}/gyms/area/${PREFECTURE_SLUGS[p]}`,
    changeFrequency: "weekly",
    priority: 0.6,
  }));

  const details: MetadataRoute.Sitemap = gyms.map((g) => ({
    url: `${base}/gyms/${g.id}`,
    changeFrequency: "weekly",
    priority: 0.5,
  }));

  return [...statics, ...areas, ...details];
}
