"use client";

import { useRouter } from "next/navigation";
import { useEffect, type ReactNode } from "react";
import { useAuth } from "@/lib/auth";
import { Container, Skeleton } from "@/components/ui/Primitives";

/**
 * クライアント側のログインゲート。
 * - loading   : 骨組み（ページ相当の高さを確保）
 * - signedOut : /login?next=<現在のパス> へ
 * - signedIn  : children
 */
export function RequireAuth({ next, children }: { next: string; children: ReactNode }) {
  const { status } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (status === "signedOut") router.replace(`/login?next=${encodeURIComponent(next)}`);
  }, [status, next, router]);

  if (status !== "signedIn") {
    return (
      <Container className="flex flex-col gap-6 py-12" aria-busy="true">
        <Skeleton className="h-3 w-24" />
        <Skeleton className="h-9 w-56" />
        <Skeleton className="h-40 w-full" />
        <Skeleton className="h-28 w-full" />
      </Container>
    );
  }
  return <>{children}</>;
}
