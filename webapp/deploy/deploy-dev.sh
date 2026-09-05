#!/usr/bin/env bash
# =============================================================================
# イワノボリタイ Web — dev デプロイ
#
#   webapp/.env.local → Cloud Build（Docker build / push）→ Cloud Run `bouldering-web-dev`
#   → （任意）Firebase Hosting `bouldering-app-dev`（https://bouldering-app-dev.web.app）
#
# 使い方（webapp/ でも、どこからでも可）:
#   deploy/deploy-dev.sh                 # ビルド → Cloud Run デプロイ（Hosting は手動）
#   deploy/deploy-dev.sh --with-hosting  # 上に加えて firebase deploy --only hosting も実行
#   deploy/deploy-dev.sh --dry-run       # 実行せず、マスク済みのコマンドを表示するだけ
#   deploy/deploy-dev.sh --tag dev-20260905-abc1234   # ビルドを飛ばし既存イメージをデプロイ
#
# 前提: gcloud / firebase CLI ログイン済み、Cloud Build・Artifact Registry・Cloud Run API 有効。
#       詳細は .claude/docs/commands.md「Web アプリ」。
# =============================================================================
set -euo pipefail

# shellcheck source=_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

PROJECT="bouldering-app-dev"
ENV_NAME="dev"
SERVICE="bouldering-web-dev"
HOSTING_SITE="bouldering-app-dev"
SITE_URL="https://bouldering-app-dev.web.app"
ENV_FILE="${WEBAPP_DIR}/.env.local"
AR_REPO="asia-northeast1-docker.pkg.dev/${PROJECT}/bouldering-app-docker-${ENV_NAME}"
MAX_INSTANCES=3
MEMORY="512Mi"

WITH_HOSTING=false
TAG=""

usage() { sed -n '2,17p' "${BASH_SOURCE[0]}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)      DRY_RUN=true ;;
    --with-hosting) WITH_HOSTING=true ;;
    --tag)          shift; TAG="${1:-}"; [[ -n "$TAG" ]] || die "--tag にはタグ名が必要です" ;;
    -h|--help)      usage; exit 0 ;;
    *)              die "不明な引数: $1（--help で使い方）" ;;
  esac
  shift
done

# ---- 1. 公開値の読み込み（.env.local。値は表示しない） ----------------------
load_env_file "$ENV_FILE"

# dev 固有の上書き（.env.local の値より優先）
NEXT_PUBLIC_SITE_URL="$SITE_URL"
NEXT_PUBLIC_APP_ENV="$ENV_NAME"

# 環境混在の安全弁: dev の Web が prod の API を向かないようにする
[[ -n "${NEXT_PUBLIC_API_BASE_URL-}" ]] || die "NEXT_PUBLIC_API_BASE_URL が .env.local にありません"
[[ "$NEXT_PUBLIC_API_BASE_URL" == *"bouldering-api-dev"* ]] \
  || die "NEXT_PUBLIC_API_BASE_URL が dev の API（bouldering-api-dev）ではありません。環境混在を防ぐため中断します"

[[ -n "${NEXT_PUBLIC_GOOGLE_MAPS_API_KEY-}" ]] || warn "NEXT_PUBLIC_GOOGLE_MAPS_API_KEY が空です（地図は仮置き表示になります）"
[[ -n "${NEXT_PUBLIC_FIREBASE_API_KEY-}" && -n "${NEXT_PUBLIC_FIREBASE_APP_ID-}" ]] \
  || warn "NEXT_PUBLIC_FIREBASE_API_KEY / APP_ID が空です（ログインは無効になります）"

print_env_summary

# ---- 2. タグ決定 --------------------------------------------------------------
SKIP_BUILD=false
if [[ -n "$TAG" ]]; then
  SKIP_BUILD=true
  log "--tag 指定: ビルドをスキップして既存イメージを使います: $TAG"
else
  TAG="$(make_tag dev)"
fi
IMAGE="${AR_REPO}/web:${TAG}"
log "イメージ: $IMAGE"

# ---- 3. Cloud Build（Docker build → Artifact Registry push） ------------------
if ! $SKIP_BUILD; then
  cloud_build "$PROJECT" "$ENV_NAME" "$TAG"
fi

# push 結果の確認（タグが意図どおり付いたか。dry-run はスキップ）
if ! $DRY_RUN; then
  gcloud artifacts docker images describe "$IMAGE" --project "$PROJECT" --format 'value(image_summary.digest)' >/dev/null \
    || die "Artifact Registry に $IMAGE が見つかりません（ビルド失敗？）"
  log "Artifact Registry にタグ ${TAG} を確認"
fi

# ---- 4. Cloud Run デプロイ ----------------------------------------------------
cloud_run_deploy "$PROJECT" "$SERVICE" "$IMAGE" "$MAX_INSTANCES" "$MEMORY"
verify_service "$PROJECT" "$SERVICE"

# ---- 5. Firebase Hosting（rewrite → Cloud Run） -------------------------------
if $WITH_HOSTING; then
  hosting_deploy "$PROJECT" "$HOSTING_SITE"
  log "Hosting: ${SITE_URL}"
else
  cat <<EOF

次の一手（Hosting の rewrite を更新する場合。firebase.json 変更時・初回のみ必要）:
  cd ${REPO_ROOT} && firebase deploy --only hosting:${HOSTING_SITE} --project ${PROJECT}
  → ${SITE_URL}
EOF
fi

cat <<EOF

完了。記録を忘れずに:
  - .claude/docs/deployment-log.md に「イメージ ${TAG} → ${SERVICE} rev NNNNN」を追記
  - タグ確認: gcloud artifacts docker images list ${AR_REPO}/web --include-tags --project ${PROJECT} --sort-by=~UPDATE_TIME | head -5
EOF
