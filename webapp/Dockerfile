# syntax=docker/dockerfile:1
# =============================================================================
# イワノボリタイ Web（Next.js 16 / output: "standalone"）— Cloud Run 用イメージ
#
# 3 ステージ構成:
#   deps    … npm ci（lockfile 固定）
#   builder … next build（NEXT_PUBLIC_* を埋め込む）
#   runner  … .next/standalone だけを非 root ユーザーで実行（最小イメージ）
#
# 重要:
#   - NEXT_PUBLIC_* は `next build` 時に JS バンドルへ「文字列として埋め込まれる」公開値。
#     実行時の環境変数（Cloud Run の --set-env-vars）では反映されないため、
#     必ず `docker build --build-arg` で渡す（deploy/cloudbuild.yaml が渡す）。
#   - 秘密（DB・サービスアカウント等）はこのイメージに一切含めない。Web は常にバックエンド API 経由。
#   - ローカル開発は Node 26 だが、Cloud Run イメージは LTS（22）に固定する。
#   - Cloud Run は $PORT（既定 8080）で待ち受ける必要がある。HOSTNAME=0.0.0.0 も必須
#     （standalone の server.js は既定で localhost に bind するため）。
# =============================================================================

ARG NODE_IMAGE=node:22-alpine

# ---- deps -------------------------------------------------------------------
FROM ${NODE_IMAGE} AS deps
# alpine(musl) で sharp 等のネイティブ依存を動かすための互換レイヤ
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

# ---- builder ----------------------------------------------------------------
FROM ${NODE_IMAGE} AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# src/lib/env.ts が参照する NEXT_PUBLIC_* を全て build-arg で受ける（値は公開値のみ）
ARG NEXT_PUBLIC_API_BASE_URL
ARG NEXT_PUBLIC_SITE_URL
ARG NEXT_PUBLIC_GOOGLE_MAPS_API_KEY
ARG NEXT_PUBLIC_FIREBASE_API_KEY
ARG NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN
ARG NEXT_PUBLIC_FIREBASE_PROJECT_ID
ARG NEXT_PUBLIC_FIREBASE_APP_ID
ARG NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID
ARG NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET
ARG NEXT_PUBLIC_ADSENSE_CLIENT
ARG NEXT_PUBLIC_APP_ENV
ARG NEXT_PUBLIC_APP_STORE_URL
ARG NEXT_PUBLIC_APP_STORE_ID

ENV NEXT_TELEMETRY_DISABLED=1

# 空文字で渡された変数は「未設定」として扱う（env.ts の `??` 既定値を生かすため、
# ENV で固定せず、値のあるものだけ export してから next build する）
RUN set -eu; \
    for k in \
      NEXT_PUBLIC_API_BASE_URL NEXT_PUBLIC_SITE_URL NEXT_PUBLIC_GOOGLE_MAPS_API_KEY \
      NEXT_PUBLIC_FIREBASE_API_KEY NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN NEXT_PUBLIC_FIREBASE_PROJECT_ID \
      NEXT_PUBLIC_FIREBASE_APP_ID NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET \
      NEXT_PUBLIC_ADSENSE_CLIENT NEXT_PUBLIC_APP_ENV NEXT_PUBLIC_APP_STORE_URL NEXT_PUBLIC_APP_STORE_ID; do \
      eval "v=\${$k:-}"; \
      if [ -n "$v" ]; then export "$k=$v"; else unset "$k" 2>/dev/null || true; fi; \
    done; \
    echo "build: NEXT_PUBLIC_APP_ENV=${NEXT_PUBLIC_APP_ENV:-<unset>} NEXT_PUBLIC_SITE_URL=${NEXT_PUBLIC_SITE_URL:-<unset>}"; \
    npm run build

# ---- runner -----------------------------------------------------------------
FROM ${NODE_IMAGE} AS runner
WORKDIR /app

ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=8080 \
    HOSTNAME=0.0.0.0

RUN addgroup --system --gid 1001 nodejs \
 && adduser --system --uid 1001 nextjs

# public/ と .next/static は standalone に自動では含まれないので手で載せる
# （Next 公式 docs「output: standalone」の手順どおり。server.js がそのまま配信する）
COPY --from=builder /app/public ./public
RUN mkdir .next && chown nextjs:nodejs .next
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 8080

CMD ["node", "server.js"]
