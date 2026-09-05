import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Cloud Run（Docker）向けに最小構成で出力する
  output: "standalone",
  images: {
    remotePatterns: [
      // 投稿写真・ユーザーアイコン（GCS 公開バケット dev/prod）
      { protocol: "https", hostname: "storage.googleapis.com", pathname: "/bouldering-app-media-*/**" },
      // Google Places の写真（Places API (New) の media リダイレクト先）
      { protocol: "https", hostname: "lh3.googleusercontent.com" },
      { protocol: "https", hostname: "places.googleapis.com" },
    ],
  },
  // 本番以外では X-Robots-Tag で検索エンジンから隠す（dev の web.app が index されるのを防ぐ）
  async headers() {
    if (process.env.NEXT_PUBLIC_APP_ENV === "prod") return [];
    return [{ source: "/:path*", headers: [{ key: "X-Robots-Tag", value: "noindex, nofollow" }] }];
  },
};

export default nextConfig;
