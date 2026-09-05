"use client";

import { useState, type ReactNode } from "react";
import type { Tweet } from "@/lib/api/types";
import { GYM_TWEETS_PAGE_SIZE, type TweetsPage } from "./tweetsPage";
import { TweetCard } from "@/components/tweet/TweetCard";
import { Button } from "@/components/ui/Button";
import { Skeleton } from "@/components/ui/Primitives";

function TweetSkeleton() {
  return (
    <div className="flex flex-col gap-3 rounded-card bg-joint p-4 md:p-5" aria-hidden="true">
      <div className="flex items-center gap-3">
        <div className="h-10 w-10 animate-pulse rounded-pill bg-ledge" />
        <div className="flex flex-col gap-2">
          <Skeleton className="h-4 w-32" />
          <Skeleton className="h-3 w-24" />
        </div>
      </div>
      <Skeleton className="h-4 w-full" />
      <Skeleton className="h-4 w-2/3" />
    </div>
  );
}

/**
 * ジム詳細のボル活タブ。初期ページはサーバーで描画し、続きは BFF（/api/gyms/[id]/tweets）から cursor で取る。
 * ブラウザからバックエンドを直接叩かない。
 */
export function GymTweetList({ gymId, initial, emptyCta }: { gymId: number; initial: TweetsPage; emptyCta: ReactNode }) {
  const [items, setItems] = useState<Tweet[]>(initial.items);
  const [cursor, setCursor] = useState<string | null>(initial.nextCursor);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function loadMore() {
    if (!cursor || loading) return;
    setLoading(true);
    setError(null);
    try {
      const qs = new URLSearchParams({ cursor, limit: String(GYM_TWEETS_PAGE_SIZE) });
      const res = await fetch(`/api/gyms/${gymId}/tweets?${qs}`, { headers: { Accept: "application/json" } });
      if (!res.ok) throw new Error(`BFF ${res.status}`);
      const page = (await res.json()) as TweetsPage;
      setItems((prev) => {
        const seen = new Set(prev.map((t) => t.id));
        return [...prev, ...page.items.filter((t) => !seen.has(t.id))];
      });
      setCursor(page.nextCursor);
    } catch {
      setError("読み込めませんでした。もう一度お試しください。");
    } finally {
      setLoading(false);
    }
  }

  if (items.length === 0) {
    return (
      <div className="flex flex-col gap-4">
        <div className="rounded-card border border-dashed border-crack px-5 py-8 text-center">
          <p className="text-[15px] text-dust">このジムのボル活はまだありません。アプリから最初の記録を残しましょう</p>
        </div>
        {emptyCta}
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-3">
      <ul className="flex flex-col gap-3" aria-label="ボル活の一覧">
        {items.map((t) => (
          <li key={t.id}>
            <TweetCard tweet={t} showGym={false} />
          </li>
        ))}
      </ul>
      {loading ? (
        <div className="flex flex-col gap-3" aria-live="polite" aria-busy="true">
          <TweetSkeleton />
          <TweetSkeleton />
        </div>
      ) : null}
      {error ? (
        <p role="alert" className="text-small text-hold-red">
          {error}
        </p>
      ) : null}
      <div className="flex justify-center pt-2">
        <Button variant="secondary" onClick={loadMore} disabled={!cursor || loading} aria-disabled={!cursor || loading}>
          {cursor ? (loading ? "読み込み中…" : "もっと見る") : "すべて表示しました"}
        </Button>
      </div>
    </div>
  );
}
