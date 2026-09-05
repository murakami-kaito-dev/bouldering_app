"use client";

import { Fragment, useEffect, useRef } from "react";
import type { GeoPoint, GymSummary } from "@/lib/gym/search";
import { groupByCity } from "@/lib/gym/search";
import { distanceKm } from "@/lib/gym/types";
import { AdSlot } from "@/components/ads/AdSlot";
import { Button } from "@/components/ui/Button";
import { Eyebrow } from "@/components/ui/Primitives";
import { GymCard } from "./GymCard";

const AD_EVERY = 8;

export interface GymListProps {
  gyms: GymSummary[];
  /** 営業中のジム id。null なら OPEN/CLOSE を出さない */
  openIds: Set<number> | null;
  selectedId: number | null;
  hoveredId?: number | null;
  onHover?: (id: number | null) => void;
  /** 現在地（あれば距離を出す） */
  origin?: GeoPoint | null;
  /** 8 件ごとに in-feed 広告 */
  ads?: boolean;
  /** 市区町村ごとに小見出しを付ける（地域順に並んでいる前提） */
  groupByCityHeaders?: boolean;
  /** 空状態の「条件をすべて解除」 */
  onClearFilters?: () => void;
  className?: string;
}

/**
 * GymCard の縦並び。選択（地図のマーカー）が変わったらそのカードへスクロールする。
 */
export function GymList({
  gyms,
  openIds,
  selectedId,
  hoveredId = null,
  onHover,
  origin = null,
  ads = false,
  groupByCityHeaders = false,
  onClearFilters,
  className = "",
}: GymListProps) {
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (selectedId === null || !rootRef.current) return;
    const el = rootRef.current.querySelector<HTMLElement>(`[data-gym-id="${selectedId}"]`);
    if (!el) return;
    const r = el.getBoundingClientRect();
    const headerH = 64;
    const visible = r.top >= headerH && r.bottom <= window.innerHeight;
    if (!visible) el.scrollIntoView({ block: "center", behavior: "smooth" });
  }, [selectedId]);

  if (gyms.length === 0) {
    return (
      <div ref={rootRef} className={`flex flex-col items-start gap-4 rounded-card border border-dashed border-crack bg-joint p-6 ${className}`}>
        <Eyebrow>NO RESULTS</Eyebrow>
        <p className="text-body text-dust">この条件のジムはまだありません。都道府県や種別を広げてみてください。</p>
        {onClearFilters ? (
          <Button variant="secondary" size="sm" onClick={onClearFilters}>
            条件をすべて解除
          </Button>
        ) : null}
      </div>
    );
  }

  const card = (g: GymSummary) => (
    <GymCard
      key={g.id}
      gym={g}
      open={openIds ? openIds.has(g.id) : null}
      selected={g.id === selectedId}
      highlighted={g.id === hoveredId}
      distanceKm={origin ? distanceKm(origin.lat, origin.lng, g.lat, g.lng) : null}
      onHover={onHover}
    />
  );

  if (groupByCityHeaders) {
    return (
      <div ref={rootRef} className={`flex flex-col gap-3 ${className}`}>
        {groupByCity(gyms).map((grp) => (
          <section key={grp.city} className="flex flex-col gap-3" aria-label={grp.city}>
            <Eyebrow className="mt-3 flex items-center gap-2 first:mt-0">
              <span className="text-chalk">{grp.city}</span>
              <span className="text-ash">{grp.gyms.length}</span>
            </Eyebrow>
            {grp.gyms.map(card)}
          </section>
        ))}
      </div>
    );
  }

  return (
    <div ref={rootRef} className={`flex flex-col gap-3 ${className}`}>
      {gyms.map((g, i) => (
        <Fragment key={g.id}>
          {card(g)}
          {ads && (i + 1) % AD_EVERY === 0 && i + 1 < gyms.length ? <AdSlot format="infeed" /> : null}
        </Fragment>
      ))}
    </div>
  );
}
