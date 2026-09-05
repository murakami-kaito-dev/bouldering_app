import type { MetadataRoute } from "next";
import { env, isProd } from "@/lib/env";

/** 本番だけクロール許可。dev（web.app 等）は全面 disallow（next.config の X-Robots-Tag と二重に守る） */
export default function robots(): MetadataRoute.Robots {
  const base = env.siteUrl.replace(/\/$/, "");
  if (!isProd) {
    return { rules: { userAgent: "*", disallow: "/" } };
  }
  return {
    rules: { userAgent: "*", allow: "/", disallow: ["/api/"] },
    sitemap: `${base}/sitemap.xml`,
  };
}
