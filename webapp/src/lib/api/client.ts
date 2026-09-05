import { env } from "@/lib/env";
import type { ApiEnvelope } from "./types";

/**
 * バックエンド API の薄いクライアント。サーバー（RSC）とブラウザの両方から使う。
 *
 * - 認証が要るときは `token`（Firebase ID トークン）を渡す → `Authorization: Bearer`。
 * - 失敗は ApiError（status 付き）。404 は呼び出し側で「無い」に倒せるよう status を保つ。
 * - サーバー側の読み取りは `revalidate` 秒でキャッシュ（Next の fetch キャッシュ）。
 */
export class ApiError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly body?: unknown,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export interface RequestOptions {
  method?: "GET" | "POST" | "PATCH" | "PUT" | "DELETE";
  token?: string | null;
  body?: unknown;
  /** サーバー側キャッシュ秒数。0 で毎回取得。未指定は 0 */
  revalidate?: number;
  /** Next の fetch キャッシュタグ（revalidateTag 用） */
  tags?: string[];
  signal?: AbortSignal;
}

export async function apiRequest<T>(path: string, opts: RequestOptions = {}): Promise<T> {
  const url = `${env.apiBaseUrl}${path.startsWith("/") ? path : `/${path}`}`;
  const headers: Record<string, string> = { Accept: "application/json" };
  if (opts.body !== undefined) headers["Content-Type"] = "application/json";
  if (opts.token) headers["Authorization"] = `Bearer ${opts.token}`;

  const init: RequestInit & { next?: { revalidate?: number; tags?: string[] } } = {
    method: opts.method ?? "GET",
    headers,
    body: opts.body === undefined ? undefined : JSON.stringify(opts.body),
    signal: opts.signal,
  };
  // ブラウザでは next オプションは無視されるので付けても害はない
  if (opts.revalidate !== undefined || opts.tags) {
    init.next = { revalidate: opts.revalidate ?? 0, tags: opts.tags };
  } else {
    init.cache = "no-store";
  }

  const res = await fetch(url, init);
  let json: ApiEnvelope<T> | undefined;
  try {
    json = (await res.json()) as ApiEnvelope<T>;
  } catch {
    json = undefined;
  }
  if (!res.ok) {
    throw new ApiError(res.status, json?.message ?? `API ${res.status}: ${path}`, json);
  }
  if (!json || json.success === false) {
    throw new ApiError(res.status, json?.message ?? `API returned failure: ${path}`, json);
  }
  return json.data;
}

/** 404 を null に倒す */
export async function apiRequestOrNull<T>(path: string, opts: RequestOptions = {}): Promise<T | null> {
  try {
    return await apiRequest<T>(path, opts);
  } catch (e) {
    if (e instanceof ApiError && e.status === 404) return null;
    throw e;
  }
}

export const toNumber = (v: string | number | null | undefined, fallback = 0): number => {
  if (v === null || v === undefined || v === "") return fallback;
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? n : fallback;
};
