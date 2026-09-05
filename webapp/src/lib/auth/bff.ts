/**
 * ブラウザ → 自サイトの BFF（/api/me, /api/post, /api/uploads）を叩く薄い関数。
 * バックエンド（Cloud Run）へは BFF が Authorization を転送する。ブラウザから直接は叩かない。
 */
export class BffError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly code?: string,
  ) {
    super(message);
    this.name = "BffError";
  }
}

interface BffEnvelope<T> {
  success: boolean;
  data: T;
  message?: string;
  code?: string;
}

export interface BffOptions {
  method?: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  token?: string | null;
  body?: unknown;
  signal?: AbortSignal;
}

export async function bff<T>(path: string, opts: BffOptions = {}): Promise<T> {
  const headers: Record<string, string> = { Accept: "application/json" };
  if (opts.body !== undefined) headers["Content-Type"] = "application/json";
  if (opts.token) headers["Authorization"] = `Bearer ${opts.token}`;
  const res = await fetch(path, {
    method: opts.method ?? "GET",
    headers,
    body: opts.body === undefined ? undefined : JSON.stringify(opts.body),
    signal: opts.signal,
    cache: "no-store",
  });
  let json: BffEnvelope<T> | undefined;
  try {
    json = (await res.json()) as BffEnvelope<T>;
  } catch {
    json = undefined;
  }
  if (!res.ok || !json || json.success === false) {
    throw new BffError(res.status, json?.message ?? `通信に失敗しました（${res.status}）`, json?.code);
  }
  return json.data;
}

/** 404 を null に倒す */
export async function bffOrNull<T>(path: string, opts: BffOptions = {}): Promise<T | null> {
  try {
    return await bff<T>(path, opts);
  } catch (e) {
    if (e instanceof BffError && e.status === 404) return null;
    throw e;
  }
}
