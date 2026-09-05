import { apiRequest } from "@/lib/api/client";
import { errorResponse, isResponse, jsonError, jsonOk, readJson, requireAuth } from "@/lib/auth/server";

interface SignBody {
  kind?: unknown;
  content_type?: unknown;
  file_name?: unknown;
}

export interface SignedUpload {
  upload_url: string;
  public_url: string;
  object_path: string;
  expires_at: string;
}

const ALLOWED_TYPES = new Set(["image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"]);

/**
 * POST /api/uploads/sign → POST /uploads/sign（バックエンドで署名付き PUT URL を発行）。
 * 契約: { kind:"post", content_type, file_name? } → { upload_url, public_url, object_path, expires_at }
 * バックエンド未デプロイの間は 404 が返る → フォーム側で「写真のアップロードは準備中」に倒す。
 */
export async function POST(req: Request) {
  const ctx = requireAuth(req);
  if (isResponse(ctx)) return ctx;
  const body = await readJson<SignBody>(req);
  if (!body || body.kind !== "post") return jsonError(400, "kind は post のみ対応しています");
  const contentType = typeof body.content_type === "string" ? body.content_type.toLowerCase() : "";
  if (!ALLOWED_TYPES.has(contentType)) return jsonError(400, "対応していない画像形式です（JPEG / PNG / WebP / HEIC）", "TYPE_INVALID");
  const fileName = typeof body.file_name === "string" ? body.file_name.slice(0, 200) : undefined;
  try {
    const signed = await apiRequest<SignedUpload>("/uploads/sign", {
      method: "POST",
      token: ctx.token,
      body: { kind: "post", content_type: contentType, file_name: fileName },
    });
    return jsonOk(signed);
  } catch (e) {
    return errorResponse(e);
  }
}
