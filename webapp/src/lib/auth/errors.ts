import { FirebaseError } from "firebase/app";

/** ユーザーが自分で閉じた・二重起動など「エラー表示しなくてよい」中断 */
export function isCancelled(e: unknown): boolean {
  if (!(e instanceof FirebaseError)) return false;
  return (
    e.code === "auth/popup-closed-by-user" ||
    e.code === "auth/cancelled-popup-request" ||
    e.code === "auth/user-cancelled" ||
    e.code === "auth/web-context-cancelled"
  );
}

/** ポップアップが使えない環境（ブロック・iOS の in-app ブラウザ等）→ リダイレクト方式に切り替える */
export function shouldFallbackToRedirect(e: unknown): boolean {
  if (!(e instanceof FirebaseError)) return false;
  return e.code === "auth/popup-blocked" || e.code === "auth/operation-not-supported-in-this-environment";
}

export const APPLE_NOT_READY = "Apple でのログインは準備中です。Google をお使いください";

/** Firebase / 通信のエラーを日本語の 1 行に */
export function authErrorMessage(e: unknown, provider: "google" | "apple" = "google"): string {
  if (e instanceof AuthFlowError) return e.message;
  if (e instanceof FirebaseError) {
    switch (e.code) {
      case "auth/network-request-failed":
        return "サーバーとの通信に失敗しました。ネットワーク環境を確認して、再度お試しください。";
      case "auth/account-exists-with-different-credential":
        return "このメールアドレスは別のログイン方法で登録されています。前回と同じ方法でログインしてください。";
      case "auth/too-many-requests":
        return "試行回数が多すぎます。しばらく時間をおいて再度お試しください。";
      case "auth/unauthorized-domain":
        return "このドメインからのログインは許可されていません（Firebase の承認済みドメイン設定）。";
      case "auth/operation-not-allowed":
      case "auth/invalid-oauth-client-id":
      case "auth/invalid-credential":
      case "auth/missing-or-invalid-nonce":
        if (provider === "apple") return APPLE_NOT_READY;
        return "ログインに失敗しました。時間をおいて再度お試しください。";
      default:
        if (provider === "apple") return APPLE_NOT_READY;
        return "ログインに失敗しました。時間をおいて再度お試しください。";
    }
  }
  return "ログインに失敗しました。時間をおいて再度お試しください。";
}

/** バックエンド登録（GET/POST /users）で失敗したときに投げる。文言はそのまま画面へ */
export class AuthFlowError extends Error {
  constructor(message: string, public readonly status?: number) {
    super(message);
    this.name = "AuthFlowError";
  }
}
