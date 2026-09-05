"use client";

import { useMemo, useState } from "react";
import { isOpenNow } from "@/lib/gym/hours";
import type { GymSummary } from "@/lib/gym/search";
import { GymList } from "./GymList";
import { GymMap } from "./GymMap";
import { useNow } from "./useNow";

/**
 * 都道府県ページの「一覧（市区町村ごと）｜地図」。静的生成されるので営業状態は mount 後に付ける。
 */
export function AreaExplorer({ gyms, prefecture }: { gyms: GymSummary[]; prefecture: string }) {
  const now = useNow(null);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [hoveredId, setHoveredId] = useState<number | null>(null);

  const openIds = useMemo(() => (now ? new Set(gyms.filter((g) => isOpenNow(g.hours, now)).map((g) => g.id)) : null), [gyms, now]);

  return (
    <div className="lg:grid lg:grid-cols-[minmax(0,1fr)_400px] lg:gap-8">
      <section aria-label={`${prefecture}のジム一覧`}>
        <GymList gyms={gyms} openIds={openIds} selectedId={selectedId} hoveredId={hoveredId} onHover={setHoveredId} groupByCityHeaders />
      </section>
      <aside className="mt-8 lg:mt-0" aria-label={`${prefecture}の地図`}>
        <div className="lg:sticky lg:top-[80px]">
          <GymMap id="area-map" className="h-[320px] lg:h-[calc(100vh-64px-32px)] lg:max-h-[640px]" gyms={gyms} selectedId={selectedId} hoveredId={hoveredId} onSelect={setSelectedId} openIds={openIds} />
        </div>
      </aside>
    </div>
  );
}
