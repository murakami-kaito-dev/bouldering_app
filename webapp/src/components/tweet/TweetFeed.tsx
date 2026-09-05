"use client";

import { Fragment, useCallback, useState } from "react";
import type { Tweet } from "@/lib/api/types";
import type { TweetPage } from "@/lib/api/tweets";
import { TweetCard } from "./TweetCard";
import { AdSlot } from "@/components/ads/AdSlot";
import { Button, LinkButton } from "@/components/ui/Button";
import { Eyebrow, Skeleton } from "@/components/ui/Primitives";

/** 何件ごとに in-feed 広告を挟むか */
const AD_EVERY = 6;
/** 読込中に見せる骨組みの数 */
const SKELETONS = 3;

/** ボル活カードの骨組み（loading.tsx とフィードの追加読込で共用） */
export function TweetSkeleton() {
  return (
    <div className="flex flex-col gap-3 rounded-card bg-joint p-4 md:p-5" aria-hidden="true">
      <div className="flex items-center gap-3">
        <div className="h-10 w-10 shrink-0 animate-pulse rounded-pill bg-ledge" />
        <div className="flex flex-1 flex-col gap-2">
          <Skeleton className="h-4 w-[30%]" />
          <Skeleton className="h-3 w-[22%]" />
        </div>
        <Skeleton className="h-4 w-[26%]" />
      </div>
      <Skeleton className="h-4 w-[92%]" />
      <Skeleton className="h-4 w-[70%]" />
    </div>
  );
}

function EmptyState() {
  return (
    <div className="flex flex-col items-start gap-4 rounded-card border border-dashed border-crack bg-joint p-6">
      <Eyebrow>NO POSTS YET</Eyebrow>
      <p className="text-chalk">まだボル活の投稿がありません。</p>
      <p className="text-small text-dust">アプリ、または Web の投稿ページ（ログインが必要）から最初のボル活を記録しましょう。</p>
      <LinkButton href="/post" variant="secondary">
        ボル活を投稿する
      </LinkButton>
    </div>
  );
}

/**
 * みんなのボル活のフィード（クライアント）。
 * 最初のページは SSR で props から受け取り、「もっと見る」で BFF `/api/tweets?cursor=` から次ページを足す。
 * カードは 6 件ごとに in-feed 広告枠を挟む。
 */
export function TweetFeed({ initial, pageSize = 20 }: { initial: TweetPage; pageSize?: number }) {
  const [items, setItems] = useState<Tweet[]>(initial.items);
  const [cursor, setCursor] = useState<string | null>(initial.nextCursor);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadMore = useCallback(async () => {
    if (!cursor || loading) return;
    setLoading(true);
    setError(null);
    try {
      const qs = new URLSearchParams({ limit: String(pageSize), cursor });
      const res = await fetch(`/api/tweets?${qs}`, { headers: { Accept: "application/json" } });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const page = (await res.json()) as TweetPage;
      setItems((prev) => {
        const seen = new Set(prev.map((t) => t.id));
        return [...prev, ...page.items.filter((t) => !seen.has(t.id))];
      });
      setCursor(page.nextCursor);
    } catch {
      setError("読み込みに失敗しました。もう一度お試しください。");
    } finally {
      setLoading(false);
    }
  }, [cursor, loading, pageSize]);

  if (items.length === 0) return <EmptyState />;

  return (
    <div className="flex flex-col gap-4">
      <ol className="flex flex-col gap-4" aria-busy={loading}>
        {items.map((t, i) => (
          <Fragment key={t.id}>
            <li>
              <TweetCard tweet={t} />
            </li>
            {(i + 1) % AD_EVERY === 0 ? (
              <li>
                <AdSlot format="infeed" />
              </li>
            ) : null}
          </Fragment>
        ))}
        {loading
          ? Array.from({ length: SKELETONS }, (_, i) => (
              <li key={`skeleton-${i}`}>
                <TweetSkeleton />
              </li>
            ))
          : null}
      </ol>

      <div className="flex flex-col items-center gap-3 py-2">
        <p role="status" aria-live="polite" className="text-small text-hold-red empty:hidden">
          {error}
        </p>
        {cursor ? (
          <Button type="button" variant="secondary" onClick={loadMore} disabled={loading}>
            {loading ? "読み込み中…" : "もっと見る"}
          </Button>
        ) : (
          <p className="text-eyebrow text-ash">END OF LOG · {items.length}</p>
        )}
      </div>
    </div>
  );
}
