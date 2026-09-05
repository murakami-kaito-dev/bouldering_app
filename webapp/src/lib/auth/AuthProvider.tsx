"use client";

import { hasFirebaseConfig } from "@/lib/env";

import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import {
  GoogleAuthProvider,
  OAuthProvider,
  getRedirectResult,
  onAuthStateChanged,
  signInWithPopup,
  signInWithRedirect,
  signOut as fbSignOut,
  type Auth,
  type User,
} from "firebase/auth";
import { FirebaseError } from "firebase/app";
import { getFirebaseAuth } from "./firebase";
import { bff, bffOrNull, BffError } from "./bff";
import { AuthFlowError, authErrorMessage, isCancelled, shouldFallbackToRedirect } from "./errors";

/**
 * 認証状態（Firebase Auth）をアプリ全体へ配る。
 *
 * 流れはアプリ（auth_provider.dart の signInWith → loginOrRegister）と同じ:
 *   Firebase でサインイン → GET /api/me（= GET /users/:uid）→ 404 なら POST /api/me（= POST /users）→ 再取得。
 *   バックエンド側に進めなかったら Firebase のセッションを残さない（signOut して日本語エラーを返す）。
 * 永続化は Firebase に任せる（自前で何も保存しない）。
 */
export type AuthStatus = "loading" | "signedOut" | "signedIn";

export interface AuthUser {
  uid: string;
  displayName: string | null;
  photoURL: string | null;
}

export interface AuthContextValue {
  user: AuthUser | null;
  status: AuthStatus;
  /** ログインが構成されていない（Firebase 設定なし）とき false */
  available: boolean;
  /** 成功で true、ユーザーがキャンセルしたら false。失敗は日本語メッセージの Error を投げる */
  signInWithGoogle: () => Promise<boolean>;
  signInWithApple: () => Promise<boolean>;
  signOut: () => Promise<void>;
  /** Firebase ID トークン（未ログインなら null） */
  getIdToken: (forceRefresh?: boolean) => Promise<string | null>;
  /** リダイレクト方式で戻ってきた直後に失敗していたときの日本語メッセージ（/login が表示して消す） */
  pendingError: string | null;
  clearPendingError: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const toAuthUser = (u: User): AuthUser => ({ uid: u.uid, displayName: u.displayName, photoURL: u.photoURL });

/** GET /users/:uid → 404 なら POST /users → 再取得（アプリの loginOrRegister と同じ） */
async function ensureRegistered(user: User): Promise<void> {
  const token = await user.getIdToken();
  let me: unknown;
  try {
    me = await bffOrNull("/api/me", { token });
    if (me === null) {
      await bff("/api/me", { method: "POST", token });
      me = await bffOrNull("/api/me", { token });
    }
  } catch (e) {
    if (e instanceof BffError) {
      throw new AuthFlowError(
        e.status >= 500 || e.status === 502
          ? "サーバーとの通信に失敗しました。時間をおいて再度お試しください。"
          : `ユーザー情報の登録に失敗しました（${e.message}）`,
        e.status,
      );
    }
    throw new AuthFlowError("サーバーとの通信に失敗しました。時間をおいて再度お試しください。");
  }
  if (me === null) throw new AuthFlowError("ユーザー情報の登録に失敗しました。時間をおいて再度お試しください。");
}

const isIosSafari = (): boolean => {
  if (typeof navigator === "undefined") return false;
  const ua = navigator.userAgent;
  const ios = /iP(hone|ad|od)/.test(ua) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
  return ios && /Safari/.test(ua) && !/CriOS|FxiOS|EdgiOS/.test(ua);
};

export function AuthProvider({ children }: { children: ReactNode }) {
  const [auth] = useState<Auth | null>(() => getFirebaseAuth());
  const [user, setUser] = useState<AuthUser | null>(null);
  // SSR とハイドレーションで同じ初期値にする（サーバーでは auth が null なので "loading" を hasFirebaseConfig で決める）。
  // auth が本当に無いときは下の effect で signedOut に落とす
  const [status, setStatus] = useState<AuthStatus>(hasFirebaseConfig ? "loading" : "signedOut");
  useEffect(() => {
    // 設定はあるのにクライアントで初期化できなかった場合だけ（通常は通らない）
    // eslint-disable-next-line react-hooks/set-state-in-effect
    if (!auth) setStatus("signedOut");
  }, [auth]);
  const [pendingError, setPendingError] = useState<string | null>(null);
  /** signInWith* の途中（onAuthStateChanged 側で二重に登録処理をしないためのフラグ） */
  const signingIn = useRef(false);

  useEffect(() => {
    if (!auth) return;
    let disposed = false;

    // リダイレクト方式で戻ってきた直後（ポップアップが使えなかった環境）: ここで登録処理を厳密に行う
    signingIn.current = true;
    getRedirectResult(auth)
      .then(async (res) => {
        if (!res || disposed) return;
        try {
          await ensureRegistered(res.user);
        } catch (e) {
          await fbSignOut(auth);
          console.error("[auth] redirect sign-in: backend registration failed", e);
          if (!disposed) setPendingError(e instanceof Error ? e.message : String(e));
        }
      })
      .catch((e) => {
        console.error("[auth] getRedirectResult failed", e);
        if (!disposed && !isCancelled(e)) {
          const apple = e instanceof FirebaseError && /apple/i.test(String(e.customData?.["providerId"] ?? ""));
          setPendingError(authErrorMessage(e, apple ? "apple" : "google"));
        }
      })
      .finally(() => {
        signingIn.current = false;
      });

    const unsub = onAuthStateChanged(auth, (u) => {
      if (disposed) return;
      if (!u) {
        setUser(null);
        setStatus("signedOut");
        return;
      }
      setUser(toAuthUser(u));
      setStatus("signedIn");
      // 永続化されたセッションの復元時は静かに登録確認（失敗してもログアウトさせない。アプリの _loadUserQuietly と同じ）
      if (!signingIn.current) {
        ensureRegistered(u).catch((e) => console.warn("[auth] quiet registration check failed", e));
      }
    });
    return () => {
      disposed = true;
      unsub();
    };
  }, [auth]);

  const signInWith = useCallback(
    async (kind: "google" | "apple"): Promise<boolean> => {
      if (!auth) throw new Error("ログインは現在ご利用いただけません（設定が未完了です）");
      const provider =
        kind === "google"
          ? new GoogleAuthProvider()
          : (() => {
              const p = new OAuthProvider("apple.com");
              p.addScope("email");
              p.addScope("name");
              p.setCustomParameters({ locale: "ja_JP" });
              return p;
            })();
      signingIn.current = true;
      try {
        let signedUser: User;
        try {
          if (isIosSafari()) {
            await signInWithRedirect(auth, provider);
            return false; // ページ遷移するのでここには戻らない
          }
          const cred = await signInWithPopup(auth, provider);
          signedUser = cred.user;
        } catch (e) {
          if (isCancelled(e)) return false;
          if (shouldFallbackToRedirect(e)) {
            await signInWithRedirect(auth, provider);
            return false;
          }
          throw new Error(authErrorMessage(e, kind));
        }
        try {
          await ensureRegistered(signedUser);
        } catch (e) {
          await fbSignOut(auth);
          throw e instanceof Error ? e : new Error(String(e));
        }
        setUser(toAuthUser(signedUser));
        setStatus("signedIn");
        return true;
      } finally {
        signingIn.current = false;
      }
    },
    [auth],
  );

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      status,
      // SSR とクライアントで同じ値にする（auth の有無で決めるとハイドレーション不一致になる）。
      // 設定があるのに初期化できないときは signIn* 側でエラーを出す
      available: hasFirebaseConfig,
      signInWithGoogle: () => signInWith("google"),
      signInWithApple: () => signInWith("apple"),
      signOut: async () => {
        if (!auth) return;
        await fbSignOut(auth);
      },
      getIdToken: async (forceRefresh = false) => {
        const u = auth?.currentUser;
        if (!u) return null;
        try {
          return await u.getIdToken(forceRefresh);
        } catch {
          return null;
        }
      },
      pendingError,
      clearPendingError: () => setPendingError(null),
    }),
    [auth, user, status, signInWith, pendingError],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth は <AuthProvider> の内側で使う");
  return ctx;
}
