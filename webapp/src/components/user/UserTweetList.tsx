"use client";

import { useState } from "react";
import type { Tweet } from "@/lib/api/types";
import type { TweetPage } from "@/lib/api/tweets";
import { bff, BffError, useAuth } from "@/lib/auth";
import { TweetCard } from "@/components/tweet/TweetCard";
import { Button } from "@/components/ui/Button";

/**
 * ユーザーのボル活一覧（「もっと見る」付き）。
 * - mode="public": /api/me/users/[id]/tweets（認証不要）
 * - mode="me"    : /api/me/tweets（要トークン）＋削除
 */
export function UserTweetList({
  mode,
  userId,
  initial,
  onDeleted,
}: {
  mode: "public" | "me";
  userId?: string;
  initial: TweetPage;
  onDeleted?: (id: number) => void;
}) {
  const { getIdToken } = useAuth();
  const [items, setItems] = useState<Tweet[]>(initial.items);
  const [cursor, setCursor] = useState<string | null>(initial.nextCursor);
  const [loading, setLoading] = useState(false);
  const [deleting, setDeleting] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);

  const endpoint = mode === "me" ? "/api/me/tweets" : `/api/me/users/${encodeURIComponent(userId ?? "")}/tweets`;

  const loadMore = async () => {
    if (!cursor || loading) return;
    setLoading(true);
    setError(null);
    try {
      const token = mode === "me" ? await getIdToken() : null;
      const page = await bff<TweetPage>(`${endpoint}?cursor=${encodeURIComponent(cursor)}`, { token });
      setItems((prev) => {
        const seen = new Set(prev.map((t) => t.id));
        return [...prev, ...page.items.filter((t) => !seen.has(t.id))];
      });
      setCursor(page.nextCursor);
    } catch (e) {
      setError(e instanceof BffError ? e.message : "読み込みに失敗しました");
    } finally {
      setLoading(false);
    }
  };

  const remove = async (t: Tweet) => {
    if (!window.confirm(`${t.gymName} のボル活（${t.visitedDate}）を削除します。元に戻せません。よろしいですか？`)) return;
    setDeleting(t.id);
    setError(null);
    try {
      const token = await getIdToken();
      await bff(`/api/me/tweets/${t.id}`, { method: "DELETE", token });
      setItems((prev) => prev.filter((x) => x.id !== t.id));
      onDeleted?.(t.id);
    } catch (e) {
      setError(e instanceof BffError ? e.message : "削除に失敗しました");
    } finally {
      setDeleting(null);
    }
  };

  if (items.length === 0) {
    return (
      <p className="rounded-card border border-dashed border-crack px-5 py-8 text-center text-dust">
        {mode === "me" ? "まだボル活がありません。登った日を記録しましょう。" : "まだボル活がありません。"}
      </p>
    );
  }

  return (
    <div className="flex flex-col gap-3">
      {items.map((t) => (
        <div key={t.id} className="relative">
          <TweetCard tweet={t} />
          {mode === "me" ? (
            <button
              type="button"
              onClick={() => remove(t)}
              disabled={deleting === t.id}
              className="pressable absolute right-4 top-4 rounded-pill border border-crack px-3 py-1 text-[12px] font-bold text-dust hover:border-hold-red hover:text-hold-red disabled:opacity-50 md:right-5 md:top-5"
              aria-label="このボル活を削除"
            >
              {deleting === t.id ? "削除中…" : "削除"}
            </button>
          ) : null}
        </div>
      ))}
      {error ? (
        <p role="alert" className="text-small text-hold-red">
          {error}
        </p>
      ) : null}
      {cursor ? (
        <div className="flex justify-center pt-2">
          <Button variant="secondary" onClick={loadMore} disabled={loading}>
            {loading ? "読み込み中…" : "もっと見る"}
          </Button>
        </div>
      ) : null}
    </div>
  );
}
