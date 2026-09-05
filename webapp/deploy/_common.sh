# shellcheck shell=bash
# =============================================================================
# deploy-dev.sh / deploy-prod.sh の共通処理。単体では実行しない（source 専用）。
#
# 方針:
#   - .env.local 等の値は絶対に画面へ出さない（長さだけ出す）。
#   - macOS 標準の bash 3.2 でも動くように連想配列は使わない。
#   - `run` を通した処理は --dry-run で「マスク済みのコマンド」を表示するだけになる。
# =============================================================================

REGION="asia-northeast1"
WEBAPP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${WEBAPP_DIR}/.." && pwd)"

# src/lib/env.ts が参照する公開値（順序は cloudbuild.yaml と合わせてある）
PUBLIC_KEYS="NEXT_PUBLIC_API_BASE_URL NEXT_PUBLIC_SITE_URL NEXT_PUBLIC_GOOGLE_MAPS_API_KEY \
NEXT_PUBLIC_FIREBASE_API_KEY NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN NEXT_PUBLIC_FIREBASE_PROJECT_ID \
NEXT_PUBLIC_FIREBASE_APP_ID NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET \
NEXT_PUBLIC_ADSENSE_CLIENT NEXT_PUBLIC_APP_ENV NEXT_PUBLIC_APP_STORE_URL NEXT_PUBLIC_APP_STORE_ID"

DRY_RUN=false

log()  { printf '\033[1;34m[deploy]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

# 値をマスクして表示用にする（長さだけ見せる）
mask() {
  local v="${1-}"
  if [[ -z "$v" ]]; then printf '<empty>'; else printf '<set:%d chars>' "${#v}"; fi
}

# NEXT_PUBLIC_* → cloudbuild.yaml の substitution 名
sub_name() {
  case "$1" in
    NEXT_PUBLIC_API_BASE_URL)                 echo _API_BASE_URL ;;
    NEXT_PUBLIC_SITE_URL)                     echo _SITE_URL ;;
    NEXT_PUBLIC_GOOGLE_MAPS_API_KEY)          echo _MAPS_KEY ;;
    NEXT_PUBLIC_FIREBASE_API_KEY)             echo _FIREBASE_API_KEY ;;
    NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN)         echo _FIREBASE_AUTH_DOMAIN ;;
    NEXT_PUBLIC_FIREBASE_PROJECT_ID)          echo _FIREBASE_PROJECT_ID ;;
    NEXT_PUBLIC_FIREBASE_APP_ID)              echo _FIREBASE_APP_ID ;;
    NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID) echo _FIREBASE_MESSAGING_SENDER_ID ;;
    NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET)      echo _FIREBASE_STORAGE_BUCKET ;;
    NEXT_PUBLIC_ADSENSE_CLIENT)               echo _ADSENSE_CLIENT ;;
    NEXT_PUBLIC_APP_ENV)                      echo _APP_ENV ;;
    NEXT_PUBLIC_APP_STORE_URL)                echo _APP_STORE_URL ;;
    NEXT_PUBLIC_APP_STORE_ID)                 echo _APP_STORE_ID ;;
    *) die "unknown key: $1" ;;
  esac
}

# KEY=VALUE 形式の env ファイルを読み、NEXT_PUBLIC_* だけをシェル変数に取り込む（export はしない）
# - 空行・# コメント行・`export KEY=...` 形式・前後の "..." / '...' に対応
# - 値は一切表示しない
load_env_file() {
  local file="$1" line key val
  [[ -f "$file" ]] || die "env ファイルがありません: $file"
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=(.*)$ ]] || continue
    key="${BASH_REMATCH[2]}"
    val="${BASH_REMATCH[3]}"
    # 前後の空白を除去
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    # 囲みクォートを除去
    if [[ "$val" =~ ^\"(.*)\"$ ]]; then val="${BASH_REMATCH[1]}"; fi
    if [[ "$val" =~ ^\'(.*)\'$ ]]; then val="${BASH_REMATCH[1]}"; fi
    [[ "$key" == NEXT_PUBLIC_* ]] || continue
    printf -v "$key" '%s' "$val"
  done < "$file"
}

# 取り込んだ公開値の一覧を（マスクして）表示
print_env_summary() {
  local k
  log "ビルドに埋め込む NEXT_PUBLIC_*（値はマスク）:"
  for k in $PUBLIC_KEYS; do
    printf '   %-42s %s\n' "$k" "$(mask "${!k-}")"
  done
}

# cloudbuild.yaml 用の --substitutions 文字列を作る
#   $1 = _ENV, $2 = _TAG。結果は SUBS（実値）と SUBS_MASKED（表示用）に入る
build_substitutions() {
  local env_name="$1" tag="$2" k v
  SUBS="_ENV=${env_name},_TAG=${tag}"
  SUBS_MASKED="$SUBS"
  for k in $PUBLIC_KEYS; do
    v="${!k-}"
    # gcloud の --substitutions はカンマ区切りなので値にカンマがあると壊れる
    [[ "$v" == *,* ]] && die "$k にカンマが含まれています（--substitutions で渡せません）"
    SUBS+=",$(sub_name "$k")=${v}"
    SUBS_MASKED+=",$(sub_name "$k")=$(mask "$v")"
  done
}

# Cloud Build へアップロードする前に .gcloudignore を用意する
# （無いと .env.local 等がアップロードされ得る。backend と同じく Git 管理外のファイル）
ensure_gcloudignore() {
  local f="${WEBAPP_DIR}/.gcloudignore"
  if [[ ! -f "$f" ]]; then
    if $DRY_RUN; then
      log "[dry-run] .gcloudignore が無いので作成します: $f"
      return 0
    fi
    cat > "$f" <<'EOF'
# gcloud builds submit のアップロード対象から除外（deploy/_common.sh が生成。Git 管理外）
.git
.gcloudignore
node_modules/
.next/
out/
coverage/
.env*
deploy/
hosting-public/
*.md
.DS_Store
EOF
    log ".gcloudignore を作成しました: $f"
  fi
  grep -q '^\.env\*' "$f" || die ".gcloudignore に '.env*' がありません（秘密混入防止のため中断）: $f"
}

# コマンド実行ラッパ。$1 = 表示用（マスク済み）文字列、以降 = 実コマンド
run() {
  local shown="$1"; shift
  if $DRY_RUN; then
    printf '\033[2m[dry-run]\033[0m %s\n' "$shown"
    return 0
  fi
  printf '\033[1m+ %s\033[0m\n' "$shown"
  "$@"
}

# イメージタグ: <prefix>-YYYYMMDD-<git 短縮 SHA>[-dirty]
make_tag() {
  local prefix="$1" sha dirty=""
  sha="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
  if [[ -n "$(git -C "$REPO_ROOT" status --porcelain -- webapp)" ]]; then
    dirty="-dirty"
    warn "webapp/ に未コミットの変更があります。タグに -dirty を付けます（SHA だけでは中身を特定できないため）"
  fi
  printf '%s-%s-%s%s' "$prefix" "$(date +%Y%m%d)" "$sha" "$dirty"
}

# Cloud Build → Artifact Registry。$1 = project, $2 = env(dev/prod), $3 = tag
cloud_build() {
  local project="$1" env_name="$2" tag="$3"
  build_substitutions "$env_name" "$tag"
  ensure_gcloudignore
  run "gcloud builds submit --config deploy/cloudbuild.yaml --substitutions ${SUBS_MASKED} --project ${project} ." \
    bash -c 'cd "$1" && gcloud builds submit --config deploy/cloudbuild.yaml --substitutions "$2" --project "$3" .' _ \
    "$WEBAPP_DIR" "$SUBS" "$project"
}

# Cloud Run デプロイ。$1 = project, $2 = service, $3 = image, $4 = max-instances, $5 = memory
cloud_run_deploy() {
  local project="$1" service="$2" image="$3" max_instances="$4" memory="$5"
  run "gcloud run deploy ${service} --image ${image} --region ${REGION} --project ${project} --allow-unauthenticated --port 8080 --memory ${memory} --cpu 1 --min-instances 0 --max-instances ${max_instances} --quiet" \
    gcloud run deploy "$service" \
      --image "$image" \
      --region "$REGION" \
      --project "$project" \
      --platform managed \
      --allow-unauthenticated \
      --port 8080 \
      --memory "$memory" \
      --cpu 1 \
      --min-instances 0 \
      --max-instances "$max_instances" \
      --quiet
}

# デプロイ後の疎通確認（dry-run 時はスキップ）
verify_service() {
  local project="$1" service="$2" url code
  if $DRY_RUN; then
    log "[dry-run] 疎通確認はスキップ（gcloud run services describe → curl）"
    return 0
  fi
  url="$(gcloud run services describe "$service" --region "$REGION" --project "$project" --format 'value(status.url)')"
  log "Cloud Run URL: $url"
  code="$(curl -sS -o /dev/null -w '%{http_code}' "$url/" || echo 000)"
  log "GET / → HTTP $code"
  [[ "$code" == "200" ]] || warn "トップページが 200 ではありません。ログ: gcloud run services logs read $service --region $REGION --project $project --limit 50"
  # 本番以外は noindex ヘッダが付いていることを確認
  curl -sSI "$url/" | grep -i '^x-robots-tag' || true
  SERVICE_URL="$url"
}

# Firebase Hosting デプロイ（firebase.json はリポジトリ直下）。$1 = project, $2 = site
hosting_deploy() {
  local project="$1" site="$2"
  run "(cd ${REPO_ROOT} && firebase deploy --only hosting:${site} --project ${project})" \
    bash -c 'cd "$1" && firebase deploy --only "hosting:$2" --project "$3"' _ "$REPO_ROOT" "$site" "$project"
}
