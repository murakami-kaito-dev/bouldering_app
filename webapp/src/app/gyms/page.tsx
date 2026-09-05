import type { Metadata } from "next";
import { Suspense } from "react";
import { getAllGyms } from "@/lib/api/gyms";
import { parseSearchParams, searchGyms, toGymSummary, type GymSummary, type SearchState } from "@/lib/gym/search";
import { GymSearch } from "@/components/gym/GymSearch";
import { GymSearchSkeleton } from "@/components/gym/GymSearchSkeleton";
import { LinkButton } from "@/components/ui/Button";
import { Container, Eyebrow } from "@/components/ui/Primitives";

/**
 * /gyms — 検索ページ。
 * `?q=&pref=東京都,神奈川県&type=bouldering,lead&open=1&sort=popular|geo|near`
 * サーバーで初期絞り込みを済ませて HTML に出し、その後はブラウザ側（GymSearch）が URL と状態を持つ。
 *
 * 読込中の骨組みは `loading.tsx` ではなく、このページ内の Suspense で出す
 * （`app/gyms/loading.tsx` は /gyms/[id]・/gyms/area/* も包んでしまい、それらの 404 が 200 になるため）。
 */

async function loadSummaries(): Promise<GymSummary[] | null> {
  try {
    return (await getAllGyms()).map(toGymSummary);
  } catch {
    return null;
  }
}

export async function generateMetadata(): Promise<Metadata> {
  const all = await loadSummaries();
  const n = all ? all.length : null;
  const description = n
    ? `全国 ${n} 件のボルダリングジムを、都道府県・種別（ボルダリング／リード／スピード）・営業中・現在地からの距離で絞り込み、地図と一覧で比べられます。`
    : "全国のボルダリングジムを、都道府県・種別・営業中・現在地からの距離で絞り込み、地図と一覧で比べられます。";
  return {
    title: "ジムを探す",
    description,
    alternates: { canonical: "/gyms" },
    openGraph: { title: "ジムを探す | イワノボリタイ", description },
  };
}

export default async function GymsPage({ searchParams }: PageProps<"/gyms">) {
  const state = parseSearchParams(await searchParams);
  return (
    <Suspense fallback={<GymSearchSkeleton />}>
      <SearchResults state={state} />
    </Suspense>
  );
}

/** データ取得と初期絞り込み。Suspense の中で待つので、骨組みが先に届く */
async function SearchResults({ state }: { state: SearchState }) {
  const all = await loadSummaries();

  if (!all) {
    return (
      <Container className="flex min-h-[50vh] flex-col items-start justify-center gap-4 py-16">
        <Eyebrow>GYMS · ERROR</Eyebrow>
        <h1 className="text-h1">ジム情報を取得できませんでした</h1>
        <p className="max-w-[40ch] text-dust">しばらく待ってから、もう一度読み込んでください。</p>
        <LinkButton href="/gyms" variant="secondary">
          もう一度読み込む
        </LinkButton>
      </Container>
    );
  }

  const now = new Date();
  const initial = searchGyms(all, state, now);
  const isComplete = initial.length === all.length;

  return <GymSearch initialGyms={initial} total={all.length} isComplete={isComplete} initialState={state} nowMs={now.getTime()} />;
}
