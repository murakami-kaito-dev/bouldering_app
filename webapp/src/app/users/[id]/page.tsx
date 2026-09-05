import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getPublicProfile, getMonthlyStats } from "@/lib/api/users";
import { getUserTweets } from "@/lib/api/tweets";
import { getAllGyms } from "@/lib/api/gyms";
import { Container, Eyebrow, SectionHeader, Stat } from "@/components/ui/Primitives";
import { ProfileHeader } from "@/components/user/ProfileHeader";
import { UserTweetList } from "@/components/user/UserTweetList";
import { AppCta } from "@/components/site/AppCta";

type Params = Promise<{ id: string }>;

const VALID_ID = /^[A-Za-z0-9_-]{1,128}$/;

export async function generateMetadata({ params }: { params: Params }): Promise<Metadata> {
  const { id } = await params;
  if (!VALID_ID.test(id)) return { title: "ユーザー" };
  const profile = await getPublicProfile(id).catch(() => null);
  if (!profile) return { title: "ユーザー" };
  const name = profile.name || "名もなきクライマー";
  return {
    title: `${name} のボル活`,
    description: profile.introduce ? profile.introduce.slice(0, 120) : `${name} さんのボルダリング記録（イワノボリタイ）`,
    openGraph: { title: `${name} のボル活`, images: profile.iconUrl ? [{ url: profile.iconUrl }] : undefined },
  };
}

/** 公開プロフィール（SSR）。本人以外も見られる情報だけ出す */
export default async function UserPage({ params }: { params: Params }) {
  const { id } = await params;
  if (!VALID_ID.test(id)) notFound();

  const profile = await getPublicProfile(id);
  if (!profile) notFound();

  const [stats, tweets, gyms] = await Promise.all([
    getMonthlyStats(id, 0).catch(() => null),
    getUserTweets(id).catch(() => ({ items: [], nextCursor: null })),
    profile.homeGymId ? getAllGyms().catch(() => []) : Promise.resolve([]),
  ]);
  const homeGymName = profile.homeGymId ? (gyms.find((g) => g.id === profile.homeGymId)?.name ?? null) : null;
  const name = profile.name || "名もなきクライマー";

  return (
    <Container className="flex flex-col gap-12 py-10 md:py-12">
      <div className="flex flex-col gap-6">
        <Eyebrow>CLIMBER</Eyebrow>
        <ProfileHeader name={name} iconUrl={profile.iconUrl} introduce={profile.introduce} boulStartDate={profile.boulStartDate} homeGymName={homeGymName} />
      </div>

      <section className="flex flex-col gap-5">
        <SectionHeader eyebrow="THIS MONTH" title="今月のボル活" />
        <div className="grid grid-cols-3 gap-4 rounded-card bg-joint p-5 md:p-6">
          <Stat label="ボル活" value={stats?.totalVisits ?? 0} unit="回" />
          <Stat label="ジム数" value={stats?.uniqueGyms ?? 0} unit="件" />
          <Stat label="週あたり" value={(stats?.weeklyAverage ?? 0).toFixed(1)} unit="回" tone="dust" />
        </div>
      </section>

      <div className="grid gap-10 lg:grid-cols-[1fr_360px] lg:items-start">
        <section className="flex flex-col gap-5">
          <SectionHeader eyebrow="LOG" title={`${name} のボル活`} />
          <UserTweetList mode="public" userId={id} initial={tweets} />
        </section>
        <aside className="lg:sticky lg:top-24">
          <AppCta />
        </aside>
      </div>
    </Container>
  );
}
