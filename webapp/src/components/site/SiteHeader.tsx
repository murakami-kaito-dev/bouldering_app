import Link from "next/link";
import { Container } from "@/components/ui/Primitives";
import { HeaderAuth } from "./HeaderAuth";

/** ロゴ: 「イワノボリタイ」＋テープの点 */
export function Logo({ size = "md" }: { size?: "md" | "lg" }) {
  return (
    <span className={`inline-flex items-center gap-2 font-display font-bold tracking-[-0.01em] ${size === "lg" ? "text-[26px]" : "text-[19px]"}`}>
      <span className="tape bg-wall text-wall-ink px-[6px] py-[3px]" aria-hidden="true">
        <span className="text-[11px]">IWA</span>
      </span>
      <span className="text-chalk">イワノボリタイ</span>
    </span>
  );
}

const NAV = [
  { href: "/gyms", label: "ジムを探す" },
  { href: "/boul-log", label: "みんなのボル活" },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-40 border-b border-crack bg-rock/90 backdrop-blur-md">
      <Container className="flex h-14 items-center justify-between gap-4 md:h-16">
        <Link href="/" className="pressable rounded-tape" aria-label="イワノボリタイ ホーム">
          <Logo />
        </Link>
        <nav className="flex items-center gap-1 md:gap-2" aria-label="主要">
          {NAV.map((n) => (
            <Link
              key={n.href}
              href={n.href}
              className="pressable rounded-pill px-3 py-2 text-[14px] font-medium text-dust hover:bg-ledge hover:text-chalk md:px-4"
            >
              {n.label}
            </Link>
          ))}
          <HeaderAuth />
        </nav>
      </Container>
    </header>
  );
}
