import Link from "next/link";
import { Container, Eyebrow } from "@/components/ui/Primitives";
import { AppCta } from "./AppCta";
import { Logo } from "./SiteHeader";
import { REGIONS, PREFECTURE_SLUGS } from "@/lib/gym/prefectures";

const LEGAL = [
  { href: "https://murakami-kaito-dev.github.io/iwanoboritai-legal/terms/", label: "利用規約" },
  { href: "https://murakami-kaito-dev.github.io/iwanoboritai-legal/privacy/", label: "プライバシーポリシー" },
];

export function SiteFooter() {
  return (
    <footer className="mt-16 border-t border-crack bg-joint">
      <Container className="grid gap-10 py-12 md:grid-cols-[1.2fr_2fr]">
        <div className="flex flex-col gap-5">
          <Logo size="lg" />
          <p className="text-small text-dust max-w-[36ch]">
            日本全国のボルダリング・クライミングジムを探して、登った記録を残す。イワノボリタイの Web 版です。
          </p>
          <AppCta variant="compact" />
        </div>
        <div className="flex flex-col gap-6">
          <div>
            <Eyebrow className="mb-3">都道府県からジムを探す</Eyebrow>
            <div className="flex flex-col gap-2">
              {REGIONS.map((r) => (
                <div key={r.name} className="flex flex-wrap items-baseline gap-x-3 gap-y-1 text-small">
                  <span className="w-[6.5em] shrink-0 text-ash">{r.name}</span>
                  {r.prefectures.map((p) => (
                    <Link key={p} href={`/gyms/area/${PREFECTURE_SLUGS[p]}`} className="text-dust hover:text-chalk hover:underline underline-offset-4">
                      {p.replace(/[都府県]$/, "")}
                    </Link>
                  ))}
                </div>
              ))}
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-x-5 gap-y-2 text-small text-dust">
            {LEGAL.map((l) => (
              <a key={l.href} href={l.href} target="_blank" rel="noopener noreferrer" className="hover:text-chalk hover:underline underline-offset-4">
                {l.label}
              </a>
            ))}
            <Link href="/about" className="hover:text-chalk hover:underline underline-offset-4">
              イワノボリタイとは
            </Link>
          </div>
        </div>
      </Container>
      <div className="border-t border-crack">
        <Container className="flex h-12 items-center justify-between text-eyebrow text-ash">
          <span>© {new Date().getFullYear()} IWANOBORITAI</span>
          <span>ROCK & CHALK</span>
        </Container>
      </div>
    </footer>
  );
}
