import { Container, Eyebrow } from "@/components/ui/Primitives";
import { LinkButton } from "@/components/ui/Button";

/** 仮置き。ホームチームが差し替える */
export default function HomePage() {
  return (
    <Container className="flex flex-col gap-6 py-16">
      <Eyebrow>IWANOBORITAI · WEB</Eyebrow>
      <h1 className="text-display">ジムを探す。登る。残す。</h1>
      <LinkButton href="/gyms">ジムを探す</LinkButton>
    </Container>
  );
}
