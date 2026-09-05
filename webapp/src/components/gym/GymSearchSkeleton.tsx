import { Skeleton } from "@/components/ui/Primitives";

/**
 * /gyms の読込中: カード 6 枚と地図の骨組み（レイアウトは GymSearch と同じ 2 ペイン）。
 * `app/gyms/loading.tsx` にはしない（あの位置に置くと /gyms/[id]・/gyms/area/* まで包んでしまい、
 * それらの notFound() が 200 になる＝ソフト 404 になるため）。page.tsx の Suspense fallback として使う。
 */
export function GymSearchSkeleton() {
  return (
    <div className="mx-auto w-full max-w-[1200px] px-5 md:px-8" aria-busy="true" aria-label="読み込み中">
      <div className="lg:grid lg:grid-cols-[440px_minmax(0,1fr)] lg:gap-6">
        <div className="flex flex-col gap-4 py-5 lg:py-6">
          <Skeleton className="h-11 w-full rounded-card" />
          <div className="flex gap-2">
            <Skeleton className="h-8 w-24 rounded-pill" />
            <Skeleton className="h-6 w-20" />
            <Skeleton className="h-6 w-14" />
            <Skeleton className="h-6 w-16" />
          </div>
          <Skeleton className="h-8 w-48 rounded-pill" />
          <div className="border-b border-crack pb-3">
            <Skeleton className="h-3 w-28" />
          </div>
          <div className="flex flex-col gap-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="flex gap-4 rounded-card bg-joint p-4">
                <Skeleton className="h-24 w-24 shrink-0 rounded-card" />
                <div className="flex flex-1 flex-col gap-2">
                  <Skeleton className="h-5 w-3/4" />
                  <Skeleton className="h-3 w-1/2" />
                  <div className="flex gap-1.5">
                    <Skeleton className="h-5 w-16" />
                    <Skeleton className="h-5 w-12" />
                  </div>
                  <div className="mt-auto flex gap-4">
                    <Skeleton className="h-6 w-12" />
                    <Skeleton className="h-6 w-12" />
                    <Skeleton className="h-6 w-16" />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
        <div className="hidden lg:block">
          <div className="sticky top-16 h-[calc(100vh-64px)] py-6">
            <Skeleton className="h-full w-full rounded-card" />
          </div>
        </div>
      </div>
    </div>
  );
}
