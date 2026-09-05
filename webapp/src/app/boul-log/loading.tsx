import { Container, Eyebrow, Skeleton } from "@/components/ui/Primitives";
import { TweetSkeleton } from "@/components/tweet/TweetFeed";

export default function BoulLogLoading() {
  return (
    <Container narrow className="flex flex-col gap-8 py-10 md:py-14" aria-busy="true">
      <header className="flex flex-col gap-3">
        <Eyebrow>BOUL LOG</Eyebrow>
        <h1 className="text-h1">みんなのボル活</h1>
        <span className="tape-rule" aria-hidden="true" />
        <Skeleton className="h-5 w-[60%]" />
      </header>
      <div className="flex flex-col gap-4">
        {[0, 1, 2, 3].map((i) => (
          <TweetSkeleton key={i} />
        ))}
      </div>
    </Container>
  );
}
