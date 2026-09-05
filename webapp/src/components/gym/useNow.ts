"use client";

import { useMemo, useSyncExternalStore } from "react";

/**
 * 「いま」を購読する（営業中判定に使う。判定そのものは lib/gym/hours.ts＝JST 固定）。
 *
 * - `initialMs` を渡すと SSR とハイドレーションで同じ時刻を使える（検索ページ: サーバーのリクエスト時刻）。
 * - 渡さないとサーバー描画とハイドレーション中は null（静的な都道府県ページに古い OPEN を焼き込まない）。
 * - ブラウザでは 1 分ごとに更新される（購読者が居る間だけタイマーを回す）。
 */

const listeners = new Set<() => void>();
let tick = 0;
let timer: number | null = null;

function subscribe(cb: () => void) {
  listeners.add(cb);
  if (timer === null) {
    timer = window.setInterval(() => {
      tick += 1;
      listeners.forEach((l) => l());
    }, 60_000);
  }
  return () => {
    listeners.delete(cb);
    if (listeners.size === 0 && timer !== null) {
      window.clearInterval(timer);
      timer = null;
    }
  };
}

const getSnapshot = () => tick;
/** サーバー／ハイドレーション中は -1 */
const getServerSnapshot = () => -1;

export function useNow(initialMs?: number | null): Date | null {
  const t = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
  return useMemo(() => {
    if (t === -1) return initialMs ? new Date(initialMs) : null;
    return new Date();
  }, [t, initialMs]);
}
