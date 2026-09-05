"use client";

import { Suspense, useCallback, useId, type KeyboardEvent, type ReactNode } from "react";
import { useSearchParams } from "next/navigation";

export type GymTab = "info" | "boul-log";

const TABS: Array<{ id: GymTab; label: string }> = [
  { id: "info", label: "施設情報" },
  { id: "boul-log", label: "ボル活" },
];

interface TabsContent {
  info: ReactNode;
  boulLog: ReactNode;
  /** ボル活タブに添える件数 */
  boulCount?: number;
}

function TabsView({ active, onSelect, info, boulLog, boulCount }: TabsContent & { active: GymTab; onSelect?: (t: GymTab) => void }) {
  const base = useId();
  const tabId = (t: GymTab) => `${base}-tab-${t}`;
  const panelId = (t: GymTab) => `${base}-panel-${t}`;

  const onKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    if (e.key !== "ArrowRight" && e.key !== "ArrowLeft") return;
    e.preventDefault();
    const i = TABS.findIndex((t) => t.id === active);
    const next = TABS[(i + (e.key === "ArrowRight" ? 1 : -1) + TABS.length) % TABS.length].id;
    onSelect?.(next);
    document.getElementById(tabId(next))?.focus();
  };

  return (
    <div className="flex flex-col gap-6">
      <div role="tablist" aria-label="ジムの情報" className="flex gap-2 border-b border-crack pb-4" onKeyDown={onKeyDown}>
        {TABS.map((t) => {
          const selected = t.id === active;
          return (
            <button
              key={t.id}
              type="button"
              role="tab"
              id={tabId(t.id)}
              aria-selected={selected}
              aria-controls={panelId(t.id)}
              tabIndex={selected ? 0 : -1}
              onClick={() => onSelect?.(t.id)}
              className="tape pressable focus-visible:rounded-tape"
              style={{
                padding: "9px 18px",
                fontSize: 14,
                background: selected ? "var(--color-wall)" : "color-mix(in srgb, var(--color-dust) 12%, transparent)",
                color: selected ? "var(--color-wall-ink)" : "var(--color-dust)",
              }}
            >
              <span className="inline-flex items-baseline gap-2">
                {t.label}
                {t.id === "boul-log" && boulCount !== undefined ? <span className="font-numeric text-[13px]">{boulCount.toLocaleString("ja-JP")}</span> : null}
              </span>
            </button>
          );
        })}
      </div>
      <div role="tabpanel" id={panelId("info")} aria-labelledby={tabId("info")} hidden={active !== "info"} tabIndex={0} className="focus-visible:rounded-card">
        {info}
      </div>
      <div role="tabpanel" id={panelId("boul-log")} aria-labelledby={tabId("boul-log")} hidden={active !== "boul-log"} tabIndex={0} className="focus-visible:rounded-card">
        {boulLog}
      </div>
    </div>
  );
}

function UrlSyncedTabs(props: TabsContent) {
  const sp = useSearchParams();
  const active: GymTab = sp.get("tab") === "boul-log" ? "boul-log" : "info";

  // 同じページ内の状態なので RSC を取り直さず、history だけ書き換える（Next が useSearchParams に同期する）
  const select = useCallback((t: GymTab) => {
    const url = new URL(window.location.href);
    if (t === "info") url.searchParams.delete("tab");
    else url.searchParams.set("tab", t);
    window.history.replaceState(null, "", url.toString());
  }, []);

  return <TabsView active={active} onSelect={select} {...props} />;
}

/**
 * 施設情報｜ボル活 のタブ。`?tab=info|boul-log` と同期（既定 info）。
 * 静的描画時は useSearchParams が Suspense を要するため、既定タブと同じ見た目をフォールバックにする。
 */
export function GymTabs(props: TabsContent) {
  return (
    <Suspense fallback={<TabsView active="info" {...props} />}>
      <UrlSyncedTabs {...props} />
    </Suspense>
  );
}
