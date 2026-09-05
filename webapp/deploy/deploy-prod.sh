#!/usr/bin/env bash
# =============================================================================
# イワノボリタイ Web — prod デプロイ（プレースホルダ。独自ドメイン取得前は実行を拒否する）
#
#   webapp/.env.prod.local → Cloud Build → Cloud Run `bouldering-web-prod`（bouldering-app-prod-ca5d7）
#   → Firebase Hosting（prod 用サイト。未作成）
#
# 使い方:
#   deploy/deploy-prod.sh --dry-run          # チェックリストと（通れば）マスク済みコマンドを表示
#   deploy/deploy-prod.sh --confirm-prod     # 本番デプロイ（全ガードを通過した場合のみ）
#
# ガード（1 つでも満たさなければ止まる）:
#   1. webapp/.env.prod.local が存在する
#   2. NEXT_PUBLIC_SITE_URL が https の独自ドメイン（*.web.app / *.firebaseapp.com / *.run.app / localhost は不可）
#   3. NEXT_PUBLIC_API_BASE_URL が prod の API（bouldering-api-prod）
#   4. PROD_HOSTING_SITE が設定済み（prod 用 Hosting サイトを作ったらここに書く）
#   5. --confirm-prod が指定されている
#
# 手順の全体像は .claude/docs/web-domain-setup.md。
# =============================================================================
set -euo pipefail

# shellcheck source=_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

PROJECT="bouldering-app-prod-ca5d7"
ENV_NAME="prod"
SERVICE="bouldering-web-prod"
# prod 用 Firebase Hosting サイト ID（例: bouldering-app-prod）。作成後にここへ記入する。
PROD_HOSTING_SITE=""
ENV_FILE="${WEBAPP_DIR}/.env.prod.local"
AR_REPO="asia-northeast1-docker.pkg.dev/${PROJECT}/bouldering-app-docker-${ENV_NAME}"
MAX_INSTANCES=5
MEMORY="512Mi"

CONFIRM=false
WITH_HOSTING=true

print_checklist() {
  cat <<'EOF'

===== prod 公開チェックリスト（.claude/docs/web-domain-setup.md の要約） =====
 [ ] 独自ドメインを取得し、Firebase Hosting の prod サイトにカスタムドメインとして接続済み（SSL 発行済み）
 [ ] prod 用 Hosting サイトを作成し、firebase.json に target を追加、本スクリプトの PROD_HOSTING_SITE に記入
 [ ] webapp/.env.prod.local を作成（NEXT_PUBLIC_SITE_URL=https://<独自ドメイン>、API は bouldering-api-prod、
     Maps キーは「Web Maps API Key - Prod」、Firebase は prod プロジェクトの Web アプリ設定）
 [ ] Firebase Auth（prod）: 承認済みドメインに独自ドメインを追加、Google / Apple プロバイダ有効化
 [ ] Google Maps ブラウザキー（prod）の HTTP リファラに https://<独自ドメイン>/* を追加
 [ ] バックエンド bouldering-api-prod の ALLOWED_ORIGINS に https://<独自ドメイン> を追加して再デプロイ
 [ ] （直接 GCS へアップロードする実装がある場合のみ）prod バケットの CORS に独自ドメインを追加
 [ ] Artifact Registry `bouldering-app-docker-prod` が存在する（backend と共用）
 [ ] Cloud Run `bouldering-web-prod` の初回デプロイ後、Hosting rewrite → 独自ドメインで表示確認
 [ ] Search Console にドメインを登録し sitemap.xml を送信
 [ ] AdSense 申請（ads.txt・プライバシーポリシー・お問い合わせページ）→ 承認後に NEXT_PUBLIC_ADSENSE_CLIENT を設定して再デプロイ
 [ ] .claude/docs/deployment-log.md に記録
==============================================================================
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)      DRY_RUN=true ;;
    --confirm-prod) CONFIRM=true ;;
    --no-hosting)   WITH_HOSTING=false ;;
    -h|--help)      sed -n '2,20p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *)              die "不明な引数: $1（--help で使い方）" ;;
  esac
  shift
done

# ---- ガード ---------------------------------------------------------------------
if [[ ! -f "$ENV_FILE" ]]; then
  print_checklist
  die "prod はまだ実行できません: $ENV_FILE がありません"
fi
load_env_file "$ENV_FILE"
NEXT_PUBLIC_APP_ENV="$ENV_NAME"

site_url="${NEXT_PUBLIC_SITE_URL-}"
if [[ -z "$site_url" || "$site_url" != https://* \
   || "$site_url" == *.web.app* || "$site_url" == *.firebaseapp.com* \
   || "$site_url" == *.run.app* || "$site_url" == *localhost* ]]; then
  print_checklist
  die "prod はまだ実行できません: NEXT_PUBLIC_SITE_URL が独自ドメイン（https://…）ではありません（現在: $(mask "$site_url")）"
fi
[[ "${NEXT_PUBLIC_API_BASE_URL-}" == *"bouldering-api-prod"* ]] \
  || { print_checklist; die "NEXT_PUBLIC_API_BASE_URL が prod の API（bouldering-api-prod）ではありません"; }
if [[ -z "$PROD_HOSTING_SITE" ]]; then
  print_checklist
  die "prod はまだ実行できません: PROD_HOSTING_SITE が未設定です（prod 用 Hosting サイト作成後にこのファイルへ記入）"
fi
if ! $CONFIRM && ! $DRY_RUN; then
  print_checklist
  die "本番デプロイには --confirm-prod が必要です（確認用に --dry-run もあります）"
fi

print_env_summary
log "公開 URL: ${site_url}"

# ---- ビルド → デプロイ（dev と同じ流れ） ---------------------------------------
TAG="$(make_tag prod)"
IMAGE="${AR_REPO}/web:${TAG}"
log "イメージ: $IMAGE"

cloud_build "$PROJECT" "$ENV_NAME" "$TAG"
if ! $DRY_RUN; then
  gcloud artifacts docker images describe "$IMAGE" --project "$PROJECT" --format 'value(image_summary.digest)' >/dev/null \
    || die "Artifact Registry に $IMAGE が見つかりません"
fi
cloud_run_deploy "$PROJECT" "$SERVICE" "$IMAGE" "$MAX_INSTANCES" "$MEMORY"
verify_service "$PROJECT" "$SERVICE"
if $WITH_HOSTING; then
  hosting_deploy "$PROJECT" "$PROD_HOSTING_SITE"
fi

cat <<EOF

完了。記録を忘れずに:
  - .claude/docs/deployment-log.md に「イメージ ${TAG} → ${SERVICE} rev NNNNN」を追記
  - 独自ドメインで表示・ログイン・地図・投稿を確認
EOF
