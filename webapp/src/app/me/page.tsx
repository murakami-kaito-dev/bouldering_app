import type { Metadata } from "next";
import { getAllGyms } from "@/lib/api/gyms";
import { RequireAuth } from "@/components/auth/RequireAuth";
import { MePage, type SlimGym } from "@/components/user/MePage";

export const metadata: Metadata = {
  title: "マイページ",
  robots: { index: false, follow: false },
};

/** サーバー側でジム名の対応表（ホームジム表示用）だけ用意し、本人データはクライアントが BFF 経由で読む */
export default async function MeRoute() {
  let gyms: SlimGym[] = [];
  try {
    gyms = (await getAllGyms()).map((g) => ({ id: g.id, name: g.name }));
  } catch (e) {
    console.error("[me] getAllGyms failed", e);
  }
  return (
    <RequireAuth next="/me">
      <MePage gyms={gyms} />
    </RequireAuth>
  );
}
