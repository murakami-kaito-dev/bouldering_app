import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { getAllGyms } from "@/lib/api/gyms";
import { PREFECTURES, PREFECTURE_SLUGS, REGIONS, prefectureFromSlug } from "@/lib/gym/prefectures";
import { countByType, sortGyms, toGymSummary, type GymSummary } from "@/lib/gym/search";
import { GYM_TYPE_META } from "@/lib/gym/types";
import { AreaExplorer } from "@/components/gym/AreaExplorer";
import { AdSlot } from "@/components/ads/AdSlot";
import { AppCta } from "@/components/site/AppCta";
import { LinkButton } from "@/components/ui/Button";
import { Container, Eyebrow, SectionHeader } from "@/components/ui/Primitives";

/**
 * /gyms/area/[slug] — 都道府県別の一覧（SEO 用の着地ページ）。47 都道府県を静的生成し、1 時間ごとに再生成。
 */
export const revalidate = 3600;

export function generateStaticParams() {
  return PREFECTURES.map((p) => ({ slug: PREFECTURE_SLUGS[p] }));
}

async function loadPrefectureGyms(prefecture: string): Promise<GymSummary[]> {
  const all = await getAllGyms();
  return sortGyms(
    all.filter((g) => g.prefecture === prefecture).map(toGymSummary),
    "geo",
    null,
  );
}

export async function generateMetadata({ params }: PageProps<"/gyms/area/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const pref = prefectureFromSlug(slug);
  if (!pref) notFound();
  const gyms = await loadPrefectureGyms(pref);
  const title = `${pref}のボルダリングジム一覧（${gyms.length}件）`;
  const c = countByType(gyms);
  const description = `${pref}のボルダリング・クライミングジム ${gyms.length} 件を市区町村ごとに掲載。ボルダリング ${c.bouldering} 件・リード ${c.lead} 件・スピード ${c.speed} 件。営業時間・料金・地図と、みんなのボル活記録。`;
  return {
    title,
    description,
    alternates: { canonical: `/gyms/area/${slug}` },
    openGraph: { title: `${title} | イワノボリタイ`, description },
  };
}

export default async function AreaPage({ params }: PageProps<"/gyms/area/[slug]">) {
  const { slug } = await params;
  const pref = prefectureFromSlug(slug);
  if (!pref) notFound();

  const gyms = await loadPrefectureGyms(pref);
  const c = countByType(gyms);
  const region = REGIONS.find((r) => r.prefectures.includes(pref));
  const siblings = region ? region.prefectures.filter((p) => p !== pref) : [];
  const cities = new Set(gyms.map((g) => g.city).filter(Boolean)).size;

  const typeSentence = [
    c.bouldering ? `${GYM_TYPE_META.bouldering.label} ${c.bouldering} 件` : null,
    c.lead ? `${GYM_TYPE_META.lead.label} ${c.lead} 件` : null,
    c.speed ? `${GYM_TYPE_META.speed.label} ${c.speed} 件` : null,
  ]
    .filter(Boolean)
    .join("・");

  return (
    <Container className="flex flex-col gap-10 py-8 md:py-12">
      <header className="flex flex-col gap-3">
        <nav aria-label="パンくず" className="text-small text-dust">
          <ol className="flex flex-wrap items-center gap-2">
            <li>
              <Link href="/gyms" className="hover:text-chalk hover:underline underline-offset-4">
                ジムを探す
              </Link>
            </li>
            <li aria-hidden="true">/</li>
            {region ? (
              <>
                <li>{region.name}</li>
                <li aria-hidden="true">/</li>
              </>
            ) : null}
            <li aria-current="page" className="text-chalk">
              {pref}
            </li>
          </ol>
        </nav>
        <Eyebrow className="flex items-center gap-2">
          <span>{PREFECTURE_SLUGS[pref]}</span>
          <span aria-hidden="true">·</span>
          <span className="font-numeric text-[14px] font-bold text-chalk">{gyms.length}</span>
          <span>GYMS</span>
        </Eyebrow>
        <h1 className="text-h1">
          {pref}のボルダリングジム一覧（{gyms.length}件）
        </h1>
        <p className="max-w-[60ch] text-body text-dust">
          {gyms.length > 0
            ? `${pref}には ${cities} の市区町村に ${gyms.length} 件のクライミングジムがあります（${typeSentence}）。市区町村ごとに並べているので、通いやすい場所から比べられます。`
            : `${pref}のジムはまだ登録がありません。近くの都道府県も見てみてください。`}
        </p>
        <div className="flex flex-wrap gap-2 pt-1">
          <LinkButton href={`/gyms?pref=${encodeURIComponent(pref)}`} variant="secondary" size="sm">
            条件を足して探す
          </LinkButton>
        </div>
      </header>

      <AreaExplorer gyms={gyms} prefecture={pref} />

      <AdSlot format="banner" />

      {siblings.length > 0 ? (
        <section className="flex flex-col gap-5">
          <SectionHeader eyebrow={region?.name} title={`${region?.name}のほかの都道府県`} />
          <ul className="flex flex-wrap gap-2">
            {siblings.map((p) => (
              <li key={p}>
                <Link
                  href={`/gyms/area/${PREFECTURE_SLUGS[p]}`}
                  className="pressable inline-flex h-9 items-center rounded-pill border border-crack px-4 text-[14px] font-medium text-chalk hover:bg-ledge"
                >
                  {p}
                </Link>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      <AppCta />
    </Container>
  );
}
