"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import { useAuth, safeNextPath } from "@/lib/auth";
import { Container, Eyebrow } from "@/components/ui/Primitives";
import { AppleButton, GoogleButton } from "./ProviderButtons";

const TERMS = "https://murakami-kaito-dev.github.io/iwanoboritai-legal/terms/";
const PRIVACY = "https://murakami-kaito-dev.github.io/iwanoboritai-legal/privacy/";

/** /login の本体。?next= があればログイン後にそこへ戻る（同一オリジンのパスのみ） */
export function LoginScreen() {
  const { status, available, signInWithGoogle, signInWithApple, pendingError, clearPendingError } = useAuth();
  const router = useRouter();
  const params = useSearchParams();
  const next = safeNextPath(params.get("next"), "/me");
  const [busy, setBusy] = useState<"google" | "apple" | null>(null);
  const [error, setError] = useState<string | null>(null);

  // すでにログイン済みなら戻す
  useEffect(() => {
    if (status === "signedIn") router.replace(next);
  }, [status, next, router]);

  // リダイレクト方式で戻ってきて失敗していたら、その文言を優先して出す
  const shownError = error ?? pendingError;

  const run = async (kind: "google" | "apple") => {
    setError(null);
    clearPendingError();
    setBusy(kind);
    try {
      const ok = await (kind === "google" ? signInWithGoogle() : signInWithApple());
      if (ok) router.replace(next);
    } catch (e) {
      setError(e instanceof Error ? e.message : "ログインに失敗しました。時間をおいて再度お試しください。");
    } finally {
      setBusy(null);
    }
  };

  return (
    <Container narrow className="flex flex-col gap-8 py-12 md:py-16">
      <div className="flex flex-col gap-2">
        <Eyebrow>SIGN IN</Eyebrow>
        <h1 className="text-h1">ログイン</h1>
        <span className="tape-rule mt-1" aria-hidden="true" />
      </div>

      <div className="flex flex-col gap-5 rounded-card bg-joint p-5 md:p-6">
        <p className="text-dust">
          ログインが必要なのは<span className="text-chalk">ボル活の投稿</span>と<span className="text-chalk">イキタイ</span>だけ。
          ジム検索とみんなのボル活はログインなしで使えます。
        </p>

        {!available ? (
          <p className="rounded-card border border-crack bg-ledge px-4 py-3 text-small text-dust">ログインは現在ご利用いただけません（Firebase の設定が未完了です）。</p>
        ) : null}

        <div className="flex flex-col gap-3">
          <GoogleButton onClick={() => run("google")} disabled={!available || busy !== null || status === "loading"}>
            {busy === "google" ? "Google に接続中…" : "Google でログイン"}
          </GoogleButton>
          <AppleButton onClick={() => run("apple")} disabled={!available || busy !== null || status === "loading"}>
            {busy === "apple" ? "Apple に接続中…" : "Apple でログイン"}
          </AppleButton>
        </div>

        {shownError ? (
          <p role="alert" className="rounded-card border border-hold-red/40 bg-hold-red/10 px-4 py-3 text-small text-hold-red">
            {shownError}
          </p>
        ) : null}

        <p className="text-small text-dust">
          ログインすると、
          <a href={TERMS} target="_blank" rel="noopener noreferrer" className="text-chalk underline underline-offset-4 hover:text-wall">
            利用規約
          </a>
          と
          <a href={PRIVACY} target="_blank" rel="noopener noreferrer" className="text-chalk underline underline-offset-4 hover:text-wall">
            プライバシーポリシー
          </a>
          に同意したものとみなします。iOS アプリと同じアカウントでログインすると、記録が共有されます。
        </p>
      </div>

      <p className="text-small text-ash">
        <Link href={next === "/me" ? "/" : next} className="hover:text-dust hover:underline underline-offset-4">
          ← ログインせずに戻る
        </Link>
      </p>
    </Container>
  );
}
