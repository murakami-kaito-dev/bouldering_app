/**
 * 環境変数の一元取得（値の所在は webapp/README.md「環境変数」）。
 *
 * - NEXT_PUBLIC_* はブラウザにも配布される公開値（Maps ブラウザキー・Firebase Web 設定・AdSense ID など）。
 *   秘密（DB・サービスアカウント・Brevo 等）は絶対にここに置かない＝Web は常にバックエンド API 経由。
 * - 未設定でもビルドが落ちないよう既定値を持たせ、機能側で「未設定なら仮置き表示」に倒す。
 */
export const env = {
  /** バックエンド API（末尾に /api を含む） */
  apiBaseUrl:
    process.env.NEXT_PUBLIC_API_BASE_URL ??
    "https://bouldering-api-dev-cdd6zxnioq-an.a.run.app/api",
  /** 公開 URL（sitemap / OG / canonical 用。独自ドメイン取得後に差し替え） */
  siteUrl: process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000",
  /** Google Maps JavaScript API ブラウザキー（HTTP リファラ制限付き） */
  googleMapsApiKey: process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY ?? "",
  /** AdSense のパブリッシャー ID（例: ca-pub-XXXX）。空なら広告枠は仮置き表示 */
  adsenseClient: process.env.NEXT_PUBLIC_ADSENSE_CLIENT ?? "",
  /** Firebase Web 設定（Auth 用。公開値） */
  firebase: {
    apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY ?? "",
    authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN ?? "",
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? "",
    appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID ?? "",
    messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID ?? "",
    storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET ?? "",
  },
  /** App Store の URL（iOS アプリへの導線） */
  appStoreUrl:
    process.env.NEXT_PUBLIC_APP_STORE_URL ??
    "https://apps.apple.com/jp/app/id6753177257",
  /** App Store の数値 ID（apple-itunes-app メタ用） */
  appStoreId: process.env.NEXT_PUBLIC_APP_STORE_ID ?? "6753177257",
  /** 環境名（表示用。dev / prod） */
  appEnv: process.env.NEXT_PUBLIC_APP_ENV ?? "dev",
} as const;

export const isProd = env.appEnv === "prod";
export const hasFirebaseConfig = env.firebase.apiKey !== "" && env.firebase.appId !== "";
