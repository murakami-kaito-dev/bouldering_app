"use client";

import Image from "next/image";
import { useCallback, useEffect, useRef, useState } from "react";
import type { GymPhoto, GymPhotosResponse } from "@/lib/api/types";

/** Google Places 由来の写真に必須の投稿者クレジット（Google の利用規約） */
function uniqueAuthors(photos: GymPhoto[]): Array<{ name: string; uri: string | null }> {
  const seen = new Map<string, string | null>();
  for (const p of photos) {
    if (p.authorName && !seen.has(p.authorName)) seen.set(p.authorName, p.authorUri);
  }
  return [...seen.entries()].map(([name, uri]) => ({ name, uri }));
}

function AuthorLink({ name, uri, className = "" }: { name: string; uri: string | null; className?: string }) {
  if (!uri) return <span className={className}>{name}</span>;
  return (
    <a href={uri} target="_blank" rel="noopener noreferrer" className={`rounded-tape underline underline-offset-4 hover:text-dust ${className}`}>
      {name}
    </a>
  );
}

function GoogleCredit({ photos }: { photos: GymPhoto[] }) {
  const authors = uniqueAuthors(photos);
  return (
    <p className="text-small text-ash">
      写真: Google マップ
      {authors.length > 0 ? (
        <>
          {" · 提供 "}
          {authors.map((a, i) => (
            <span key={a.name}>
              {i > 0 ? "、" : null}
              <AuthorLink name={a.name} uri={a.uri} />
            </span>
          ))}
        </>
      ) : null}
    </p>
  );
}

/** 写真が無いときの岩肌プレースホルダ（ジム名の頭文字を Barlow で） */
function PhotoPlaceholder({ gymName }: { gymName: string }) {
  const initial = (gymName.trim().charAt(0) || "?").toUpperCase();
  return (
    <div className="flex flex-col gap-2">
      <div className="grain relative flex aspect-[4/3] w-full max-w-[320px] items-center justify-center overflow-hidden rounded-card bg-joint" aria-hidden="true">
        <span className="font-numeric text-[112px] font-bold leading-none text-ash">{initial}</span>
        <span className="absolute bottom-3 right-4 text-eyebrow text-ash">NO PHOTO</span>
      </div>
      <p className="text-small text-ash">写真はまだありません</p>
    </div>
  );
}

const IconChevron = ({ dir }: { dir: "left" | "right" }) => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    {dir === "left" ? <path d="m15 6-6 6 6 6" /> : <path d="m9 6 6 6-6 6" />}
  </svg>
);

const IconClose = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
    <path d="M6 6l12 12M18 6 6 18" />
  </svg>
);

const navButton =
  "pressable inline-flex h-11 w-11 items-center justify-center rounded-pill border border-crack bg-joint text-chalk hover:bg-ledge disabled:opacity-40 disabled:pointer-events-none focus-visible:rounded-pill";

/**
 * 写真の横スクロール（scroll-snap）＋ライトボックス（<dialog>。Esc／←→ 対応）。
 * Places 由来のときはストリップの下に投稿者クレジットを出す。
 */
export function PhotoStrip({ gymName, photos }: { gymName: string; photos: GymPhotosResponse }) {
  const list = photos.photos;
  const [index, setIndex] = useState<number | null>(null);
  const dialogRef = useRef<HTMLDialogElement>(null);
  const openerRef = useRef<HTMLElement | null>(null);

  const open = useCallback((i: number, opener: HTMLElement) => {
    openerRef.current = opener;
    setIndex(i);
  }, []);
  const close = useCallback(() => setIndex(null), []);
  const step = useCallback(
    (delta: number) => {
      setIndex((cur) => (cur === null ? cur : (cur + delta + list.length) % list.length));
    },
    [list.length],
  );

  // dialog の開閉を state に追従させる（showModal でフォーカストラップと Esc を得る）
  useEffect(() => {
    const d = dialogRef.current;
    if (!d) return;
    if (index !== null && !d.open) d.showModal();
    if (index === null && d.open) {
      d.close();
      openerRef.current?.focus();
    }
  }, [index]);

  useEffect(() => {
    if (index === null) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "ArrowRight") step(1);
      else if (e.key === "ArrowLeft") step(-1);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [index, step]);

  if (list.length === 0) return <PhotoPlaceholder gymName={gymName} />;

  const current = index === null ? null : list[index];

  return (
    <section aria-label={`${gymName} の写真`} className="flex flex-col gap-2">
      <ul className="-mx-5 flex snap-x snap-mandatory gap-3 overflow-x-auto px-5 pb-1 md:-mx-8 md:px-8 lg:mx-0 lg:px-0">
        {list.map((p, i) => (
          <li key={p.url} className="w-[78%] shrink-0 snap-start md:w-[320px]">
            <button
              type="button"
              onClick={(e) => open(i, e.currentTarget)}
              className="pressable relative block aspect-[4/3] w-full overflow-hidden rounded-card bg-ledge focus-visible:rounded-card"
              aria-label={`${gymName} の写真 ${i + 1}／${list.length} を拡大`}
            >
              <Image
                src={p.url}
                alt={`${gymName} の写真 ${i + 1}`}
                fill
                sizes="(min-width: 768px) 320px, 80vw"
                className="object-cover"
                priority={i === 0}
              />
            </button>
          </li>
        ))}
      </ul>
      {photos.source === "google" ? <GoogleCredit photos={list} /> : null}

      <dialog
        ref={dialogRef}
        onClose={close}
        onClick={(e) => {
          if (e.target === e.currentTarget) close();
        }}
        aria-label={`${gymName} の写真を拡大表示`}
        className="m-auto h-[min(92vh,900px)] w-[min(96vw,1200px)] max-h-none max-w-none border-0 bg-transparent p-0 text-chalk backdrop:bg-rock/90"
      >
        {current ? (
          <div className="flex h-full w-full flex-col gap-3">
            <div className="flex items-center justify-between gap-3">
              <span className="font-numeric text-[18px] font-semibold tracking-[0.04em] text-dust" aria-live="polite">
                {(index ?? 0) + 1} / {list.length}
              </span>
              <button type="button" onClick={close} className={navButton} aria-label="閉じる">
                <IconClose />
              </button>
            </div>
            <div className="relative min-h-0 flex-1 overflow-hidden rounded-card bg-joint">
              <Image key={current.url} src={current.url} alt={`${gymName} の写真 ${(index ?? 0) + 1}`} fill sizes="100vw" className="object-contain" />
            </div>
            <div className="flex items-center justify-between gap-3">
              <button type="button" onClick={() => step(-1)} className={navButton} aria-label="前の写真" disabled={list.length < 2}>
                <IconChevron dir="left" />
              </button>
              {photos.source === "google" && current.authorName ? (
                <p className="min-w-0 truncate text-small text-ash">
                  写真: Google マップ · 提供 <AuthorLink name={current.authorName} uri={current.authorUri} />
                </p>
              ) : (
                <span />
              )}
              <button type="button" onClick={() => step(1)} className={navButton} aria-label="次の写真" disabled={list.length < 2}>
                <IconChevron dir="right" />
              </button>
            </div>
          </div>
        ) : null}
      </dialog>
    </section>
  );
}
