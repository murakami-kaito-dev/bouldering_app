import type { Metadata } from "next";
import { getAllGyms } from "@/lib/api/gyms";
import { RequireAuth } from "@/components/auth/RequireAuth";
import { PostForm } from "@/components/post/PostForm";
import type { PickerGym } from "@/components/post/GymCombobox";

export const metadata: Metadata = {
  title: "ボル活を投稿",
  robots: { index: false, follow: false },
};

/** サーバー側で全ジムの軽い一覧を用意し、フォーム本体はクライアント（要ログイン） */
export default async function PostRoute({ searchParams }: { searchParams: Promise<{ gym?: string | string[] }> }) {
  const sp = await searchParams;
  const gymParam = Array.isArray(sp.gym) ? sp.gym[0] : sp.gym;
  const initialGymId = gymParam && /^\d+$/.test(gymParam) ? Number.parseInt(gymParam, 10) : null;

  let gyms: PickerGym[] = [];
  try {
    gyms = (await getAllGyms()).map((g) => ({ id: g.id, name: g.name, prefecture: g.prefecture, city: g.city }));
  } catch (e) {
    console.error("[post] getAllGyms failed", e);
  }
  const next = initialGymId ? `/post?gym=${initialGymId}` : "/post";
  return (
    <RequireAuth next={next}>
      <PostForm gyms={gyms} initialGymId={initialGymId} />
    </RequireAuth>
  );
}
