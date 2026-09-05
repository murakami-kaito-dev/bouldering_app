"use client";

import { useEffect, useRef } from "react";

export const MAX_PHOTOS = 4;
export const MAX_PHOTO_BYTES = 10 * 1024 * 1024;
const ACCEPT_TYPES = new Set(["image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"]);

export interface PickedPhoto {
  id: string;
  file: File;
  /** ブラウザで表示できない HEIC などは null */
  previewUrl: string | null;
  contentType: string;
}

/** 拡張子から MIME を補う（iOS の HEIC は file.type が空になることがある） */
export function detectContentType(file: File): string | null {
  const t = (file.type || "").toLowerCase();
  if (ACCEPT_TYPES.has(t)) return t;
  const ext = file.name.toLowerCase().split(".").pop();
  if (ext === "jpg" || ext === "jpeg") return "image/jpeg";
  if (ext === "png") return "image/png";
  if (ext === "webp") return "image/webp";
  if (ext === "heic") return "image/heic";
  if (ext === "heif") return "image/heif";
  return null;
}

export function toPicked(file: File): PickedPhoto | { error: string } {
  const contentType = detectContentType(file);
  if (!contentType) return { error: `${file.name}: JPEG / PNG / WebP / HEIC のみ添付できます` };
  if (file.size > MAX_PHOTO_BYTES) return { error: `${file.name}: 1 枚 10MB までです` };
  const canPreview = contentType !== "image/heic" && contentType !== "image/heif";
  return {
    id: `${file.name}-${file.size}-${file.lastModified}-${Math.random().toString(36).slice(2, 8)}`,
    file,
    previewUrl: canPreview ? URL.createObjectURL(file) : null,
    contentType,
  };
}

/** 写真の選択・サムネイル・削除（最大 4 枚） */
export function PhotoPicker({
  photos,
  onAdd,
  onRemove,
  disabled = false,
}: {
  photos: PickedPhoto[];
  onAdd: (files: FileList) => void;
  onRemove: (id: string) => void;
  disabled?: boolean;
}) {
  const inputRef = useRef<HTMLInputElement>(null);

  // previewUrl の解放
  useEffect(() => {
    return () => {
      photos.forEach((p) => {
        if (p.previewUrl) URL.revokeObjectURL(p.previewUrl);
      });
    };
    // アンマウント時のみ
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const remaining = MAX_PHOTOS - photos.length;

  return (
    <div className="flex flex-col gap-3">
      <div className="grid grid-cols-4 gap-2">
        {photos.map((p, i) => (
          <div key={p.id} className="relative aspect-square overflow-hidden rounded-card bg-ledge">
            {p.previewUrl ? (
              // eslint-disable-next-line @next/next/no-img-element -- ローカルの blob: プレビュー（next/image は不要）
              <img src={p.previewUrl} alt={`添付写真 ${i + 1}`} className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full w-full flex-col items-center justify-center gap-1 px-2 text-center">
                <span className="text-eyebrow text-dust">HEIC</span>
                <span className="line-clamp-2 break-all text-[11px] text-ash">{p.file.name}</span>
              </div>
            )}
            <button
              type="button"
              onClick={() => onRemove(p.id)}
              disabled={disabled}
              aria-label={`写真 ${i + 1} を外す`}
              className="pressable absolute right-1 top-1 flex h-7 w-7 items-center justify-center rounded-pill bg-rock/85 text-chalk hover:bg-hold-red hover:text-wall-ink"
            >
              <svg width="12" height="12" viewBox="0 0 12 12" aria-hidden="true" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <path d="M2 2l8 8M10 2l-8 8" />
              </svg>
            </button>
          </div>
        ))}
        {remaining > 0 ? (
          <button
            type="button"
            onClick={() => inputRef.current?.click()}
            disabled={disabled}
            className="pressable flex aspect-square flex-col items-center justify-center gap-1 rounded-card border border-dashed border-crack text-dust hover:border-dust hover:text-chalk disabled:opacity-50"
          >
            <svg width="20" height="20" viewBox="0 0 20 20" aria-hidden="true" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" fill="none">
              <path d="M10 4v12M4 10h12" />
            </svg>
            <span className="font-numeric text-[12px] tracking-[0.08em]">
              {photos.length}/{MAX_PHOTOS}
            </span>
          </button>
        ) : null}
      </div>
      <input
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp,image/heic,image/heif,.heic,.heif"
        multiple
        hidden
        onChange={(e) => {
          if (e.target.files && e.target.files.length > 0) onAdd(e.target.files);
          e.target.value = "";
        }}
      />
    </div>
  );
}
