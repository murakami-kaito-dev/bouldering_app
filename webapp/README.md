# イワノボリタイ Web（webapp/）

Next.js 16（App Router / TypeScript / Tailwind v4）。iOS アプリと同じバックエンド API（Cloud Run）を使う。
設計の正典は [DESIGN.md](./DESIGN.md)、作業ルールは [CLAUDE.md](./CLAUDE.md)。

## 環境変数（`.env.local`・Git 非管理）

| 変数 | 値の所在 | 備考 |
|---|---|---|
| `NEXT_PUBLIC_API_BASE_URL` | dev: `https://bouldering-api-dev-cdd6zxnioq-an.a.run.app/api` | prod は本番切替時 |
| `NEXT_PUBLIC_SITE_URL` | 公開 URL（独自ドメイン取得後に差し替え） | sitemap / OG / canonical |
| `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` | GCP dev「Web Maps API Key - Dev」（HTTP リファラ制限） | ブラウザ公開値 |
| `NEXT_PUBLIC_FIREBASE_*` | Firebase dev の Web アプリ `boulderingapp-dev-web` | `firebase apps:sdkconfig WEB <appId>` |
| `NEXT_PUBLIC_ADSENSE_CLIENT` | AdSense 審査通過後の `ca-pub-…` | 空なら仮枠表示 |
| `NEXT_PUBLIC_APP_STORE_URL` | App Store のアプリ URL | 未設定なら既定値 |
| `NEXT_PUBLIC_APP_ENV` | `dev` / `prod` | prod 以外は noindex |

## 開発

```
npm install
npm run dev     # http://localhost:3000
npm run lint
npm run build   # standalone 出力（Docker / Cloud Run 用）
```

## デプロイ（dev）

`deploy/` 配下の手順（Cloud Build → Artifact Registry → Cloud Run `bouldering-web-dev` → Firebase Hosting の rewrite）。
独自ドメインは Firebase Hosting に接続する（手順は `.claude/docs/web-domain-setup.md`）。
