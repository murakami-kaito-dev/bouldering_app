import type { Metadata } from "next";
import { getAllGyms } from "@/lib/api/gyms";
import { RequireAuth } from "@/components/auth/RequireAuth";
import { ProfileSettings } from "@/components/user/ProfileSettings";
import type { PickerGym } from "@/components/post/GymCombobox";

export const metadata: Metadata = {
  title: "設定",
  robots: { index: false, follow: false },
};

/** ホームジム選択用にジム一覧（軽い形）だけサーバーで用意し、本人データはクライアントが BFF 経由で読む */
export default async function MeSettingsRoute() {
  let gyms: PickerGym[] = [];
  try {
    gyms = (await getAllGyms()).map((g) => ({ id: g.id, name: g.name, prefecture: g.prefecture, city: g.city }));
  } catch (e) {
    console.error("[me/settings] getAllGyms failed", e);
  }
  return (
    <RequireAuth next="/me/settings">
      <ProfileSettings gyms={gyms} />
    </RequireAuth>
  );
}
