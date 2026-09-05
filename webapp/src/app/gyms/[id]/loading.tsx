import { Container, Skeleton } from "@/components/ui/Primitives";

/** 詳細ページの骨組み（ヒーロー・写真・タブ・右レール） */
export default function GymDetailLoading() {
  return (
    <Container className="py-8 md:py-12" aria-busy="true" aria-label="読み込み中">
      <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_360px] lg:gap-12">
        <div className="flex min-w-0 flex-col gap-8">
          <Skeleton className="h-3 w-40" />
          <div className="flex flex-col gap-6">
            <div className="flex flex-col gap-3">
              <Skeleton className="h-9 w-3/4 md:h-11" />
              <div className="flex gap-2">
                <Skeleton className="h-5 w-20" />
                <Skeleton className="h-5 w-16" />
                <Skeleton className="h-5 w-28" />
              </div>
              <Skeleton className="h-4 w-32" />
            </div>
            <div className="flex flex-wrap gap-10 rounded-card bg-joint px-5 py-5 md:px-6">
              {[0, 1, 2].map((i) => (
                <div key={i} className="flex flex-col gap-2">
                  <Skeleton className="h-3 w-14" />
                  <Skeleton className="h-10 w-24 md:h-12" />
                </div>
              ))}
            </div>
          </div>
          <div className="flex gap-3 overflow-hidden">
            {[0, 1, 2].map((i) => (
              <Skeleton key={i} className="aspect-[4/3] w-[78%] shrink-0 rounded-card md:w-[320px]" />
            ))}
          </div>
          <div className="flex flex-col gap-6">
            <div className="flex gap-2 border-b border-crack pb-4">
              <Skeleton className="h-8 w-24" />
              <Skeleton className="h-8 w-24" />
            </div>
            <div className="flex flex-col divide-y divide-crack">
              {[0, 1, 2, 3].map((i) => (
                <div key={i} className="grid gap-2 py-5 md:grid-cols-[7em_minmax(0,1fr)] md:gap-6">
                  <Skeleton className="h-3 w-12" />
                  <Skeleton className="h-5 w-2/3" />
                </div>
              ))}
            </div>
          </div>
        </div>
        <aside className="flex flex-col gap-4 lg:sticky lg:top-20 lg:self-start" aria-hidden="true">
          <Skeleton className="h-[284px] rounded-card" />
          <Skeleton className="h-[172px] rounded-card" />
          <Skeleton className="min-h-[250px] rounded-card" />
        </aside>
      </div>
    </Container>
  );
}
