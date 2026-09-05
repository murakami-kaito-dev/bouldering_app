import Link from "next/link";
import { Container, Eyebrow, Stat } from "@/components/ui/Primitives";
import { Button, LinkButton } from "@/components/ui/Button";
import { Tape } from "@/components/ui/Tape";
import { PREFECTURE_SLUGS, type Prefecture } from "@/lib/gym/prefectures";

/** ヒーロー直下のクイックリンク（ジム数の多い都道府県） */
const QUICK_PREFECTURES: Prefecture[] = ["東京都", "神奈川県", "埼玉県", "千葉県", "大阪府", "愛知県", "福岡県", "北海道"];

const fmt = (n: number) => n.toLocaleString("ja-JP");

/**
 * ホームの「壁」。主張（見出し）＋検索の計器＋課題ボード（全国の数字）。
 * フォームは JS 無しでも /gyms?q= に飛ぶ（plain GET form）。
 */
export function HomeHero({
  gymCount,
  openCount,
  boulTotal,
  renderedAtJst,
}: {
  gymCount: number;
  openCount: number;
  boulTotal: number;
  /** 営業中の数を数えた時刻（JST "HH:MM"）。ページは 5 分ごとに再生成される */
  renderedAtJst: string;
}) {
  return (
    <section className="grain border-b border-crack bg-joint">
      <Container className="relative grid grid-cols-[minmax(0,1fr)] gap-10 py-14 md:py-20 lg:grid-cols-[minmax(0,1fr)_340px] lg:items-center lg:gap-16">
        <div className="flex min-w-0 flex-col gap-6">
          <Eyebrow>JAPAN · BOULDERING GYMS</Eyebrow>
          <h1 className="text-display [word-break:keep-all]">
            今日登るジムを、
            <br />
            地図と条件で。
          </h1>
          <p className="max-w-[44ch] text-[16px] leading-[1.7] text-dust">
            全国のボルダリング・クライミングジムを、営業時間・料金・種別で絞り込めます。登った記録は「ボル活」としてみんなと共有。
          </p>

          <form action="/gyms" method="get" role="search" className="flex flex-col gap-3 md:flex-row">
            <label htmlFor="home-q" className="sr-only">
              ジム名・地名
            </label>
            <input
              id="home-q"
              name="q"
              type="search"
              placeholder="ジム名・地名で探す"
              autoComplete="off"
              enterKeyHint="search"
              className="h-13 w-full min-w-0 flex-1 appearance-none rounded-card border border-crack bg-ledge px-5 font-body text-[16px] text-chalk placeholder:text-dust focus-visible:rounded-card focus-visible:border-wall-bright"
            />
            <div className="flex min-w-0 gap-3">
              <Button type="submit" size="lg" className="min-w-0 flex-1 md:flex-none">
                探す
              </Button>
              <LinkButton href="/gyms?sort=near" variant="secondary" size="lg" className="min-w-0 flex-1 md:flex-none">
                現在地から探す
              </LinkButton>
            </div>
          </form>

          <nav aria-label="ジムの多い都道府県" className="flex flex-wrap items-center gap-2">
            <span className="mr-1 text-small text-ash">人気のエリア</span>
            {QUICK_PREFECTURES.map((p) => (
              <Link key={p} href={`/gyms/area/${PREFECTURE_SLUGS[p]}`} className="pressable rounded-tape" aria-label={`${p}のジム一覧`}>
                <Tape tone="chalk">{p.replace(/[都府県]$/, "")}</Tape>
              </Link>
            ))}
          </nav>
        </div>

        {/* 課題ボード。「営業中」は JST の現在時刻に依存するため、ページ全体を revalidate=300 で再生成する */}
        <aside aria-label="全国のジム統計" className="relative flex min-w-0 flex-col gap-5 rounded-card border border-crack bg-rock p-5 md:p-6">
          <div className="flex items-center justify-between gap-3">
            <Eyebrow>GRADE BOARD</Eyebrow>
            <Tape tone="green" filled title="営業中の判定は日本時間">
              JST {renderedAtJst}
            </Tape>
          </div>
          <div className="grid grid-cols-3 gap-3 lg:grid-cols-1 lg:gap-6 [&>*]:min-w-0">
            <Stat label="ジム数" value={fmt(gymCount)} unit="軒" />
            <div data-live="open-now">
              <Stat label="営業中" value={fmt(openCount)} unit="軒" />
            </div>
            <Stat label="ボル活" value={fmt(boulTotal)} unit="件" tone="yellow" />
          </div>
          <p className="text-small text-ash">営業中の数は日本時間 {renderedAtJst} 時点。5 分ごとに更新されます。</p>
        </aside>
      </Container>
    </section>
  );
}
