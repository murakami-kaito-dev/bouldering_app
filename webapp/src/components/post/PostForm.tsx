"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import type { Tweet } from "@/lib/api/types";
import { bff, BffError, useAuth } from "@/lib/auth";
import type { SignedUpload } from "@/app/api/uploads/sign/route";
import { todayYmdJst } from "@/lib/gym/hours";
import { Container, Eyebrow } from "@/components/ui/Primitives";
import { Button, LinkButton } from "@/components/ui/Button";
import { GymCombobox, type PickerGym } from "./GymCombobox";
import { MAX_PHOTOS, PhotoPicker, toPicked, type PickedPhoto } from "./PhotoPicker";

const MAX_CONTENT = 400;

type Phase = "edit" | "uploading" | "posting" | "done";

/**
 * ボル活投稿フォーム。
 * 送信: 写真ごとに POST /api/uploads/sign → PUT（署名付き URL）→ public_url を集めて POST /api/post。
 * 署名エンドポイントが 404（バックエンド未デプロイ）のときは「写真のアップロードは準備中」に倒し、写真なしでの投稿を案内する。
 */
export function PostForm({ gyms, initialGymId }: { gyms: PickerGym[]; initialGymId: number | null }) {
  const { getIdToken } = useAuth();
  const router = useRouter();
  const today = useMemo(() => todayYmdJst(), []);

  const [gym, setGym] = useState<PickerGym | null>(() => (initialGymId ? (gyms.find((g) => g.id === initialGymId) ?? null) : null));
  const [date, setDate] = useState(today);
  const [content, setContent] = useState("");
  const [photos, setPhotos] = useState<PickedPhoto[]>([]);
  const [phase, setPhase] = useState<Phase>("edit");
  const [progress, setProgress] = useState<{ done: number; total: number } | null>(null);
  const [error, setError] = useState<{ message: string; kind?: "auth" | "upload-unavailable" } | null>(null);
  const [fieldError, setFieldError] = useState<{ gym?: string; date?: string; content?: string; photos?: string }>({});
  const [posted, setPosted] = useState<Tweet | null>(null);

  const length = [...content].length;
  const busy = phase === "uploading" || phase === "posting";

  // 投稿完了 → ジム詳細のボル活タブへ
  useEffect(() => {
    if (phase !== "done" || !posted) return;
    const t = setTimeout(() => router.push(`/gyms/${posted.gymId}?tab=boul-log`), 1800);
    return () => clearTimeout(t);
  }, [phase, posted, router]);

  const addFiles = (files: FileList) => {
    setFieldError((f) => ({ ...f, photos: undefined }));
    const errors: string[] = [];
    const next = [...photos];
    for (const file of Array.from(files)) {
      if (next.length >= MAX_PHOTOS) {
        errors.push(`写真は ${MAX_PHOTOS} 枚までです`);
        break;
      }
      const r = toPicked(file);
      if ("error" in r) errors.push(r.error);
      else next.push(r);
    }
    setPhotos(next);
    if (errors.length) setFieldError((f) => ({ ...f, photos: errors.join(" / ") }));
  };

  const removePhoto = (id: string) => {
    setPhotos((prev) => {
      const hit = prev.find((p) => p.id === id);
      if (hit?.previewUrl) URL.revokeObjectURL(hit.previewUrl);
      return prev.filter((p) => p.id !== id);
    });
  };

  const validate = (): boolean => {
    const fe: typeof fieldError = {};
    if (!gym) fe.gym = "ジムを選んでください";
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) fe.date = "日付を入力してください";
    else if (date > today) fe.date = "未来の日付は選べません";
    if (length > MAX_CONTENT) fe.content = `本文は ${MAX_CONTENT} 文字以内にしてください`;
    setFieldError(fe);
    return Object.keys(fe).length === 0;
  };

  const submit = async (opts: { withoutPhotos?: boolean } = {}) => {
    setError(null);
    if (!validate() || !gym) return;
    const token = await getIdToken();
    if (!token) {
      setError({ message: "ログインの有効期限が切れました。もう一度ログインしてください。", kind: "auth" });
      return;
    }
    const files = opts.withoutPhotos ? [] : photos;
    const mediaUrls: string[] = [];

    try {
      if (files.length > 0) {
        setPhase("uploading");
        setProgress({ done: 0, total: files.length });
        for (let i = 0; i < files.length; i++) {
          const p = files[i];
          let signed: SignedUpload;
          try {
            signed = await bff<SignedUpload>("/api/uploads/sign", {
              method: "POST",
              token,
              body: { kind: "post", content_type: p.contentType, file_name: p.file.name },
            });
          } catch (e) {
            if (e instanceof BffError && e.status === 404) {
              setError({ message: "写真のアップロードは準備中です。写真を外すと投稿できます。", kind: "upload-unavailable" });
              setPhase("edit");
              setProgress(null);
              return;
            }
            throw e;
          }
          const put = await fetch(signed.upload_url, { method: "PUT", headers: { "Content-Type": p.contentType }, body: p.file });
          if (!put.ok) throw new Error(`写真のアップロードに失敗しました（${put.status}）`);
          mediaUrls.push(signed.public_url);
          setProgress({ done: i + 1, total: files.length });
        }
      }

      setPhase("posting");
      const tweet = await bff<Tweet>("/api/post", {
        method: "POST",
        token,
        body: { gym_id: gym.id, tweet_contents: content, visited_date: date, media_urls: mediaUrls },
      });
      setPosted(tweet);
      setPhase("done");
    } catch (e) {
      setPhase("edit");
      setProgress(null);
      if (e instanceof BffError) {
        if (e.status === 401) setError({ message: "ログインの有効期限が切れました。もう一度ログインしてください。", kind: "auth" });
        else setError({ message: e.message });
      } else {
        setError({ message: e instanceof Error ? e.message : "投稿に失敗しました。時間をおいて再度お試しください。" });
      }
    }
  };

  if (phase === "done" && posted) {
    return (
      <Container narrow className="flex flex-col items-start gap-6 py-16">
        <Eyebrow>POSTED</Eyebrow>
        <h1 className="text-h1">記録しました</h1>
        <span className="tape-rule" aria-hidden="true" />
        <p className="text-dust">
          {posted.gymName} のボル活（{posted.visitedDate}）を投稿しました。ジムのボル活タブへ移動します…
        </p>
        <div className="flex flex-wrap gap-3">
          <LinkButton href={`/gyms/${posted.gymId}?tab=boul-log`}>ジムのボル活を見る</LinkButton>
          <LinkButton href="/me" variant="secondary">
            マイページ
          </LinkButton>
        </div>
      </Container>
    );
  }

  return (
    <Container narrow className="flex flex-col gap-8 py-10 md:py-12">
      <div className="flex flex-col gap-2">
        <Eyebrow>NEW LOG</Eyebrow>
        <h1 className="text-h1">ボル活を投稿</h1>
        <span className="tape-rule mt-1" aria-hidden="true" />
      </div>

      <form
        className="flex flex-col gap-7 rounded-card bg-joint p-5 md:p-6"
        onSubmit={(e) => {
          e.preventDefault();
          void submit();
        }}
        aria-busy={busy}
      >
        <Field label="ジム" error={fieldError.gym}>
          <GymCombobox gyms={gyms} value={gym} onChange={(g) => { setGym(g); setFieldError((f) => ({ ...f, gym: undefined })); }} invalid={!!fieldError.gym} />
        </Field>

        <Field label="登った日" error={fieldError.date} hint="日本時間の今日まで">
          <input
            type="date"
            value={date}
            max={today}
            required
            disabled={busy}
            onChange={(e) => setDate(e.target.value)}
            className={`h-12 w-full rounded-card border bg-ledge px-4 font-numeric text-[18px] font-semibold tracking-[0.02em] text-chalk focus:outline-none md:w-64 ${fieldError.date ? "border-hold-red" : "border-crack focus:border-wall"}`}
          />
        </Field>

        <Field
          label="本文"
          error={fieldError.content}
          aside={
            <span className={`font-numeric text-[13px] tracking-[0.04em] ${length > MAX_CONTENT ? "text-hold-red" : "text-dust"}`}>
              {length} / {MAX_CONTENT}
            </span>
          }
        >
          <textarea
            value={content}
            disabled={busy}
            rows={6}
            placeholder="今日の課題、落とせた壁、次の目標。空でも投稿できます"
            onChange={(e) => setContent(e.target.value)}
            className={`w-full resize-y rounded-card border bg-ledge px-4 py-3 text-[16px] leading-[1.7] text-chalk placeholder:text-dust focus:outline-none ${fieldError.content ? "border-hold-red" : "border-crack focus:border-wall"}`}
          />
        </Field>

        <Field label="写真" error={fieldError.photos} hint={`${MAX_PHOTOS} 枚まで・1 枚 10MB まで（JPEG / PNG / WebP / HEIC）`}>
          <PhotoPicker photos={photos} onAdd={addFiles} onRemove={removePhoto} disabled={busy} />
        </Field>

        {error ? (
          <div role="alert" className="flex flex-col gap-3 rounded-card border border-hold-red/40 bg-hold-red/10 px-4 py-3 text-small text-hold-red">
            <span>{error.message}</span>
            {error.kind === "auth" ? (
              <Link href="/login?next=/post" className="w-fit rounded-pill border border-hold-red px-4 py-1 font-bold hover:bg-hold-red hover:text-wall-ink">
                ログインし直す
              </Link>
            ) : null}
            {error.kind === "upload-unavailable" ? (
              <button
                type="button"
                onClick={() => {
                  photos.forEach((p) => p.previewUrl && URL.revokeObjectURL(p.previewUrl));
                  setPhotos([]);
                  void submit({ withoutPhotos: true });
                }}
                className="w-fit rounded-pill border border-hold-red px-4 py-1 font-bold hover:bg-hold-red hover:text-wall-ink"
              >
                写真なしで投稿する
              </button>
            ) : null}
          </div>
        ) : null}

        <div className="flex flex-wrap items-center gap-4">
          <Button type="submit" size="lg" disabled={busy}>
            {phase === "uploading" && progress
              ? `写真をアップロード中 ${progress.done}/${progress.total}`
              : phase === "posting"
                ? "投稿中…"
                : "投稿する"}
          </Button>
          <Link href="/me" className="text-small text-dust hover:text-chalk hover:underline underline-offset-4">
            キャンセル
          </Link>
        </div>
      </form>
    </Container>
  );
}

function Field({ label, hint, error, aside, children }: { label: string; hint?: string; error?: string; aside?: React.ReactNode; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-end justify-between gap-3">
        <span className="font-display text-[14px] font-bold text-chalk">{label}</span>
        {aside}
      </div>
      {children}
      {error ? (
        <p role="alert" className="text-small text-hold-red">
          {error}
        </p>
      ) : hint ? (
        <p className="text-small text-ash">{hint}</p>
      ) : null}
    </div>
  );
}
