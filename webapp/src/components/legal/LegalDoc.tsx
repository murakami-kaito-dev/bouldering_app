import Link from "next/link";
import type { LegalDoc as LegalDocData } from "@/lib/legal";
import { formatUpdated } from "@/lib/legal";
import { env } from "@/lib/env";
import "./legal.css";

/**
 * 規約ページ（利用規約／プライバシーポリシー）の本体。
 * GitHub Pages 版（iwanoboritai-legal）と同じ「明るい文書」スタイルを、ダークなサイトの上に紙として置く。
 * 構造: 題名 → 最終更新日 → 要点 → 目次（本文に含まれる）→ 条文 → 改訂履歴 → 関連ページ
 */
export function LegalDoc({ doc }: { doc: LegalDocData }) {
  const other = doc.slug === "terms" ? { href: "/privacy", title: "プライバシーポリシー", sub: "取得する情報・利用目的・Cookie と広告・保存期間など" } : { href: "/terms", title: "利用規約", sub: "アカウント・投稿の公開範囲・禁止事項・退会など" };
  return (
    <div className="legal">
      <div className="legal-wrap">
        <article className="legal-paper doc">
          <p className="legal-site">イワノボリタイ</p>
          <h1>{doc.title}</h1>
          {doc.updated ? (
            <p className="meta">
              最終更新日：<time dateTime={doc.updated}>{formatUpdated(doc.updated)}</time>
            </p>
          ) : null}

          {doc.summary.length > 0 ? (
            <section className="note" aria-labelledby="summary-title">
              <strong id="summary-title">要点</strong>
              <ul>
                {doc.summary.map((item, i) => (
                  <li key={i} dangerouslySetInnerHTML={{ __html: item }} />
                ))}
              </ul>
              <p className="note-foot">本文を分かりやすくまとめたものです。正式な内容は各条文をご確認ください。</p>
            </section>
          ) : null}

          <div dangerouslySetInnerHTML={{ __html: doc.html }} />
        </article>

        <nav className="links" aria-label="関連ページ">
          <Link href={other.href}>
            {other.title}
            <span>{other.sub}</span>
          </Link>
          <a href={env.appStoreUrl} target="_blank" rel="noopener noreferrer">
            iOS アプリ<span>App Store で「イワノボリタイ」を開く</span>
          </a>
          <Link href="/gyms">
            ジムを探す<span>Web 版のトップへ戻る</span>
          </Link>
        </nav>
      </div>
    </div>
  );
}
