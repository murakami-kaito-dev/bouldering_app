import type { Metadata } from "next";
import { Suspense } from "react";
import { LoginScreen } from "@/components/auth/LoginScreen";
import { Container, Skeleton } from "@/components/ui/Primitives";

export const metadata: Metadata = {
  title: "ログイン",
  description: "Google または Apple でログインして、ボル活の投稿とイキタイ登録を。ジム検索はログインなしで使えます。",
  robots: { index: false, follow: true },
};

export default function LoginPage() {
  return (
    <Suspense
      fallback={
        <Container narrow className="flex flex-col gap-6 py-12">
          <Skeleton className="h-3 w-16" />
          <Skeleton className="h-9 w-40" />
          <Skeleton className="h-64 w-full" />
        </Container>
      }
    >
      <LoginScreen />
    </Suspense>
  );
}
