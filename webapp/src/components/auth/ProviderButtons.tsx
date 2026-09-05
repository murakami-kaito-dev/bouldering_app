"use client";

import type { ReactNode } from "react";

/** Google の "G"（4 色。ブランドガイドに従い色は固定） */
export function GoogleMark({ size = 18 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 18 18" aria-hidden="true">
      <path fill="#4285F4" d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.92c1.7-1.57 2.68-3.88 2.68-6.62z" />
      <path fill="#34A853" d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.92-2.26c-.8.54-1.84.86-3.04.86-2.34 0-4.32-1.58-5.03-3.7H.96v2.33A9 9 0 0 0 9 18z" />
      <path fill="#FBBC05" d="M3.97 10.72A5.4 5.4 0 0 1 3.68 9c0-.6.1-1.18.29-1.72V4.95H.96A9 9 0 0 0 0 9c0 1.45.35 2.83.96 4.05l3.01-2.33z" />
      <path fill="#EA4335" d="M9 3.58c1.32 0 2.5.45 3.44 1.35l2.58-2.58C13.46.9 11.43 0 9 0A9 9 0 0 0 .96 4.95l3.01 2.33C4.68 5.16 6.66 3.58 9 3.58z" />
    </svg>
  );
}

/** Apple マーク（AppCta と同じパス） */
export function AppleMark({ size = 18 }: { size?: number }) {
  return (
    <svg width={size} height={Math.round(size * 1.22)} viewBox="0 0 18 22" aria-hidden="true" fill="currentColor">
      <path d="M14.9 11.6c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9-.7 0-1.8-.8-3-.8-1.5 0-3 .9-3.8 2.3-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.7 2.4 2.9 2.4 1.2 0 1.6-.8 3-.8s1.8.8 3 .7c1.3 0 2-1.1 2.8-2.3.9-1.3 1.2-2.6 1.3-2.6-.1 0-2.5-.9-2.5-3.8zM12.6 4.8c.6-.8 1.1-1.9.9-3-.9 0-2 .6-2.7 1.4-.6.7-1.1 1.8-1 2.9 1.1.1 2.1-.5 2.8-1.3z" />
    </svg>
  );
}

const base =
  "pressable inline-flex h-12 w-full items-center justify-center gap-3 rounded-pill font-display text-[15px] font-bold disabled:opacity-50 disabled:pointer-events-none";

/** Google: 白っぽい二次ボタン（チョーク地に墨文字は Apple 用に取っておく） */
export function GoogleButton({ onClick, disabled, children }: { onClick: () => void; disabled?: boolean; children?: ReactNode }) {
  return (
    <button type="button" onClick={onClick} disabled={disabled} className={`${base} border border-crack bg-ledge text-chalk hover:border-dust`}>
      <GoogleMark />
      <span>{children ?? "Google でログイン"}</span>
    </button>
  );
}

/** Apple: チョーク塗りに墨文字 */
export function AppleButton({ onClick, disabled, children }: { onClick: () => void; disabled?: boolean; children?: ReactNode }) {
  return (
    <button type="button" onClick={onClick} disabled={disabled} className={`${base} bg-chalk text-wall-ink hover:bg-chalk/90`}>
      <AppleMark />
      <span>{children ?? "Apple でログイン"}</span>
    </button>
  );
}
