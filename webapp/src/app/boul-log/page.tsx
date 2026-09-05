import type { Metadata } from "next";
import Link from "next/link";
import { getAllTweets } from "@/lib/api/tweets";
import { Container, Eyebrow } from "@/components/ui/Primitives";
import { TweetFeed } from "@/components/tweet/TweetFeed";

export const revalidate = 60;

const PAGE_SIZE = 20;

export const metadata: Metadata = {
  title: "みんなのボル活",
  description: "全国のクライマーが投稿した「ボル活」（登った日・ジム・写真）の新着一覧。イワノボリタイのボル活記録をまとめて読めます。",
  alternates: { canonical: "/boul-log" },
  openGraph: { title: "みんなのボル活 | イワノボリタイ", url: "/boul-log" },
};

export default async function BoulLogPage() {
  const first = await getAllTweets(PAGE_SIZE);
  return (
    <Container narrow className="flex flex-col gap-8 py-10 md:py-14">
      <header className="flex flex-col gap-3">
        <Eyebrow>BOUL LOG</Eyebrow>
        <h1 className="text-h1">みんなのボル活</h1>
        <span className="tape-rule" aria-hidden="true" />
        <p className="text-dust">
          登った記録は iOS アプリ、または{" "}
          <Link href="/post" className="text-wall hover:underline underline-offset-4">
            Web の投稿ページ
          </Link>
          （ログインが必要）から投稿できます。
        </p>
      </header>
      <TweetFeed initial={first} pageSize={PAGE_SIZE} />
    </Container>
  );
}
