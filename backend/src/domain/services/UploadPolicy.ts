import { randomUUID } from 'crypto';
import { toJstDate } from '../../utils/jstTime';

/**
 * アップロード方針（署名付きURL発行のための純粋ロジック）
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層。GCS など外部サービスに依存しない（テストしやすい）
 * - 「どの種類のファイルを」「どのオブジェクトパスに置くか」をここで決める
 *
 * オブジェクトパスは iOS アプリ（lib/infrastructure/services/storage_service.dart）と
 * 完全に同じ構造にする。理由:
 * - 投稿メディアの削除ジョブ（storageCleanupPublisher / PostgresTweetRepository）が
 *   URL から「バケット名と末尾ファイル名を除いた部分」を storage_prefix として扱うため、
 *   `.../{postUuid}/{assetUuid}/original.{ext}` の形でないと削除対象が一致しない
 * - アイコンは固定パス上書き（古い画像が自動的に置き換わる）という運用を共有するため
 */

export const UPLOAD_KINDS = ['post', 'icon'] as const;
export type UploadKind = (typeof UPLOAD_KINDS)[number];

export const ALLOWED_UPLOAD_CONTENT_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
] as const;
export type AllowedUploadContentType = (typeof ALLOWED_UPLOAD_CONTENT_TYPES)[number];

/** 署名付きURLの有効期間（10分） */
export const SIGNED_UPLOAD_URL_TTL_MS = 10 * 60 * 1000;

/** file_name の最大長（拡張子の判定にしか使わない） */
export const UPLOAD_FILE_NAME_MAX_LENGTH = 200;

/** content_type ごとの既定拡張子と、file_name 側で許容する別綴り */
const EXTENSIONS_BY_CONTENT_TYPE: Record<AllowedUploadContentType, { primary: string; aliases: string[] }> = {
  'image/jpeg': { primary: 'jpg', aliases: ['jpg', 'jpeg'] },
  'image/png': { primary: 'png', aliases: ['png'] },
  'image/webp': { primary: 'webp', aliases: ['webp'] },
  'image/heic': { primary: 'heic', aliases: ['heic'] },
};

export function isAllowedUploadContentType(value: unknown): value is AllowedUploadContentType {
  return typeof value === 'string' && (ALLOWED_UPLOAD_CONTENT_TYPES as readonly string[]).includes(value);
}

export function isUploadKind(value: unknown): value is UploadKind {
  return typeof value === 'string' && (UPLOAD_KINDS as readonly string[]).includes(value);
}

/**
 * 拡張子を決める
 * - 正は content_type（file_name は信用しない）
 * - file_name の拡張子が content_type と整合する別綴り（例: .jpeg）ならその綴りを尊重する
 */
export function resolveExtension(contentType: AllowedUploadContentType, fileName?: string | null): string {
  const rule = EXTENSIONS_BY_CONTENT_TYPE[contentType];
  if (fileName) {
    const m = /\.([A-Za-z0-9]+)$/.exec(fileName.trim());
    const candidate = m?.[1]?.toLowerCase();
    if (candidate && rule.aliases.includes(candidate)) {
      return candidate;
    }
  }
  return rule.primary;
}

/**
 * パスに混ぜてよい ID か（Firebase UID / UUID を想定。区切り文字や `..` を含ませない）
 */
export function isSafePathSegment(value: string): boolean {
  return /^[A-Za-z0-9_-]{1,128}$/.test(value);
}

export interface BuildObjectPathInput {
  kind: UploadKind;
  uid: string;
  ext: string;
  /** kind=post のとき。未指定ならサーバーで採番（複数枚を1投稿にまとめるならクライアントが渡す） */
  postUuid?: string | null;
  /** テスト用。通常は省略 */
  assetUuid?: string;
  /** テスト用。通常は省略（年月は JST で決める） */
  now?: Date;
}

export interface BuiltObjectPath {
  objectPath: string;
  /** kind=post のみ。削除ジョブが使うプレフィックス（ファイル名を除いた部分） */
  storagePrefix?: string;
  postUuid?: string;
  assetUuid?: string;
}

/**
 * オブジェクトパスを組み立てる
 *
 * - post: v1/public/users/{uid}/posts/{yyyy}/{mm}/{postUuid}/{assetUuid}/original.{ext}
 * - icon: v1/public/users/{uid}/profile/icon.{ext}（固定パス・上書き）
 */
export function buildObjectPath(input: BuildObjectPathInput): BuiltObjectPath {
  const { kind, uid, ext } = input;

  if (!isSafePathSegment(uid)) {
    throw new Error('Invalid user id for object path');
  }

  if (kind === 'icon') {
    return { objectPath: `v1/public/users/${uid}/profile/icon.${ext}` };
  }

  const postUuid = input.postUuid || randomUUID();
  const assetUuid = input.assetUuid || randomUUID();
  if (!isSafePathSegment(postUuid) || !isSafePathSegment(assetUuid)) {
    throw new Error('Invalid uuid for object path');
  }

  const { year, month } = toJstDate(input.now ?? new Date());
  const yyyy = String(year);
  const mm = String(month).padStart(2, '0');

  const storagePrefix = `v1/public/users/${uid}/posts/${yyyy}/${mm}/${postUuid}/${assetUuid}`;
  return {
    objectPath: `${storagePrefix}/original.${ext}`,
    storagePrefix,
    postUuid,
    assetUuid,
  };
}

/** 公開URL（バケットは allUsers 読み取り可が前提） */
export function buildPublicUrl(bucketName: string, objectPath: string): string {
  return `https://storage.googleapis.com/${bucketName}/${objectPath}`;
}
