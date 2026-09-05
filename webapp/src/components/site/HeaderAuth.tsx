"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { useAuth } from "@/lib/auth";
import { Skeleton } from "@/components/ui/Primitives";
import { Avatar } from "@/components/tweet/TweetCard";

/**
 * ヘッダー右端のログイン／マイページ。
 * - loading   : 36px の丸い骨組み（レイアウトシフトを起こさない）
 * - signedOut : 「ログイン」ピル → /login
 * - signedIn  : アバター → 小さなメニュー（マイページ / 投稿する / ログアウト）
 */
export function HeaderAuth() {
  const { user, status, signOut } = useAuth();
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent | TouchEvent) => {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    document.addEventListener("mousedown", onDown);
    document.addEventListener("touchstart", onDown);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDown);
      document.removeEventListener("touchstart", onDown);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  if (status === "loading") {
    return (
      <span className="ml-1 inline-block h-9 w-9 overflow-hidden rounded-pill md:ml-2" aria-hidden="true">
        <Skeleton className="h-full w-full" />
      </span>
    );
  }

  if (status === "signedOut" || !user) {
    return (
      <Link
        href="/login"
        className="pressable ml-1 inline-flex h-9 shrink-0 items-center whitespace-nowrap rounded-pill border border-crack px-3 text-[13px] font-bold text-chalk hover:bg-ledge md:ml-2 md:px-4"
      >
        ログイン
      </Link>
    );
  }

  const name = user.displayName || "クライマー";

  return (
    <div ref={rootRef} className="relative ml-1 md:ml-2">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-label={`${name} のメニュー`}
        className="pressable flex h-9 w-9 items-center justify-center rounded-pill border border-crack hover:border-dust"
      >
        <Avatar src={user.photoURL} name={name} size={34} />
      </button>
      {open ? (
        <div
          role="menu"
          className="absolute right-0 top-[calc(100%+8px)] z-50 flex w-48 flex-col overflow-hidden rounded-card border border-crack bg-joint py-1"
        >
          <div className="truncate px-4 py-2 text-small text-dust">{name}</div>
          <MenuLink href="/me" onClick={() => setOpen(false)}>
            マイページ
          </MenuLink>
          <MenuLink href="/post" onClick={() => setOpen(false)}>
            投稿する
          </MenuLink>
          <button
            type="button"
            role="menuitem"
            onClick={async () => {
              setOpen(false);
              await signOut();
              router.push("/");
            }}
            className="px-4 py-2 text-left text-[14px] font-medium text-dust hover:bg-ledge hover:text-chalk"
          >
            ログアウト
          </button>
        </div>
      ) : null}
    </div>
  );
}

function MenuLink({ href, onClick, children }: { href: string; onClick: () => void; children: React.ReactNode }) {
  return (
    <Link href={href} role="menuitem" onClick={onClick} className="px-4 py-2 text-[14px] font-medium text-chalk hover:bg-ledge">
      {children}
    </Link>
  );
}
