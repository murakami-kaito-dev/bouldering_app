import { Storage } from '@google-cloud/storage';
import { config } from '../config/environment';
import { ApiError } from '../middleware/error';
import logger from '../utils/logger';
import {
  AllowedUploadContentType,
  SIGNED_UPLOAD_URL_TTL_MS,
  UploadKind,
  buildObjectPath,
  buildPublicUrl,
  resolveExtension,
} from '../domain/services/UploadPolicy';

/**
 * アップロード用 署名付きURL 発行サービス（Web アプリ向け）
 *
 * 背景:
 * - iOS アプリはサービスアカウント鍵を同梱して GCS に直接アップロードしている（別途是正予定）
 * - Web は資格情報を一切持たせず、バックエンドが短命の V4 署名付き PUT URL を発行し、
 *   ブラウザが公開メディアバケットへ直接 PUT する
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層のサービス（GCS 署名という外部依存を隠蔽）
 * - パス決定などの純粋ロジックは domain/services/UploadPolicy.ts に置く
 *
 * 認証情報:
 * - storageService.ts と同じく `new Storage()` = Application Default Credentials
 * - Cloud Run 上では実行サービスアカウントに秘密鍵が無いため、V4 署名は
 *   IAM Credentials API の signBlob で行われる。SA 自身に
 *   roles/iam.serviceAccountTokenCreator が必要（詳細: backend/docs-web-uploads.md）
 */

export interface SignUploadInput {
  uid: string;
  kind: UploadKind;
  contentType: AllowedUploadContentType;
  fileName?: string | null;
  postUuid?: string | null;
}

export interface SignedUpload {
  kind: UploadKind;
  method: 'PUT';
  upload_url: string;
  public_url: string;
  object_path: string;
  content_type: AllowedUploadContentType;
  /** ブラウザが PUT 時に付けるべきヘッダー（署名に含まれているので一致必須） */
  headers: Record<string, string>;
  expires_at: string;
  /** kind=post のみ */
  storage_prefix?: string;
  post_uuid?: string;
  asset_uuid?: string;
}

export class UploadService {
  private storage: Storage;
  private bucketName: string;

  constructor(storage: Storage = new Storage(), bucketName: string = config.storage.bucketName) {
    this.storage = storage;
    this.bucketName = bucketName;
  }

  /**
   * 署名付き PUT URL を発行する
   */
  async createSignedUpload(input: SignUploadInput): Promise<SignedUpload> {
    if (!this.bucketName) {
      logger.error('GCS bucket name is not configured (GCS_BUCKET_NAME)');
      throw new ApiError(500, 'ストレージの設定が不足しています', 'STORAGE_NOT_CONFIGURED');
    }

    const ext = resolveExtension(input.contentType, input.fileName);

    let built;
    try {
      built = buildObjectPath({
        kind: input.kind,
        uid: input.uid,
        ext,
        postUuid: input.postUuid,
      });
    } catch (error) {
      logger.warn('Rejected upload path input', {
        userId: input.uid,
        kind: input.kind,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      throw new ApiError(400, 'アップロード先を決められませんでした', 'INVALID_UPLOAD_PATH');
    }

    const expiresAtMs = Date.now() + SIGNED_UPLOAD_URL_TTL_MS;

    try {
      const [uploadUrl] = await this.storage
        .bucket(this.bucketName)
        .file(built.objectPath)
        .getSignedUrl({
          version: 'v4',
          action: 'write',
          expires: expiresAtMs,
          contentType: input.contentType,
        });

      logger.info('Signed upload URL issued', {
        userId: input.uid,
        kind: input.kind,
        objectPath: built.objectPath,
        contentType: input.contentType,
        bucketName: this.bucketName,
      });

      return {
        kind: input.kind,
        method: 'PUT',
        upload_url: uploadUrl,
        public_url: buildPublicUrl(this.bucketName, built.objectPath),
        object_path: built.objectPath,
        content_type: input.contentType,
        headers: { 'Content-Type': input.contentType },
        expires_at: new Date(expiresAtMs).toISOString(),
        ...(built.storagePrefix ? { storage_prefix: built.storagePrefix } : {}),
        ...(built.postUuid ? { post_uuid: built.postUuid } : {}),
        ...(built.assetUuid ? { asset_uuid: built.assetUuid } : {}),
      };
    } catch (error) {
      logger.error('Failed to sign upload URL', {
        userId: input.uid,
        kind: input.kind,
        objectPath: built.objectPath,
        bucketName: this.bucketName,
        error: error instanceof Error ? error.message : 'Unknown error',
        stack: error instanceof Error ? error.stack : undefined,
      });
      throw new ApiError(500, 'アップロードURLの発行に失敗しました', 'UPLOAD_SIGN_FAILED');
    }
  }
}
