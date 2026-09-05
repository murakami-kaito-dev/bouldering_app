import type { Metadata } from "next";
import Link from "next/link";
import { env } from "@/lib/env";
import { getAllGyms } from "@/lib/api/gyms";
import { getAllTweets } from "@/lib/api/tweets";
import { isOpenNow, nowHHMMJst, openStatus } from "@/lib/gym/hours";
import { sortByPopularity } from "@/lib/gym/types";
import { Container, SectionHeader } from "@/components/ui/Primitives";
import { LinkButton } from "@/components/ui/Button";
import { Tape } from "@/components/ui/Tape";
import { AdSlot } from "@/components/ads/AdSlot";
import { AppCta } from "@/components/site/AppCta";
import { TweetCard } from "@/components/tweet/TweetCard";
import { HomeHero } from "@/components/home/HomeHero";
import { HomeGymCard } from "@/components/home/HomeGymCard";
import { PrefectureGrid } from "@/components/home/PrefectureGrid";

/** 「営業中」の数が JST の現在時刻に依存するため 5 分ごとに再生成 */
export const revalidate = 300;

const TITLE = "イワノボリタイ | 全国のボルダリングジム検索・ボル活記録";
const DESCRIPTION =
  "全国のボルダリング・クライミングジムを地図と条件（営業時間・料金・種別）で探せる。いま営業中のジム、都道府県別の一覧、みんなのボル活記録。";

export const metadata: Metadata = {
  title: { absolute: TITLE },
  description: DESCRIPTION,
  alternates: { canonical: "/" },
  openGraph: { title: TITLE, description: DESCRIPTION, url: "/" },
};

const APP_ONLY = [
  { no: "01", title: "地図で近くを探す", body: "現在地から近いジムを地図の上で。営業中だけに絞ることもできます。" },
  { no: "02", title: "イキタイ登録", body: "気になるジムを保存。イキタイの数はジムの人気にも反映されます。" },
  { no: "03", title: "統計", body: "月ごとの回数・通ったジム・週あたりの平均を自動で集計します。" },
] as const;

export default async function HomePage() {
  const [gyms, latest] = await Promise.all([getAllGyms(), getAllTweets(6)]);
  const now = new Date();

  const openGyms = gyms.filter((g) => isOpenNow(g.hours, now));
  const hasOpen = openGyms.length > 0;
  const featured = sortByPopularity(hasOpen ? openGyms : gyms).slice(0, 6);
  const boulTotal = gyms.reduce((s, g) => s + g.boulCount, 0);

  const counts: Record<string, number> = {};
  for (const g of gyms) counts[g.prefecture] = (counts[g.prefecture] ?? 0) + 1;

  const siteUrl = env.siteUrl.replace(/\/$/, "");
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: "イワノボリタイ",
    url: `${siteUrl}/`,
    inLanguage: "ja",
    potentialAction: {
      "@type": "SearchAction",
      target: { "@type": "EntryPoint", urlTemplate: `${siteUrl}/gyms?q={search_term_string}` },
      "query-input": "required name=search_term_string",
    },
  };

  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

      <HomeHero gymCount={gyms.length} openCount={openGyms.length} boulTotal={boulTotal} renderedAtJst={nowHHMMJst(now)} />

      <Container className="flex flex-col gap-12 py-12 md:gap-16 md:py-16">
        {/* いま営業中（深夜など 0 件のときは人気のジム） */}
        <section className="flex flex-col gap-6" aria-labelledby="home-open">
          <SectionHeader
            eyebrow={hasOpen ? "OPEN NOW · JST" : "POPULAR"}
            title={<span id="home-open">{hasOpen ? "いま営業中" : "人気のジム"}</span>}
            aside={
              <LinkButton href={hasOpen ? "/gyms?open=1" : "/gyms"} variant="ghost" size="sm">
                {hasOpen ? "営業中をすべて見る" : "すべてのジムを見る"}
              </LinkButton>
            }
          />
          {featured.length > 0 ? (
            <ul className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {featured.map((g) => (
                <li key={g.id}>
                  <HomeGymCard gym={g} status={openStatus(g.hours, now)} />
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-dust">ジムの情報を読み込めませんでした。時間をおいて再度お試しください。</p>
          )}
        </section>

        <AdSlot format="banner" />

        <section className="flex flex-col gap-6" aria-labelledby="home-area">
          <SectionHeader eyebrow="AREA" title={<span id="home-area">都道府県から探す</span>} />
          <PrefectureGrid counts={counts} />
        </section>

        <section className="flex flex-col gap-6" aria-labelledby="home-log">
          <SectionHeader
            eyebrow="BOUL LOG"
            title={<span id="home-log">新着ボル活</span>}
            aside={
              <LinkButton href="/boul-log" variant="ghost" size="sm">
                もっと見る
              </LinkButton>
            }
          />
          {latest.items.length > 0 ? (
            <ul className="grid gap-4 md:grid-cols-2">
              {latest.items.map((t) => (
                <li key={t.id}>
                  <TweetCard tweet={t} className="h-full" />
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-dust">
              まだボル活の投稿がありません。
              <Link href="/post" className="text-wall hover:underline underline-offset-4">
                最初のボル活を投稿する
              </Link>
            </p>
          )}
        </section>

        <section className="flex flex-col gap-6" aria-labelledby="home-app">
          <SectionHeader eyebrow="iOS APP" title={<span id="home-app">アプリでできること</span>} />
          <div className="grid gap-4 lg:grid-cols-2">
            <AppCta />
            <ul className="flex flex-col gap-3">
              {APP_ONLY.map((f) => (
                <li key={f.no} className="flex items-start gap-4 rounded-card bg-joint p-4">
                  <Tape tone="wall">{f.no}</Tape>
                  <div className="flex flex-col gap-1">
                    <h3 className="text-h3">{f.title}</h3>
                    <p className="text-small text-dust">{f.body}</p>
                  </div>
                </li>
              ))}
            </ul>
          </div>
        </section>
      </Container>
    </>
  );
}
