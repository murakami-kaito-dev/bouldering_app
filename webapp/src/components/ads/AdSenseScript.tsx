import Script from "next/script";
import { env } from "@/lib/env";

/** AdSense のローダー。パブリッシャー ID 未設定のときは何も出さない（審査前・dev） */
export function AdSenseScript() {
  if (!env.adsenseClient) return null;
  return (
    <Script
      id="adsense-loader"
      async
      strategy="afterInteractive"
      src={`https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${env.adsenseClient}`}
      crossOrigin="anonymous"
    />
  );
}
