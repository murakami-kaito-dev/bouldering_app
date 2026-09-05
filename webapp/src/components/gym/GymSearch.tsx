"use client";

import { usePathname, useSearchParams } from "next/navigation";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { isOpenNow } from "@/lib/gym/hours";
import {
  EMPTY_SEARCH,
  hasActiveFilters,
  parseSearchParams,
  searchGyms,
  serializeSearchState,
  type GeoPoint,
  type GymSummary,
  type GymSummaryResponse,
  type SearchState,
} from "@/lib/gym/search";
import { GYM_TYPE_META } from "@/lib/gym/types";
import { Button } from "@/components/ui/Button";
import { Eyebrow } from "@/components/ui/Primitives";
import { GymTypeTape, Tape } from "@/components/ui/Tape";
import { GymCard } from "./GymCard";
import { GymList } from "./GymList";
import { GymMap } from "./GymMap";
import { SearchFilters, type GeoStatus } from "./SearchFilters";
import { useNow } from "./useNow";

export interface GymSearchProps {
  /** SSR で絞り込み済みの初期結果（isComplete のときは全件） */
  initialGyms: GymSummary[];
  total: number;
  /** initialGyms が全件かどうか。false ならブラウザで /api/gyms を一度だけ取得する */
  isComplete: boolean;
  initialState: SearchState;
  /** サーバーのリクエスト時刻（営業中判定を SSR とハイドレーションで揃える） */
  nowMs: number;
}

const URL_SYNC_DELAY_MS = 200;

/**
 * 検索ページの司令塔（クライアント）。
 *
 * URL 状態の流れ:
 *   1. サーバー（page.tsx）が `searchParams` を parseSearchParams で SearchState にし、初期結果と一緒に渡す。
 *   2. ここが state を持ち、変更のたびに serializeSearchState → `window.history.replaceState` で URL を書き換える
 *      （Next 16 はネイティブ History API を Router に統合しているので useSearchParams と同期し、サーバー往復は起きない）。
 *   3. 外から URL が変わったとき（フッターの都道府県リンク等・戻る/進む）は useSearchParams の変化を検知して state に取り込む。
 *   4. 絞り込み・並び替えは全件（GymSummary）をメモリ上で行う。全件が無いときは /api/gyms（BFF）を一度だけ取得する。
 */
export function GymSearch({ initialGyms, total, isComplete, initialState, nowMs }: GymSearchProps) {
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const [state, setState] = useState<SearchState>(initialState);
  const [allGyms, setAllGyms] = useState<GymSummary[] | null>(isComplete ? initialGyms : null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [origin, setOrigin] = useState<GeoPoint | null>(null);
  /** 現在地取得の結果（取得中は state ではなく「near かつ未取得」から導く） */
  const [geoResult, setGeoResult] = useState<Exclude<GeoStatus, "idle" | "locating">>("ready");
  const [rawSelectedId, setSelectedId] = useState<number | null>(null);
  const [hoveredId, setHoveredId] = useState<number | null>(null);
  const [mapOpen, setMapOpen] = useState(false);

  const nowFromClock = useNow(nowMs);
  const now = useMemo(() => nowFromClock ?? new Date(nowMs), [nowFromClock, nowMs]);

  // ---- 全件の取得（BFF）
  useEffect(() => {
    if (allGyms) return;
    const ac = new AbortController();
    fetch("/api/gyms", { signal: ac.signal })
      .then(async (r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return (await r.json()) as GymSummaryResponse;
      })
      .then((data) => setAllGyms(data.gyms))
      .catch((e: unknown) => {
        if (ac.signal.aborted) return;
        setLoadError(e instanceof Error ? e.message : "取得に失敗しました");
      });
    return () => ac.abort();
  }, [allGyms]);

  // ---- URL → state（外部からの変更。自分が書いた値はスキップ）
  const lastWrittenRef = useRef(serializeSearchState(initialState));
  useEffect(() => {
    const incoming = searchParams.toString();
    if (incoming === lastWrittenRef.current) return;
    lastWrittenRef.current = incoming;
    setState(parseSearchParams(new URLSearchParams(incoming)));
  }, [searchParams]);

  // ---- state → URL（replaceState・少し遅らせて入力中の連打を吸収）
  useEffect(() => {
    const next = serializeSearchState(state);
    if (next === lastWrittenRef.current) return;
    const id = window.setTimeout(() => {
      lastWrittenRef.current = next;
      window.history.replaceState(null, "", next ? `${pathname}?${next}` : pathname);
    }, URL_SYNC_DELAY_MS);
    return () => window.clearTimeout(id);
  }, [state, pathname]);

  // ---- 近い順 → 現在地（結果はコールバックで state に入る。取得中かどうかは下で導く）
  const geoRequested = useRef(false);
  useEffect(() => {
    if (state.sort !== "near" || origin || geoRequested.current) return;
    geoRequested.current = true;
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      // 非対応ブラウザ: 外部 API の「失敗コールバック」に相当する扱いで非同期に反映
      Promise.resolve().then(() => setGeoResult("unavailable"));
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setOrigin({ lat: pos.coords.latitude, lng: pos.coords.longitude });
        setGeoResult("ready");
      },
      (err) => {
        geoRequested.current = false; // 次に「近い順」を選び直したら再度試す
        setGeoResult(err.code === err.PERMISSION_DENIED ? "denied" : "unavailable");
      },
      { enableHighAccuracy: false, timeout: 10_000, maximumAge: 5 * 60_000 },
    );
  }, [state.sort, origin]);
  const geoStatus: GeoStatus =
    state.sort !== "near" ? "idle" : origin ? "ready" : geoResult !== "ready" ? geoResult : "locating";

  // ---- 絞り込み・並び替え
  const source = allGyms ?? initialGyms;
  const results = useMemo(() => searchGyms(source, state, now, origin), [source, state, now, origin]);
  const openIds = useMemo(() => new Set(results.filter((g) => isOpenNow(g.hours, now)).map((g) => g.id)), [results, now]);

  // 結果から消えた選択は無いものとして扱う（state を消さずに導出）
  const selectedId = rawSelectedId !== null && results.some((g) => g.id === rawSelectedId) ? rawSelectedId : null;

  // モバイルの全画面地図中は背面のスクロールを止める
  useEffect(() => {
    if (!mapOpen) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, [mapOpen]);

  const update = useCallback((patch: Partial<SearchState>) => setState((s) => ({ ...s, ...patch })), []);
  const clear = useCallback(() => setState((s) => ({ ...EMPTY_SEARCH, sort: s.sort })), []);

  const showDistance = state.sort === "near" && origin ? origin : null;
  const partial = !allGyms; // 全件がまだ無い（初期の絞り込み結果だけで動いている）

  return (
    <div className="mx-auto w-full max-w-[1200px] px-5 md:px-8">
      <div className="lg:grid lg:grid-cols-[440px_minmax(0,1fr)] lg:gap-6">
        {/* ---- 左: フィルタ＋一覧 */}
        <section className="flex flex-col gap-4 py-5 lg:py-6" aria-label="ジム検索">
          <h1 className="sr-only">ジムを探す</h1>
          <SearchFilters state={state} onChange={update} geoStatus={geoStatus} />

          <ResultsHeader state={state} total={total} count={results.length} onClear={clear} partial={partial} loadError={loadError} />

          <GymList
            gyms={results}
            openIds={openIds}
            selectedId={selectedId}
            hoveredId={hoveredId}
            onHover={setHoveredId}
            origin={showDistance}
            ads
            onClearFilters={hasActiveFilters(state) ? clear : undefined}
          />
        </section>

        {/* ---- 右: 地図（≥1024px・sticky） */}
        <aside className="hidden lg:block" aria-label="地図">
          <div className="sticky top-16 h-[calc(100vh-64px)] py-6">
            <GymMap id="search-map" className="h-full" gyms={results} selectedId={selectedId} hoveredId={hoveredId} onSelect={setSelectedId} origin={showDistance} openIds={openIds} />
          </div>
        </aside>
      </div>

      {/* ---- <1024px: 地図ボタンと全画面地図 */}
      {!mapOpen ? (
        <div className="pointer-events-none fixed inset-x-0 bottom-6 z-30 flex justify-center lg:hidden">
          <Button size="md" className="pointer-events-auto border border-wall-bright/40" onClick={() => setMapOpen(true)} aria-haspopup="dialog">
            <MapGlyph />
            地図
            <span className="font-numeric text-[13px] font-semibold tracking-[0.04em] text-wall-ink/80">{results.length}</span>
          </Button>
        </div>
      ) : (
        <MobileMapOverlay
          gyms={results}
          openIds={openIds}
          selectedId={selectedId}
          onSelect={setSelectedId}
          origin={showDistance}
          onClose={() => setMapOpen(false)}
        />
      )}
    </div>
  );
}

// ---------------------------------------------------------------- 結果ヘッダ

function ResultsHeader({
  state,
  total,
  count,
  onClear,
  partial,
  loadError,
}: {
  state: SearchState;
  total: number;
  count: number;
  onClear: () => void;
  partial: boolean;
  loadError: string | null;
}) {
  const active = hasActiveFilters(state);
  return (
    <div className="flex flex-col gap-2 border-b border-crack pb-3">
      <div className="flex items-center justify-between gap-3">
        <Eyebrow className="flex items-center gap-2" aria-live="polite">
          <span>GYMS</span>
          <span className="font-numeric text-[14px] font-bold text-chalk">{total}</span>
          {active ? (
            <>
              <span aria-hidden="true">→</span>
              <span className="font-numeric text-[14px] font-bold text-chalk">{count}</span>
              <span className="sr-only">件に絞り込み</span>
            </>
          ) : null}
          {partial ? <span className="text-ash">· 全件を読込中</span> : null}
        </Eyebrow>
        {active ? (
          <Button variant="ghost" size="sm" className="px-2" onClick={onClear}>
            すべて解除
          </Button>
        ) : null}
      </div>
      {active ? (
        <div className="flex flex-wrap items-center gap-1.5" aria-label="適用中の条件">
          {state.q ? <Tape tone="chalk">「{state.q}」</Tape> : null}
          {state.prefs.map((p) => (
            <Tape key={p} tone="wall">
              {p.replace(/[都府県]$/, "")}
            </Tape>
          ))}
          {state.types.map((t) => (
            <GymTypeTape key={t} type={t} />
          ))}
          {state.open ? (
            <Tape tone="green" filled>
              営業中
            </Tape>
          ) : null}
          {state.types.length === 0 && state.prefs.length === 0 && !state.q && !state.open ? null : (
            <span className="sr-only">{state.types.map((t) => GYM_TYPE_META[t].label).join("・")}</span>
          )}
        </div>
      ) : null}
      {loadError ? (
        <p className="text-small text-hold-red" role="alert">
          全件の読み込みに失敗しました（{loadError}）。表示中の結果内でのみ絞り込めます。
        </p>
      ) : null}
    </div>
  );
}

// ---------------------------------------------------------------- モバイルの全画面地図

function MobileMapOverlay({
  gyms,
  openIds,
  selectedId,
  onSelect,
  origin,
  onClose,
}: {
  gyms: GymSummary[];
  openIds: Set<number>;
  selectedId: number | null;
  onSelect: (id: number | null) => void;
  origin: GeoPoint | null;
  onClose: () => void;
}) {
  const railRef = useRef<HTMLDivElement>(null);
  const scrollTimer = useRef<number | null>(null);

  // Escape で閉じる
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [onClose]);

  // マーカー選択 → カルーセルを寄せる
  useEffect(() => {
    if (selectedId === null || !railRef.current) return;
    const el = railRef.current.querySelector<HTMLElement>(`[data-rail-id="${selectedId}"]`);
    el?.scrollIntoView({ inline: "center", block: "nearest", behavior: "smooth" });
  }, [selectedId]);

  // カルーセルのスクロール停止 → 中央のカードを選択
  const onRailScroll = () => {
    if (scrollTimer.current) window.clearTimeout(scrollTimer.current);
    scrollTimer.current = window.setTimeout(() => {
      const rail = railRef.current;
      if (!rail) return;
      const center = rail.scrollLeft + rail.clientWidth / 2;
      let bestId: number | null = null;
      let bestDistance = Number.POSITIVE_INFINITY;
      for (const el of Array.from(rail.querySelectorAll<HTMLElement>("[data-rail-id]"))) {
        const d = Math.abs(el.offsetLeft + el.offsetWidth / 2 - center);
        if (d < bestDistance) {
          bestDistance = d;
          bestId = Number(el.dataset.railId);
        }
      }
      if (bestId !== null && bestId !== selectedId) onSelect(bestId);
    }, 120);
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-rock lg:hidden" role="dialog" aria-modal="true" aria-label="地図でジムを探す">
      <div className="flex h-14 shrink-0 items-center justify-between border-b border-crack px-5">
        <Eyebrow className="flex items-center gap-2">
          <span>MAP</span>
          <span className="font-numeric text-[14px] font-bold text-chalk">{gyms.length}</span>
        </Eyebrow>
        <Button variant="secondary" size="sm" onClick={onClose}>
          <ListGlyph />
          リスト
        </Button>
      </div>
      <div className="min-h-0 flex-1">
        <GymMap id="mobile-map" className="h-full rounded-none border-0" gyms={gyms} selectedId={selectedId} onSelect={onSelect} origin={origin} openIds={openIds} />
      </div>
      {/* カードのカルーセル（地図の下。Google のロゴ・帰属表示を隠さない） */}
      {gyms.length > 0 ? (
        <div
          ref={railRef}
          onScroll={onRailScroll}
          className="flex shrink-0 snap-x snap-mandatory gap-3 overflow-x-auto border-t border-crack bg-rock px-5 py-3 [scrollbar-width:none]"
          aria-label="ジムのカード"
        >
          {gyms.map((g) => (
            <div key={g.id} data-rail-id={g.id} className="w-[300px] shrink-0 snap-center">
              <GymCard gym={g} open={openIds.has(g.id)} selected={g.id === selectedId} compact className="border-crack" />
            </div>
          ))}
        </div>
      ) : null}
    </div>
  );
}

function MapGlyph() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <path d="M1.5 3.5l4-1.5 5 1.5 4-1.5v10l-4 1.5-5-1.5-4 1.5v-10z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
      <path d="M5.5 2v10M10.5 3.5v10" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

function ListGlyph() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <path d="M2 4h12M2 8h12M2 12h12" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
    </svg>
  );
}
