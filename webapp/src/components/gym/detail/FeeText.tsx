import type { ElementType } from "react";

/**
 * 料金・レンタルの全文（改行区切り）を、数字だけ Barlow Condensed（tnum）で描く。
 * `1,800円` のような数字列を span で包み、それ以外は本文書体のまま。
 */
export function FeeText({ text, as: Tag = "p", className = "" }: { text: string; as?: ElementType; className?: string }) {
  const parts = text.split(/(\d[\d,]*)/g);
  return (
    <Tag className={`whitespace-pre-wrap break-words text-[15px] leading-[1.8] text-chalk ${className}`}>
      {parts.map((p, i) =>
        i % 2 === 1 ? (
          <span key={i} className="font-numeric text-[1.15em] font-semibold tracking-[0.02em]">
            {p}
          </span>
        ) : (
          p
        ),
      )}
    </Tag>
  );
}
