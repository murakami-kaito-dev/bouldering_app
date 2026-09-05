import { env } from "@/lib/env";

/**
 * AdSense の ads.txt。パブリッシャー ID（ca-pub-XXXX）が設定されていれば正規の 1 行を返し、
 * 未設定（審査前・dev）ならコメント行だけを返す。
 */
export const dynamic = "force-static";

export function GET() {
  const pub = env.adsenseClient.replace(/^ca-pub-/, "").trim();
  const body = pub ? `google.com, pub-${pub}, DIRECT, f08c47fec0942fa0\n` : "# AdSense not configured\n";
  return new Response(body, {
    headers: { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "public, max-age=86400" },
  });
}
