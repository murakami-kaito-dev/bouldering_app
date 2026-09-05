import { ImageResponse } from "next/og";
import type { Gym, GymType } from "@/lib/api/types";
import { getGym } from "@/lib/api/gyms";
import { GYM_TYPE_META } from "@/lib/gym/types";
import { parseGymId } from "@/components/gym/detail/gymId";

export const alt = "イワノボリタイ｜ボルダリングジム";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

/* DESIGN.md のトークン（satori は CSS 変数を解決しないので hex 直値） */
const C = {
  rock: "#15171B",
  joint: "#1E2126",
  crack: "#2D313A",
  chalk: "#F2F0EA",
  dust: "#9AA0AA",
  ash: "#5F6570",
  wall: "#5B8CFF",
  wallInk: "#0B1020",
  yellow: "#F5C542",
} as const;
const TYPE_HEX: Record<GymType, string> = { bouldering: "#FF7264", lead: "#3FCF8E", speed: "#3EC6E0" };

const WORDMARK = "イワノボリタイ";
const GENERIC_SUB = "全国のボルダリングジムを探す";
const LABEL_IKITAI = "イキタイ";
const LABEL_BOUL = "ボル活";

/**
 * 日本語グリフのため Noto Sans JP（700）を Google Fonts から、使う文字だけのサブセットで取る。
 * 古い UA を名乗ると TTF が返る（satori は woff2 不可）。失敗しても画像は出す（null）。
 */
async function loadJapaneseFont(text: string): Promise<ArrayBuffer | null> {
  try {
    const chars = [...new Set([...text, ...WORDMARK, ...GENERIC_SUB, ...LABEL_IKITAI, ...LABEL_BOUL, ..."0123456789,¥〜"])].join("");
    const cssUrl = `https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@700&text=${encodeURIComponent(chars)}`;
    const init = { next: { revalidate: 86400 } } as RequestInit & { next?: { revalidate?: number } };
    const css = await fetch(cssUrl, {
      ...init,
      headers: { "User-Agent": "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; de-at) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1" },
    }).then((r) => (r.ok ? r.text() : ""));
    const m = /src:\s*url\((.+?)\)\s*format\('(?:opentype|truetype)'\)/.exec(css);
    if (!m) return null;
    const res = await fetch(m[1], init);
    return res.ok ? res.arrayBuffer() : null;
  } catch {
    return null;
  }
}

function TypeTape({ type }: { type: GymType }) {
  return (
    <div
      style={{
        display: "flex",
        transform: "skewX(-8deg)",
        background: TYPE_HEX[type],
        color: C.wallInk,
        padding: "10px 22px",
        borderRadius: 2,
        fontSize: 26,
        fontWeight: 700,
        letterSpacing: 2,
      }}
    >
      <div style={{ display: "flex", transform: "skewX(8deg)" }}>{GYM_TYPE_META[type].label}</div>
    </div>
  );
}

function Count({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 6 }}>
      <div style={{ display: "flex", fontSize: 20, color: C.dust, letterSpacing: 2 }}>{label}</div>
      <div style={{ display: "flex", fontSize: 64, fontWeight: 700, lineHeight: 0.95, color }}>{value.toLocaleString("ja-JP")}</div>
    </div>
  );
}

function nameFontSize(name: string): number {
  const n = name.length;
  if (n <= 10) return 88;
  if (n <= 16) return 72;
  if (n <= 24) return 56;
  return 44;
}

function render(gym: Gym | null, font: ArrayBuffer | null) {
  const name = gym ? gym.name : WORDMARK;
  const sub = gym ? `${gym.prefecture}${gym.city}のボルダリングジム` : GENERIC_SUB;
  const family = font ? "NotoSansJP" : "sans-serif";

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
          fontFamily: family,
        }}
      >
        {/* 上: 種別テープ */}
        <div style={{ display: "flex", gap: 14, minHeight: 52 }}>
          {gym ? gym.types.map((t) => <TypeTape key={t} type={t} />) : null}
        </div>

        {/* 中: ジム名・所在地 */}
        <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
          <div style={{ display: "flex", fontSize: nameFontSize(name), fontWeight: 700, lineHeight: 1.15, letterSpacing: -1, maxWidth: 1056 }}>{name}</div>
          <div style={{ display: "flex", fontSize: 30, color: C.dust }}>{sub}</div>
        </div>

        {/* 下: 左にワードマーク、右に数字 */}
        <div style={{ display: "flex", alignItems: "flex-end", justifyContent: "space-between", borderTop: `1px solid ${C.crack}`, paddingTop: 28 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <div
              style={{
                display: "flex",
                transform: "skewX(-8deg)",
                background: C.wall,
                color: C.wallInk,
                padding: "6px 12px",
                borderRadius: 2,
                fontSize: 22,
                fontWeight: 700,
                letterSpacing: 2,
              }}
            >
              <div style={{ display: "flex", transform: "skewX(8deg)" }}>IWA</div>
            </div>
            <div style={{ display: "flex", fontSize: 32, fontWeight: 700 }}>{WORDMARK}</div>
          </div>
          {gym ? (
            <div style={{ display: "flex", gap: 48 }}>
              <Count label={LABEL_IKITAI} value={gym.ikitaiCount} color={C.yellow} />
              <Count label={LABEL_BOUL} value={gym.boulCount} color={C.chalk} />
            </div>
          ) : (
            <div style={{ display: "flex", fontSize: 20, color: C.ash, letterSpacing: 3 }}>ROCK & CHALK</div>
          )}
        </div>
      </div>
    ),
    {
      ...size,
      fonts: font ? [{ name: "NotoSansJP", data: font, weight: 700, style: "normal" }] : [],
    },
  );
}

/** ジムが無い・取得に失敗しても投げず、汎用画像を返す */
export default async function Image({ params }: { params: Promise<{ id: string }> }) {
  let gym: Gym | null = null;
  try {
    const { id } = await params;
    const n = parseGymId(id);
    gym = n === null ? null : await getGym(n);
  } catch (e) {
    console.error("[gyms/[id]/opengraph-image] getGym failed:", e);
    gym = null;
  }
  const font = await loadJapaneseFont(gym ? `${gym.name}${gym.prefecture}${gym.city}のボルダリングジム${gym.types.map((t) => GYM_TYPE_META[t].label).join("")}` : "");
  return render(gym, font);
}
