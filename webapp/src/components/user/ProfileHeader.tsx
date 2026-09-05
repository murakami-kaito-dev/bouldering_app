import { Avatar } from "@/components/tweet/TweetCard";
import { Eyebrow } from "@/components/ui/Primitives";
import { climbingHistory, climbingHistoryLabel } from "@/lib/auth/profile";

/**
 * プロフィールの頭（/me と /users/[id] で共用）。サーバー・クライアントどちらからも使える。
 * ボルダリング歴は JST の今日基準で年・月に換算。
 */
export function ProfileHeader({
  name,
  iconUrl,
  introduce,
  boulStartDate,
  homeGymName,
  aside,
}: {
  name: string;
  iconUrl: string | null;
  introduce?: string;
  boulStartDate: string | null;
  homeGymName: string | null;
  aside?: React.ReactNode;
}) {
  const history = climbingHistoryLabel(climbingHistory(boulStartDate));
  return (
    <header className="flex flex-col gap-5 md:flex-row md:items-start md:gap-6">
      <div className="shrink-0">
        <Avatar src={iconUrl} name={name} size={88} />
      </div>
      <div className="flex min-w-0 flex-1 flex-col gap-3">
        <h1 className="text-h1 break-words">{name || "名もなきクライマー"}</h1>
        {introduce ? <p className="whitespace-pre-wrap break-words text-[15px] leading-[1.75] text-dust">{introduce}</p> : null}
        <dl className="flex flex-wrap gap-x-8 gap-y-3">
          <div className="flex flex-col gap-1">
            <dt>
              <Eyebrow>ボルダリング歴</Eyebrow>
            </dt>
            <dd className="font-numeric text-[22px] font-bold leading-none text-chalk">{history}</dd>
          </div>
          <div className="flex min-w-0 flex-col gap-1">
            <dt>
              <Eyebrow>ホームジム</Eyebrow>
            </dt>
            <dd className="truncate font-display text-[16px] font-bold text-chalk">{homeGymName ?? "未設定"}</dd>
          </div>
        </dl>
      </div>
      {aside ? <div className="shrink-0">{aside}</div> : null}
    </header>
  );
}
