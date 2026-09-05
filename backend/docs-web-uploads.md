# Web 向け 画像アップロード（署名付きURL）— 手順と前提

`POST /api/uploads/sign` の追加に伴い、**オーナー / リードが手で行う作業**と、フロント（Web）側の契約をまとめる。
コードは `backend/src/routes/uploads.ts` / `services/uploadService.ts` / `domain/services/UploadPolicy.ts`。

## 1. なぜ

iOS アプリはサービスアカウント鍵を同梱して GCS へ直接アップロードしている（別途是正予定）。
Web には資格情報を一切持たせず、**バックエンドが 10 分有効の V4 署名付き PUT URL を発行し、ブラウザが公開メディアバケットへ直接 PUT** する。

## 2. エンドポイント契約

`POST /api/uploads/sign` — 認証必須（`Authorization: Bearer <Firebase ID token>`）

リクエスト body（JSON）:

| フィールド | 必須 | 値 |
|---|---|---|
| `kind` | 必須 | `"post"`（投稿写真）/ `"icon"`（プロフィールアイコン） |
| `content_type` | 必須 | `image/jpeg` / `image/png` / `image/webp` / `image/heic` |
| `file_name` | 任意 | 200 文字以内。**拡張子の判定にだけ使う**（`.jpeg` 綴りの尊重程度。保存名には使わない） |
| `post_uuid` | 任意 | UUID。`kind=post` で**複数枚を同じ投稿にまとめる**ときに同じ値を渡す。省略時はサーバーが採番して返す |

レスポンス 200:

```json
{
  "success": true,
  "data": {
    "kind": "post",
    "method": "PUT",
    "upload_url": "https://storage.googleapis.com/bouldering-app-media-dev/v1/public/...?X-Goog-Algorithm=GOOG4-RSA-SHA256&...",
    "public_url": "https://storage.googleapis.com/bouldering-app-media-dev/v1/public/users/<uid>/posts/2026/09/<post_uuid>/<asset_uuid>/original.jpg",
    "object_path": "v1/public/users/<uid>/posts/2026/09/<post_uuid>/<asset_uuid>/original.jpg",
    "content_type": "image/jpeg",
    "headers": { "Content-Type": "image/jpeg" },
    "expires_at": "2026-09-05T03:10:00.000Z",
    "storage_prefix": "v1/public/users/<uid>/posts/2026/09/<post_uuid>/<asset_uuid>",
    "post_uuid": "<post_uuid>",
    "asset_uuid": "<asset_uuid>"
  }
}
```

- `storage_prefix` / `post_uuid` / `asset_uuid` は `kind=post` のときだけ付く。
- `kind=icon` の `object_path` は `v1/public/users/<uid>/profile/icon.<ext>`（固定パス・上書き）。

オブジェクトパスは **iOS アプリ（`lib/infrastructure/services/storage_service.dart`）と同一構造**。
削除ジョブ（`storageCleanupPublisher.ts` / `PostgresTweetRepository.deriveStoragePrefixFromMediaUrl`）が
「バケット名と末尾ファイル名を除いた部分」を `storage_prefix` として扱うため、この構造を崩さないこと。
年月（`yyyy/mm`）は JST（`utils/jstTime.ts`）で決める。

エラー:

| 状況 | ステータス | 形 |
|---|---|---|
| トークン無し / 不正 | 401 | `{ success:false, error:'Missing or invalid authorization header' \| 'Invalid or expired token' }` |
| body 不正 | 400 | `{ success:false, error:'Validation failed', details:[...] }` |
| uid / uuid がパスに使えない | 400 | `code: 'INVALID_UPLOAD_PATH'` |
| `GCS_BUCKET_NAME` 未設定 | 500 | `code: 'STORAGE_NOT_CONFIGURED'`（dev バケットへのフォールバックはしない） |
| 署名失敗（IAM 権限不足など） | 500 | `code: 'UPLOAD_SIGN_FAILED'`（詳細はサーバーログ） |

### ブラウザ側の使い方（Web チーム向け）

```ts
const { data } = await api.post('/api/uploads/sign', { kind: 'post', content_type: file.type, file_name: file.name, post_uuid });
await fetch(data.upload_url, { method: 'PUT', headers: data.headers, body: file }); // Content-Type は署名に含まれるので data.headers をそのまま使う
// 投稿作成: POST /api/tweets に media_urls=[data.public_url], media_metadata=[{ asset_uuid: data.asset_uuid, mime_type: data.content_type }], post_uuid
// アイコン: PATCH /api/users/:user_id/icon-url に user_icon_url = data.public_url + '?v=' + Date.now()（iOS と同じキャッシュバスター。固定パス上書きのため）
```

- 署名に `Content-Type` を含めているため、PUT の `Content-Type` ヘッダーは `content_type` と**完全一致**させる（違うと 403 SignatureDoesNotMatch）。
- 有効期限 10 分。期限切れは再発行する。
- HEIC はブラウザで表示できないので、Web では選択時に JPEG へ変換してから `image/jpeg` で送るのを推奨（許可はしてある）。
- `Cache-Control` は署名に含めていない（iOS のアイコン `immutable` 指定とは異なる）。必要になれば `extensionHeaders` に足す＝CORS の `responseHeader` にも追加が必要。

## 3. 前提 (a): バックエンド API の CORS（Cloud Run 環境変数）

API 自体の CORS は `ALLOWED_ORIGINS`（カンマ区切り）で制御している（`config/environment.ts`）。
Web のオリジンを含めてデプロイすること。

- dev: `ALLOWED_ORIGINS=http://localhost:3000,https://bouldering-app-dev.web.app`
- prod: 本番 Web のオリジンを追加

## 4. 前提 (b): 署名のための IAM（**変更はオーナーが実施**）

`uploadService.ts` は `storageService.ts` と同じく `new Storage()`（Application Default Credentials）で動く。
Cloud Run の実行サービスアカウント（dev: `cloud-run-backend-dev@bouldering-app-dev.iam.gserviceaccount.com`、
prod: `cloud-run-backend-prod@bouldering-app-prod-ca5d7.iam.gserviceaccount.com`）には秘密鍵が無いため、
V4 署名は **IAM Credentials API の `signBlob`** で行われる。以下が必要:

1. IAM Service Account Credentials API を有効化
   ```bash
   gcloud services enable iamcredentials.googleapis.com --project bouldering-app-dev
   ```
2. 実行 SA が **自分自身に対して** `roles/iam.serviceAccountTokenCreator` を持つ
   ```bash
   gcloud iam service-accounts add-iam-policy-binding \
     cloud-run-backend-dev@bouldering-app-dev.iam.gserviceaccount.com \
     --member="serviceAccount:cloud-run-backend-dev@bouldering-app-dev.iam.gserviceaccount.com" \
     --role="roles/iam.serviceAccountTokenCreator" \
     --project bouldering-app-dev
   ```
3. 実行 SA がバケットへ **オブジェクト作成**できる（署名が通っても、署名者に `storage.objects.create` が無いと PUT が 403）
   ```bash
   gcloud storage buckets add-iam-policy-binding gs://bouldering-app-media-dev \
     --member="serviceAccount:cloud-run-backend-dev@bouldering-app-dev.iam.gserviceaccount.com" \
     --role="roles/storage.objectAdmin"
   ```
   （既に削除ジョブ用に付与済みなら不要。`gcloud storage buckets get-iam-policy gs://bouldering-app-media-dev` で確認）

prod は SA 名・プロジェクト・バケット（`GCS_BUCKET_NAME` の実値。`.claude/docs/infrastructure.md` によれば `boulderingapp_tweets_media`、要確認）を読み替える。

補足:
- `FIREBASE_ADMIN_KEY`（Secret Manager 注入）はコード上どこでも読んでおらず（`config/firebase.ts` も ADC）、形式も未確認のため**再利用していない**。
  もし将来、鍵 JSON を `Storage({ credentials })` に渡す方式にするなら signBlob 権限は不要になるが、その SA にバケットの `storage.objects.create` が要る点は同じ。
- ローカル `npm run dev` で ADC がユーザー資格情報（`gcloud auth application-default login`）の場合、V4 署名は失敗する（`UPLOAD_SIGN_FAILED`）。
  ローカルで試すなら `gcloud auth application-default login --impersonate-service-account=cloud-run-backend-dev@...` を使う。

## 5. 前提 (c): バケットの CORS（**適用はオーナーが実施**）

ブラウザからの PUT はクロスオリジンなので、バケットに CORS ポリシーが必要。まだ適用していない。

`cors-web-uploads.json`（任意の場所に保存）:

```json
[
  {
    "origin": ["http://localhost:3000", "https://bouldering-app-dev.web.app"],
    "method": ["PUT"],
    "responseHeader": ["Content-Type"],
    "maxAgeSeconds": 3600
  }
]
```

適用（どちらか一方）:

```bash
gcloud storage buckets update gs://bouldering-app-media-dev --cors-file=cors-web-uploads.json
# または
gsutil cors set cors-web-uploads.json gs://bouldering-app-media-dev
```

確認:

```bash
gcloud storage buckets describe gs://bouldering-app-media-dev --format="json(cors_config)"
```

prod は `origin` を本番 Web のオリジンに、バケットを prod のものに読み替える。

## 6. 前提 (d): アップロード物が公開で読めること

バケットは「きめ細かい管理（fine-grained）」＋バケット IAM で `allUsers` に読み取り権限を付与済み（`docs/setup/google_cloud_setup_private.txt`）。
この場合、署名付き URL で置いたオブジェクトも `public_url` でそのまま読める（iOS が付けているオブジェクト ACL `allUsers:READER` は不要）。

もし `allUsers` のバケット IAM が無い環境（prod で未設定の可能性）なら、次のいずれか:
- バケット IAM に `allUsers` → `roles/storage.objectViewer` を付与（推奨。`gcloud storage buckets add-iam-policy-binding gs://<bucket> --member=allUsers --role=roles/storage.objectViewer`）
- または署名に `extensionHeaders: { 'x-goog-acl': 'public-read' }` を加え、ブラウザも同じヘッダーを送る（CORS の `responseHeader` に `x-goog-acl` を追加）

## 7. API 一覧スプレッドシートに貼る行

「イワノボリタイ_バックエンドAPI一覧」→ API一覧タブ。`No.` はシート側で振り直す（カテゴリ「アップロード」を新設、末尾に追加）。

| No. | カテゴリ | メソッド | パス | 概要 | 認証 | パスパラメータ | クエリ・ボディ | レスポンス(200) | 主なエラー | 定義場所 | 備考 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| (振り直し) | アップロード | POST | /api/uploads/sign | Web 向けに GCS への V4 署名付き PUT URL（10分有効）を発行 | 必須 | なし | body: kind("post"\|"icon"), content_type(image/jpeg\|png\|webp\|heic), file_name?(≤200, 拡張子判定のみ), post_uuid?(UUID, post で複数枚を束ねる) | { success, data: { kind, method:"PUT", upload_url, public_url, object_path, content_type, headers, expires_at, storage_prefix?, post_uuid?, asset_uuid? } } | 401 認証, 400 Validation failed / INVALID_UPLOAD_PATH, 500 STORAGE_NOT_CONFIGURED / UPLOAD_SIGN_FAILED | routes/uploads.ts:13 | オブジェクトパスは iOS と同一（v1/public/users/{uid}/posts/{yyyy}/{mm}/{post_uuid}/{asset_uuid}/original.{ext} / profile/icon.{ext}）。要: 実行SAの iam.serviceAccountTokenCreator＋バケット CORS（backend/docs-web-uploads.md） |

改訂履歴タブ: `2026-09-05 / 追加 / POST /api/uploads/sign（Web 向け署名付きアップロードURL） / feature/web-app / Claude`
