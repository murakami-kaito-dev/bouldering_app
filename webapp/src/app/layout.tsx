import type { Metadata, Viewport } from "next";
import { Barlow_Condensed, Noto_Sans_JP, Zen_Kaku_Gothic_New } from "next/font/google";
import "./globals.css";
import { env, isProd } from "@/lib/env";
import { SiteHeader } from "@/components/site/SiteHeader";
import { SiteFooter } from "@/components/site/SiteFooter";
import { AdSenseScript } from "@/components/ads/AdSenseScript";

const zen = Zen_Kaku_Gothic_New({ weight: ["500", "700"], subsets: ["latin"], variable: "--font-zen", display: "swap", preload: false });
const barlow = Barlow_Condensed({ weight: ["500", "600", "700"], subsets: ["latin"], variable: "--font-barlow", display: "swap" });
const noto = Noto_Sans_JP({ weight: ["400", "500"], subsets: ["latin"], variable: "--font-noto", display: "swap", preload: false });

const SITE_NAME = "イワノボリタイ";
const DESCRIPTION = "全国のボルダリング・クライミングジムを地図と条件で探せる。営業時間・料金・種別（ボルダリング／リード／スピード）と、みんなのボル活記録。";

export const metadata: Metadata = {
  metadataBase: new URL(env.siteUrl),
  title: { default: `${SITE_NAME} | ボルダリングジム検索`, template: `%s | ${SITE_NAME}` },
  description: DESCRIPTION,
  applicationName: SITE_NAME,
  openGraph: { type: "website", siteName: SITE_NAME, locale: "ja_JP" },
  twitter: { card: "summary_large_image" },
  robots: isProd ? { index: true, follow: true } : { index: false, follow: false },
  other: { "apple-itunes-app": `app-id=${env.appStoreId}` },
};

export const viewport: Viewport = {
  themeColor: "#15171B",
  colorScheme: "dark",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="ja" className={`${zen.variable} ${barlow.variable} ${noto.variable} h-full`}>
      <body className="flex min-h-full flex-col">
        <SiteHeader />
        <main className="flex-1">{children}</main>
        <SiteFooter />
        <AdSenseScript />
      </body>
    </html>
  );
}
