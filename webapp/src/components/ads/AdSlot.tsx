"use client";

import { useEffect, useRef } from "react";
import { env } from "@/lib/env";

type Format = "rect" | "banner" | "infeed" | "auto";

const SIZE: Record<Format, { minH: string; label: string }> = {
  rect: { minH: "min-h-[250px]", label: "300×250" },
  banner: { minH: "min-h-[90px]", label: "728×90" },
  infeed: { minH: "min-h-[120px]", label: "in-feed" },
  auto: { minH: "min-h-[250px]", label: "responsive" },
};

declare global {
  interface Window {
    adsbygoogle?: unknown[];
  }
}

/**
 * AdSense の広告枠。
 * - NEXT_PUBLIC_ADSENSE_CLIENT が未設定（審査前・dev）のときは同じ寸法の空枠を出し、レイアウトシフトを起こさない。
 * - 設定後は <ins class="adsbygoogle"> を描画し、AdSenseScript（layout）が読み込んだ adsbygoogle に push する。
 * - `slot` は AdSense 管理画面で作る広告ユニットの ID。未指定なら自動広告に任せる。
 */
export function AdSlot({ format = "auto", slot, className = "" }: { format?: Format; slot?: string; className?: string }) {
  const ref = useRef<HTMLModElement>(null);
  const client = env.adsenseClient;

  useEffect(() => {
    if (!client || !ref.current) return;
    try {
      (window.adsbygoogle = window.adsbygoogle || []).push({});
    } catch {
      /* AdSense が未ロードでも画面は壊さない */
    }
  }, [client]);

  const { minH, label } = SIZE[format];

  if (!client) {
    return (
      <div
        className={`relative w-full ${minH} rounded-card border border-dashed border-crack bg-joint ${className}`}
        role="presentation"
        aria-hidden="true"
      >
        <span className="absolute right-3 top-2 text-eyebrow text-ash">AD · {label}</span>
      </div>
    );
  }

  return (
    <div className={`relative w-full ${minH} ${className}`}>
      <span className="absolute right-3 top-2 text-eyebrow text-ash">AD</span>
      <ins
        ref={ref}
        className="adsbygoogle block w-full"
        style={{ display: "block", minHeight: "inherit" }}
        data-ad-client={client}
        data-ad-slot={slot}
        data-ad-format={format === "rect" ? "rectangle" : format === "banner" ? "horizontal" : format === "infeed" ? "fluid" : "auto"}
        data-full-width-responsive="true"
      />
    </div>
  );
}
