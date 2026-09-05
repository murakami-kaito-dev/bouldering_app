import { Container, Eyebrow } from "@/components/ui/Primitives";
import { LinkButton } from "@/components/ui/Button";

export default function NotFound() {
  return (
    <Container className="flex min-h-[60vh] flex-col items-start justify-center gap-4 py-16">
      <Eyebrow>404 · NOT FOUND</Eyebrow>
      <h1 className="text-h1">このホールドはありません</h1>
      <p className="text-dust max-w-[40ch]">ページが移動したか、URL が間違っています。ジム一覧から探し直せます。</p>
      <LinkButton href="/gyms">ジムを探す</LinkButton>
    </Container>
  );
}
