import { ImageResponse } from "next/og";
import { ogFonts } from "@/components/home/ogFonts";

/**
 * サイト既定の OG 画像（1200×630）。
 * 岩肌（rock）の上に、テープ付きワードマーク・タグライン・種別チップ 3 本。
 * フォントは同梱のサブセット（ogFonts.ts）だけを使い、ネットワークに依存しない。
 * ここで使う文字を増やしたら ogFonts.ts を再生成すること。
 */
export const alt = "イワノボリタイ — 全国のボルダリングジム検索・ボル活記録";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

const C = {
  rock: "#15171B",
  joint: "#1E2126",
  crack: "#2D313A",
  chalk: "#F2F0EA",
  dust: "#9AA0AA",
  wall: "#5B8CFF",
  wallInk: "#0B1020",
  red: "#FF7264",
  green: "#3FCF8E",
  cyan: "#3EC6E0",
} as const;

const CHIPS: Array<{ label: string; color: string; bg: string }> = [
  { label: "BOULDER", color: C.red, bg: "rgba(255,114,100,0.16)" },
  { label: "LEAD", color: C.green, bg: "rgba(63,207,142,0.16)" },
  { label: "SPEED", color: C.cyan, bg: "rgba(62,198,224,0.16)" },
];

export default function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: "64px 72px",
          background: C.rock,
          color: C.chalk,
          fontFamily: "ZenKaku",
          position: "relative",
        }}
      >
        {/* 岩肌: 右側の節理面と、割れ目の線 */}
        <div style={{ position: "absolute", top: 0, right: 0, width: 360, height: 630, background: C.joint, display: "flex" }} />
        <div style={{ position: "absolute", top: 0, left: 840, width: 2, height: 630, background: C.crack, display: "flex" }} />
        <div style={{ position: "absolute", top: 420, left: 840, width: 360, height: 2, background: C.crack, display: "flex" }} />
        {/* 壁ブルーのテープ（右上） */}
        <div
          style={{
            position: "absolute",
            top: 84,
            left: 900,
            width: 220,
            height: 14,
            background: C.wall,
            transform: "skewX(-8deg)",
            display: "flex",
          }}
        />

        {/* 上段: アイブロウ */}
        <div style={{ display: "flex", fontFamily: "Barlow", fontSize: 26, letterSpacing: 4, color: C.dust }}>JAPAN · BOULDERING GYMS</div>

        {/* 中段: ワードマーク＋タグライン */}
        <div style={{ display: "flex", flexDirection: "column", gap: 28, width: 760 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 22 }}>
            <div
              style={{
                display: "flex",
                padding: "10px 16px",
                background: C.wall,
                color: C.wallInk,
                fontFamily: "Barlow",
                fontSize: 30,
                letterSpacing: 3,
                transform: "skewX(-8deg)",
                borderRadius: 3,
              }}
            >
              <span style={{ transform: "skewX(8deg)" }}>IWA</span>
            </div>
            <div style={{ display: "flex", fontSize: 92, fontWeight: 700, letterSpacing: -2, lineHeight: 1 }}>イワノボリタイ</div>
          </div>
          <div style={{ display: "flex", fontSize: 46, fontWeight: 700, letterSpacing: -1, lineHeight: 1.2 }}>今日登るジムを、地図と条件で。</div>
          <div style={{ display: "flex", fontSize: 26, color: C.dust, lineHeight: 1.4 }}>全国のボルダリング・クライミングジム検索とボル活記録</div>
        </div>

        {/* 下段: 種別チップ */}
        <div style={{ display: "flex", gap: 16 }}>
          {CHIPS.map((c) => (
            <div
              key={c.label}
              style={{
                display: "flex",
                padding: "12px 26px",
                background: c.bg,
                color: c.color,
                fontFamily: "Barlow",
                fontSize: 30,
                letterSpacing: 3,
                transform: "skewX(-8deg)",
                borderRadius: 3,
              }}
            >
              <span style={{ transform: "skewX(8deg)" }}>{c.label}</span>
            </div>
          ))}
        </div>
      </div>
    ),
    { ...size, fonts: ogFonts() },
  );
}
