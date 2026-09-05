import { notFound } from "next/navigation";
import { getGym } from "@/lib/api/gyms";
import { parseGymId } from "@/components/gym/detail/gymId";

/**
 * 存在チェックだけをレイアウトで行う（page の loading 境界より外側なので、ストリーミング開始前に 404 を確定できる）。
 * getGym は 10 分キャッシュ＋同一リクエスト内で page 側と重複排除されるため追加コストはほぼ無い。
 */
export default async function GymDetailLayout({ params, children }: LayoutProps<"/gyms/[id]">) {
  const { id } = await params;
  const n = parseGymId(id);
  if (n === null || !(await getGym(n))) notFound();
  return children;
}
