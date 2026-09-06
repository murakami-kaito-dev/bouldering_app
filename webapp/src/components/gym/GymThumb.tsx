"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";
import type { GymPhotosResponse } from "@/lib/api/types";

interface Thumb {
  url: string | null;
  source: GymPhotosResponse["source"];
}

/**
 * 一覧カード用のサムネイル取得。ジム ID ごとに 1 回だけ取りに行き、結果（無しも含む）をモジュール内に保持する。
 * - 画面に入りそうになったカードだけ取得（IntersectionObserver）＝ 430 件を一度に叩かない
 * - 取得先は BFF `/api/gyms/[id]/photos?limit=1`（サーバー側で 1 日キャッシュ。Places API の課金を抑える）
 */
const cache = new Map<number, Promise<Thumb>>();

function loadThumb(gymId: number): Promise<Thumb> {
  const hit = cache.get(gymId);
  if (hit) return hit;
  const p = fetch(`/api/gyms/${gymId}/photos?limit=1`, { headers: { Accept: "application/json" } })
    .then(async (res) => {
      if (!res.ok) return { url: null, source: "none" as const };
      const data = (await res.json()) as GymPhotosResponse;
      return { url: data.photos[0]?.url ?? null, source: data.source };
    })
    .catch((): Thumb => ({ url: null, source: "none" }));
  cache.set(gymId, p);
  return p;
}

/**
 * ジムの写真サムネイル（DESIGN.md「GymCard」の左 96×96）。
 * 写真が無い／読込前は岩肌の面のまま（レイアウトは動かない）。
 * Google Places 由来の写真には「Google」の小さな表示を付ける（Places API の利用規約で出典表示が必須）。
 */
export function GymThumb({ gymId, name, className = "", sizes = "96px" }: { gymId: number; name: string; className?: string; sizes?: string }) {
  const ref = useRef<HTMLDivElement>(null);
  const [thumb, setThumb] = useState<Thumb | null>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    let cancelled = false;
    const start = () => {
      loadThumb(gymId).then((t) => {
        if (!cancelled) setThumb(t);
      });
    };
    if (typeof IntersectionObserver === "undefined") {
      start();
      return () => {
        cancelled = true;
      };
    }
    const io = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) {
          io.disconnect();
          start();
        }
      },
      { rootMargin: "200px 0px" },
    );
    io.observe(el);
    return () => {
      cancelled = true;
      io.disconnect();
    };
  }, [gymId]);

  return (
    <div ref={ref} className={`grain relative shrink-0 overflow-hidden rounded-card bg-rock ${className}`} role="img" aria-label={`${name} の写真`}>
      {thumb?.url ? <Image src={thumb.url} alt={name} fill sizes={sizes} className="object-cover" /> : null}
      {thumb?.url && thumb.source === "google" ? (
        <span className="absolute bottom-1 right-1 rounded-tape bg-rock/75 px-1.5 py-0.5 text-[9px] font-medium leading-none text-chalk" aria-label="写真: Google マップ">
          Google
        </span>
      ) : null}
    </div>
  );
}
