import type { ReactNode } from "react";

/** ページ幅（1200px）と左右の余白 */
export function Container({ children, className = "", narrow = false }: { children: ReactNode; className?: string; narrow?: boolean }) {
  return <div className={`mx-auto w-full ${narrow ? "max-w-[720px]" : "max-w-[1200px]"} px-5 md:px-8 ${className}`}>{children}</div>;
}

/** 英字のアイブロウ（Barlow 600 12px uppercase） */
export function Eyebrow({ children, className = "" }: { children: ReactNode; className?: string }) {
  return <div className={`text-eyebrow text-dust ${className}`}>{children}</div>;
}

/** セクション見出し: アイブロウ → 見出し → テープ線 */
export function SectionHeader({
  eyebrow,
  title,
  aside,
  className = "",
}: {
  eyebrow?: ReactNode;
  title: ReactNode;
  aside?: ReactNode;
  className?: string;
}) {
  return (
    <div className={`flex items-end justify-between gap-4 ${className}`}>
      <div className="flex flex-col gap-2">
        {eyebrow ? <Eyebrow>{eyebrow}</Eyebrow> : null}
        <h2 className="text-h2">{title}</h2>
        <span className="tape-rule mt-1" aria-hidden="true" />
      </div>
      {aside ? <div className="shrink-0">{aside}</div> : null}
    </div>
  );
}

/** 課題ボードの数字（イキタイ・ボル活・料金） */
export function Stat({
  label,
  value,
  unit,
  tone = "chalk",
  size = "md",
  className = "",
}: {
  label: ReactNode;
  value: ReactNode;
  unit?: ReactNode;
  tone?: "chalk" | "yellow" | "wall" | "dust";
  size?: "sm" | "md" | "lg";
  className?: string;
}) {
  const color =
    tone === "yellow" ? "text-tape-yellow" : tone === "wall" ? "text-wall" : tone === "dust" ? "text-dust" : "text-chalk";
  const fs = size === "lg" ? "text-[64px] md:text-[72px]" : size === "md" ? "text-[40px] md:text-[48px]" : "text-[22px]";
  return (
    <div className={`flex flex-col gap-1 ${className}`}>
      <Eyebrow>{label}</Eyebrow>
      <div className={`text-stat ${color} ${fs} flex items-baseline gap-[0.35em]`}>
        <span>{value}</span>
        {unit ? <span className="text-[0.4em] font-semibold text-dust tracking-[0.04em]">{unit}</span> : null}
      </div>
    </div>
  );
}

/** 面（joint）のカード */
export function Panel({ children, className = "", as: Tag = "div" }: { children: ReactNode; className?: string; as?: "div" | "section" | "article" | "aside" }) {
  return <Tag className={`bg-joint rounded-card border border-transparent ${className}`}>{children}</Tag>;
}

/** 骨組み（読込中）。層は ledge、テープ状に角丸 2px */
export function Skeleton({ className = "" }: { className?: string }) {
  return <div className={`animate-pulse bg-ledge rounded-tape ${className}`} aria-hidden="true" />;
}
