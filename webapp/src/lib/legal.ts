import { readFile } from "node:fs/promises";
import path from "node:path";
import { marked } from "marked";

/**
 * 利用規約・プライバシーポリシーの本文（`content/legal/*.md`）。
 * 正典は別リポジトリ iwanoboritai-legal（GitHub Pages）と同じ Markdown で、Web 版はそれをそのまま同梱して描画する。
 * - front matter（title / updated / summary…）は最小の自前パーサで読む
 * - 見出しの kramdown 記法 `## 1. 適用 {#terms-1}` は id 付き見出しへ変換（条文へのリンクを両サイトで揃える）
 */
export type LegalSlug = "terms" | "privacy";

export interface LegalDoc {
  slug: LegalSlug;
  title: string;
  eyebrow: string;
  description: string;
  /** 'YYYY-MM-DD' */
  updated: string;
  /** 要点（HTML 断片） */
  summary: string[];
  /** 本文 HTML */
  html: string;
}

function parseFrontMatter(src: string): { meta: Record<string, string | string[]>; body: string } {
  const m = /^---\n([\s\S]*?)\n---\n([\s\S]*)$/.exec(src);
  if (!m) return { meta: {}, body: src };
  const meta: Record<string, string | string[]> = {};
  let key: string | null = null;
  for (const line of m[1].split("\n")) {
    const kv = /^([a-z_]+):\s*(.*)$/.exec(line);
    if (kv && !line.startsWith(" ")) {
      key = kv[1];
      const v = kv[2].trim();
      meta[key] = v === "" ? [] : v.replace(/^['"]|['"]$/g, "");
      continue;
    }
    const item = /^\s+-\s+(.*)$/.exec(line);
    if (item && key && Array.isArray(meta[key])) {
      let v = item[1].trim();
      if ((v.startsWith("'") && v.endsWith("'")) || (v.startsWith('"') && v.endsWith('"'))) v = v.slice(1, -1);
      (meta[key] as string[]).push(v);
    }
  }
  return { meta, body: m[2] };
}

/**
 * kramdown の見出し IAL `## 見出し {#id}` を id 付き見出しへ。
 * 前処理で生 HTML の <h2> にすると marked がその後の HTML ブロック扱いを誤り、続く箇条書きの Markdown が
 * 素のまま出る（実測）ため、見出しは Markdown のまま描画し、**出力 HTML 側**で `{#id}` を id 属性に置き換える。
 */
function applyHeadingIds(html: string): string {
  return html.replace(/<h([1-6])>([\s\S]*?)\s*\{#([\w-]+)\}\s*<\/h\1>/g, (_m, level: string, text: string, id: string) => `<h${level} id="${id}">${text}</h${level}>`);
}

const cache = new Map<LegalSlug, Promise<LegalDoc>>();

export function loadLegal(slug: LegalSlug): Promise<LegalDoc> {
  const hit = cache.get(slug);
  if (hit) return hit;
  const p = (async () => {
    const file = path.join(process.cwd(), "content", "legal", `${slug}.md`);
    const src = await readFile(file, "utf8");
    const { meta, body } = parseFrontMatter(src);
    const html = applyHeadingIds(await marked.parse(body, { gfm: true, breaks: false }));
    const str = (k: string) => (typeof meta[k] === "string" ? (meta[k] as string) : "");
    return {
      slug,
      title: str("title") || (slug === "terms" ? "利用規約" : "プライバシーポリシー"),
      eyebrow: str("eyebrow"),
      description: str("description"),
      updated: str("updated"),
      summary: Array.isArray(meta.summary) ? (meta.summary as string[]) : [],
      html,
    };
  })();
  cache.set(slug, p);
  return p;
}

export function formatUpdated(ymd: string): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(ymd);
  if (!m) return ymd;
  return `${m[1]}年${Number(m[2])}月${Number(m[3])}日`;
}
