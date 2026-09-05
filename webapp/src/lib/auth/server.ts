import { NextResponse } from "next/server";
import { ApiError } from "@/lib/api/client";

/**
 * Route Handler（BFF）側の共通部品。
 * - ブラウザから来た Authorization: Bearer <Firebase ID トークン> を取り出す。
 *   トークンの**検証はバックエンド**（Firebase Admin）が行う。ここでは payload の uid を読むだけ
 *   （バックエンドは「トークンの uid ≠ パスの uid」を 403 で弾くので、偽装しても他人の行には届かない）。
 * - バックエンドの失敗（ApiError）を { success:false, message, code } に揃えて返す。
 */
export function bearerToken(req: Request): string | null {
  const h = req.headers.get("authorization") ?? "";
  const m = /^Bearer\s+(.+)$/i.exec(h);
  return m ? m[1].trim() : null;
}

/** JWT の payload から uid（sub）を読む。検証はしない（上記コメント参照） */
export function uidFromToken(token: string): string | null {
  const parts = token.split(".");
  if (parts.length < 2) return null;
  try {
    const payload = JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8")) as { sub?: unknown; user_id?: unknown };
    const uid = typeof payload.sub === "string" ? payload.sub : typeof payload.user_id === "string" ? payload.user_id : null;
    return uid && /^[A-Za-z0-9_-]{1,128}$/.test(uid) ? uid : null;
  } catch {
    return null;
  }
}

export interface AuthedContext {
  token: string;
  uid: string;
}

/** 認証必須のハンドラで最初に呼ぶ。失敗時は 401 のレスポンスを返す */
export function requireAuth(req: Request): AuthedContext | NextResponse {
  const token = bearerToken(req);
  if (!token) return jsonError(401, "ログインが必要です", "UNAUTHENTICATED");
  const uid = uidFromToken(token);
  if (!uid) return jsonError(401, "認証情報が正しくありません", "INVALID_TOKEN");
  return { token, uid };
}

export function isResponse(v: unknown): v is NextResponse {
  return v instanceof Response;
}

export function jsonOk<T>(data: T, status = 200): NextResponse {
  return NextResponse.json({ success: true, data }, { status, headers: { "Cache-Control": "no-store" } });
}

export function jsonError(status: number, message: string, code?: string): NextResponse {
  return NextResponse.json({ success: false, message, code }, { status, headers: { "Cache-Control": "no-store" } });
}

const STATUS_MESSAGE: Record<number, string> = {
  400: "入力内容に誤りがあります",
  401: "ログインの有効期限が切れました。もう一度ログインしてください",
  403: "この操作を行う権限がありません",
  404: "見つかりませんでした",
  409: "すでに登録されています",
  413: "データが大きすぎます",
  429: "リクエストが多すぎます。しばらくしてからお試しください",
};

/** バックエンドのエラーを BFF のレスポンスへ */
export function errorResponse(e: unknown): NextResponse {
  if (e instanceof ApiError) {
    const body = e.body as { error?: unknown; code?: unknown; details?: unknown } | undefined;
    const detail = typeof body?.error === "string" ? body.error : undefined;
    const code = typeof body?.code === "string" ? body.code : undefined;
    const message = STATUS_MESSAGE[e.status] ?? "サーバーでエラーが発生しました。時間をおいて再度お試しください";
    return jsonError(e.status, detail && e.status === 400 ? `${message}（${detail}）` : message, code);
  }
  console.error("[BFF] unexpected error", e);
  return jsonError(502, "サーバーに接続できませんでした。時間をおいて再度お試しください", "UPSTREAM");
}

/** JSON ボディを安全に読む（壊れていたら null） */
export async function readJson<T>(req: Request): Promise<T | null> {
  try {
    return (await req.json()) as T;
  } catch {
    return null;
  }
}
