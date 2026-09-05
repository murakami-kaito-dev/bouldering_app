import type { Metadata } from "next";
import Link from "next/link";
import { Container, Eyebrow, SectionHeader } from "@/components/ui/Primitives";
import { Tape } from "@/components/ui/Tape";
import { AppCta } from "@/components/site/AppCta";

export const metadata: Metadata = {
  title: "イワノボリタイとは",
  description: "イワノボリタイは、全国のボルダリング・クライミングジムを探し、登った記録（ボル活）を残すためのアプリと Web サイトです。",
  alternates: { canonical: "/about" },
};

/** フッターと同じ URL（SiteFooter.tsx の LEGAL と揃える） */
const LEGAL = [
  { href: "https://murakami-kaito-dev.github.io/iwanoboritai-legal/terms/", label: "利用規約" },
  { href: "https://murakami-kaito-dev.github.io/iwanoboritai-legal/privacy/", label: "プライバシーポリシー" },
] as const;

const FEATURES = [
  {
    tape: "SEARCH",
    tone: "wall",
    title: "ジム検索",
    body: "47 都道府県のジムを、営業時間・料金・種別（ボルダリング／リード／スピード）で絞り込み。Web では地図とリストを並べて比べられます。",
    href: "/gyms",
    link: "ジムを探す",
  },
  {
    tape: "BOUL LOG",
    tone: "yellow",
    title: "ボル活の記録",
    body: "登った日・ジム・写真を「ボル活」として投稿。みんなのボル活で、他のクライマーの記録も読めます。",
    href: "/boul-log",
    link: "みんなのボル活を見る",
  },
  {
    tape: "IKITAI",
    tone: "green",
    title: "イキタイ",
    body: "気になるジムをイキタイに登録。イキタイの数はジムの人気の目安にもなります（登録はアプリから）。",
    href: null,
    link: null,
  },
] as const;

export default function AboutPage() {
  return (
    <Container narrow className="flex flex-col gap-12 py-10 md:py-14">
      <header className="flex flex-col gap-3">
        <Eyebrow>ABOUT</Eyebrow>
        <h1 className="text-h1">イワノボリタイとは</h1>
        <span className="tape-rule" aria-hidden="true" />
        <p className="text-[16px] leading-[1.7] text-dust">
          イワノボリタイは、全国のボルダリング・クライミングジムを探して、登った記録を残すための iOS
          アプリと、その Web 版です。ジムの検索と「みんなのボル活」は Web でも読めます。
        </p>
      </header>

      <section className="flex flex-col gap-6" aria-labelledby="about-features">
        <SectionHeader eyebrow="WHAT IT DOES" title={<span id="about-features">できること</span>} />
        <ul className="flex flex-col gap-4">
          {FEATURES.map((f) => (
            <li key={f.title} className="flex flex-col gap-2 rounded-card bg-joint p-5">
              <div className="flex items-center gap-3">
                <Tape tone={f.tone}>{f.tape}</Tape>
                <h3 className="text-h3">{f.title}</h3>
              </div>
              <p className="text-small text-dust">{f.body}</p>
              {f.href ? (
                <Link href={f.href} className="w-fit text-[14px] font-bold text-wall hover:underline underline-offset-4">
                  {f.link}
                </Link>
              ) : null}
            </li>
          ))}
        </ul>
      </section>

      <AppCta />

      <section className="flex flex-col gap-4" aria-labelledby="about-legal">
        <SectionHeader eyebrow="LEGAL" title={<span id="about-legal">規約・ポリシー</span>} />
        <ul className="flex flex-wrap gap-x-6 gap-y-2">
          {LEGAL.map((l) => (
            <li key={l.href}>
              <a href={l.href} target="_blank" rel="noopener noreferrer" className="text-chalk hover:underline underline-offset-4">
                {l.label}
              </a>
            </li>
          ))}
        </ul>
      </section>

      <section className="flex flex-col gap-4" aria-labelledby="about-operator">
        <SectionHeader eyebrow="OPERATOR" title={<span id="about-operator">運営</span>} />
        <p className="text-dust">運営者情報は準備中です。</p>
      </section>
    </Container>
  );
}
