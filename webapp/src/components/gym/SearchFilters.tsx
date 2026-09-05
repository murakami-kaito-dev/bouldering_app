"use client";

import { useEffect, useId, useRef, useState } from "react";
import type { GymType } from "@/lib/api/types";
import { REGIONS } from "@/lib/gym/prefectures";
import { SORT_KEYS, SORT_LABELS, type SearchState, type SortKey } from "@/lib/gym/search";
import { GYM_TYPES, GYM_TYPE_META } from "@/lib/gym/types";
import { Button } from "@/components/ui/Button";
import { GymTypeTape, Tape } from "@/components/ui/Tape";

export type GeoStatus = "idle" | "locating" | "ready" | "denied" | "unavailable";

export interface SearchFiltersProps {
  state: SearchState;
  onChange: (patch: Partial<SearchState>) => void;
  geoStatus: GeoStatus;
}

/**
 * 一覧上部のフィルタ列: テキスト → 都道府県（ポップオーバー／シート）→ 種別テープ → 営業中 → 並び替え。
 * 状態は親（GymSearch）が持ち、ここは表示と入力だけ。「すべて解除」は結果ヘッダ側（GymSearch）にある。
 */
export function SearchFilters({ state, onChange, geoStatus }: SearchFiltersProps) {
  return (
    <div className="flex flex-col gap-3">
      <SearchInput value={state.q} onChange={(q) => onChange({ q })} />

      <div className="flex flex-wrap items-center gap-2">
        <PrefecturePicker selected={state.prefs} onChange={(prefs) => onChange({ prefs })} />
        <span className="mx-1 hidden h-5 w-px bg-crack sm:block" aria-hidden="true" />
        <div className="flex items-center gap-1.5" role="group" aria-label="種別">
          {GYM_TYPES.map((t) => (
            <TypeToggle key={t} type={t} active={state.types.includes(t)} onToggle={() => onChange({ types: toggle(state.types, t) })} />
          ))}
        </div>
        <button
          type="button"
          className="pressable rounded-tape"
          aria-pressed={state.open}
          onClick={() => onChange({ open: !state.open })}
          title="いま営業中のジムだけ（日本時間）"
        >
          <Tape tone="green" filled={state.open}>
            営業中
          </Tape>
        </button>
      </div>

      <div className="flex flex-wrap items-center justify-between gap-2">
        <SortControl value={state.sort} onChange={(sort) => onChange({ sort })} />
      </div>

      {state.sort === "near" && geoStatus !== "ready" ? (
        <p className="text-small text-dust" role="status">
          {geoStatus === "locating"
            ? "現在地を取得しています…"
            : geoStatus === "denied"
              ? "位置情報の利用が許可されていないため、人気順で表示しています。ブラウザの設定で許可すると近い順に並びます。"
              : geoStatus === "unavailable"
                ? "このブラウザでは位置情報を取得できないため、人気順で表示しています。"
                : "現在地を使って近い順に並べます。"}
        </p>
      ) : null}
    </div>
  );
}

function toggle<T>(list: T[], v: T): T[] {
  return list.includes(v) ? list.filter((x) => x !== v) : [...list, v];
}

// ---------------------------------------------------------------- テキスト

function SearchInput({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  const id = useId();
  return (
    <div className="relative">
      <label htmlFor={id} className="sr-only">
        ジム名・地名で探す
      </label>
      <svg className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-dust" width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
        <circle cx="7" cy="7" r="5" stroke="currentColor" strokeWidth="1.6" />
        <path d="M11 11l3.5 3.5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
      </svg>
      <input
        id={id}
        type="search"
        inputMode="search"
        autoComplete="off"
        enterKeyHint="search"
        placeholder="ジム名・地名で探す"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="h-11 w-full rounded-card border border-transparent bg-ledge pl-11 pr-10 text-[15px] text-chalk placeholder:text-dust focus:border-crack focus:outline-none focus-visible:[box-shadow:var(--ring)]"
      />
      {value ? (
        <button
          type="button"
          onClick={() => onChange("")}
          className="pressable absolute right-2 top-1/2 inline-flex h-7 w-7 -translate-y-1/2 items-center justify-center rounded-pill text-dust hover:bg-crack hover:text-chalk"
          aria-label="入力を消す"
        >
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden="true">
            <path d="M2 2l8 8M10 2l-8 8" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
          </svg>
        </button>
      ) : null}
    </div>
  );
}

// ---------------------------------------------------------------- 種別

function TypeToggle({ type, active, onToggle }: { type: GymType; active: boolean; onToggle: () => void }) {
  return (
    <button type="button" className="pressable rounded-tape" aria-pressed={active} onClick={onToggle} aria-label={GYM_TYPE_META[type].label}>
      <GymTypeTape type={type} filled={active} long />
    </button>
  );
}

// ---------------------------------------------------------------- 並び替え

function SortControl({ value, onChange }: { value: SortKey; onChange: (v: SortKey) => void }) {
  return (
    <div className="inline-flex rounded-pill bg-joint p-1" role="group" aria-label="並び替え">
      {SORT_KEYS.map((k) => (
        <button
          key={k}
          type="button"
          aria-pressed={value === k}
          onClick={() => onChange(k)}
          className={`pressable h-8 rounded-pill px-3 font-display text-[13px] font-bold ${value === k ? "bg-ledge text-chalk" : "text-dust hover:text-chalk"}`}
        >
          {SORT_LABELS[k]}
        </button>
      ))}
    </div>
  );
}

// ---------------------------------------------------------------- 都道府県

function PrefecturePicker({ selected, onChange }: { selected: string[]; onChange: (prefs: string[]) => void }) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const panelId = useId();

  // 外側クリック／Escape で閉じる
  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent | TouchEvent) => {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setOpen(false);
        buttonRef.current?.focus();
      }
    };
    document.addEventListener("mousedown", onDown);
    document.addEventListener("touchstart", onDown);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDown);
      document.removeEventListener("touchstart", onDown);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  const label = selected.length === 0 ? "都道府県" : selected.length === 1 ? selected[0] : `都道府県 ${selected.length}`;

  return (
    <div ref={rootRef} className="relative">
      <div className="flex flex-wrap items-center gap-1.5">
        <button
          ref={buttonRef}
          type="button"
          aria-haspopup="dialog"
          aria-expanded={open}
          aria-controls={panelId}
          onClick={() => setOpen((v) => !v)}
          className={`pressable inline-flex h-8 items-center gap-1.5 rounded-pill border px-3 font-display text-[13px] font-bold ${
            selected.length ? "border-wall bg-wall/10 text-chalk" : "border-crack text-chalk hover:bg-ledge"
          }`}
        >
          {label}
          <svg width="10" height="10" viewBox="0 0 10 10" fill="none" aria-hidden="true" className={open ? "rotate-180" : ""}>
            <path d="M2 3.5l3 3 3-3" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
        {selected.map((p) => (
          <button
            key={p}
            type="button"
            className="pressable rounded-tape"
            onClick={() => onChange(selected.filter((x) => x !== p))}
            aria-label={`${p} を外す`}
          >
            <Tape tone="wall" filled>
              {p.replace(/[都府県]$/, "")} ×
            </Tape>
          </button>
        ))}
      </div>

      {open ? (
        <>
          {/* モバイル: 下からのシート。≥640px: ボタン下のポップオーバー */}
          <div className="fixed inset-0 z-40 bg-rock/60 sm:hidden" aria-hidden="true" onClick={() => setOpen(false)} />
          <div
            id={panelId}
            role="dialog"
            aria-label="都道府県を選ぶ"
            className="fixed inset-x-0 bottom-0 z-50 flex max-h-[75vh] flex-col rounded-t-card border border-crack bg-joint sm:absolute sm:inset-auto sm:left-0 sm:top-[calc(100%+8px)] sm:w-[560px] sm:max-h-[70vh] sm:rounded-card"
          >
            <div className="flex items-center justify-between border-b border-crack px-4 py-3">
              <span className="text-eyebrow text-dust">PREFECTURE</span>
              <div className="flex items-center gap-1">
                {selected.length ? (
                  <Button variant="ghost" size="sm" className="px-2" onClick={() => onChange([])}>
                    クリア
                  </Button>
                ) : null}
                <Button variant="secondary" size="sm" onClick={() => setOpen(false)}>
                  閉じる
                </Button>
              </div>
            </div>
            <div className="overflow-y-auto px-4 py-3">
              {REGIONS.map((r) => (
                <fieldset key={r.name} className="mb-3 last:mb-0">
                  <legend className="mb-1.5 text-eyebrow text-[11px] text-ash">{r.name}</legend>
                  <div className="flex flex-wrap gap-x-1 gap-y-1">
                    {r.prefectures.map((p) => {
                      const on = selected.includes(p);
                      return (
                        <label
                          key={p}
                          className={`pressable inline-flex h-8 cursor-pointer select-none items-center gap-1.5 rounded-pill px-2.5 text-[13px] ${
                            on ? "bg-ledge text-chalk" : "text-dust hover:bg-ledge hover:text-chalk"
                          }`}
                        >
                          <input
                            type="checkbox"
                            className="h-3.5 w-3.5 accent-[var(--color-wall)]"
                            checked={on}
                            onChange={() => onChange(on ? selected.filter((x) => x !== p) : [...selected, p])}
                          />
                          {p}
                        </label>
                      );
                    })}
                  </div>
                </fieldset>
              ))}
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
}
