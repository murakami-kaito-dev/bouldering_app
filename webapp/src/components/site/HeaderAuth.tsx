"use client";

import Link from "next/link";

/**
 * ヘッダー右端のログイン／マイページ。
 * 認証チーム（Phase B）が useAuth() に差し替える。差し替え前は「ログイン」リンクのみ（仮置き）。
 */
export function HeaderAuth() {
  return (
    <Link
      href="/login"
      className="pressable ml-1 inline-flex h-9 items-center rounded-pill border border-crack px-4 text-[13px] font-bold text-chalk hover:bg-ledge md:ml-2"
    >
      ログイン
    </Link>
  );
}
