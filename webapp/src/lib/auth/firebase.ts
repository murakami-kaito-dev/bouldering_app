import { getApp, getApps, initializeApp, type FirebaseApp } from "firebase/app";
import { getAuth, type Auth } from "firebase/auth";
import { env, hasFirebaseConfig } from "@/lib/env";

/**
 * Firebase（Auth のみ）の遅延初期化。ブラウザ専用。
 * - 設定が無い（.env.local 未整備）ときは null を返し、呼び出し側で「ログイン不可」に倒す。
 * - サーバー（RSC / Route Handler）から呼ばない。ID トークンの検証はバックエンドが行う。
 */
let cachedAuth: Auth | null = null;

export function getFirebaseApp(): FirebaseApp | null {
  if (typeof window === "undefined" || !hasFirebaseConfig) return null;
  return getApps().length ? getApp() : initializeApp(env.firebase);
}

export function getFirebaseAuth(): Auth | null {
  if (cachedAuth) return cachedAuth;
  const app = getFirebaseApp();
  if (!app) return null;
  const auth = getAuth(app);
  auth.languageCode = "ja";
  cachedAuth = auth;
  return auth;
}
