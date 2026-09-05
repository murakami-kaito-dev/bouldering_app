import type { Metadata } from "next";
import { notFound } from "next/navigation";
import type { Gym } from "@/lib/api/types";
import { getAllGyms, getGym, getGymPhotos, getGymTweets } from "@/lib/api/gyms";
import { todayHours } from "@/lib/gym/hours";
import { GYM_TYPE_META, distanceKm, formatYen } from "@/lib/gym/types";
import { Container } from "@/components/ui/Primitives";
import { AppCta } from "@/components/site/AppCta";
import { AdSlot } from "@/components/ads/AdSlot";
import { parseGymId } from "@/components/gym/detail/gymId";
import { GymBreadcrumb, GymHero } from "@/components/gym/detail/GymHero";
import { PhotoStrip } from "@/components/gym/detail/PhotoStrip";
import { GymTabs } from "@/components/gym/detail/GymTabs";
import { FacilityInfo, googleMapsSearchUrl } from "@/components/gym/detail/FacilityInfo";
import { GymTweetList } from "@/components/gym/detail/GymTweetList";
import { GYM_TWEETS_PAGE_SIZE } from "@/components/gym/detail/tweetsPage";
import { GymMap } from "@/components/gym/detail/GymMap";
import { NearbyGyms, type NearbyItem } from "@/components/gym/detail/NearbyGymCard";
import { GymJsonLd } from "@/components/gym/detail/GymJsonLd";

/** 詳細は 10 分キャッシュ（webapp/CLAUDE.md） */
export const revalidate = 600;

const NEARBY_COUNT = 4;

/** 数字以外の id・存在しない id はどちらも 404（バックエンドの 400 を踏まない） */
async function loadGym(rawId: string): Promise<Gym | null> {
  const id = parseGymId(rawId);
  if (id === null) return null;
  return getGym(id);
}

/** 補助データは落ちても本文を出す */
async function safe<T>(label: string, fn: () => Promise<T>, fallback: T): Promise<T> {
  try {
    return await fn();
  } catch (e) {
    console.error(`[gyms/[id]] ${label} failed:`, e);
    return fallback;
  }
}

function truncate(s: string, max: number): string {
  return s.length <= max ? s : `${s.slice(0, max - 1)}…`;
}

function buildDescription(gym: Gym): string {
  const types = gym.types.map((t) => GYM_TYPE_META[t].label).join("・") || "クライミング";
  const today = todayHours(gym.hours);
  const hoursText = today.open && today.close ? `本日 ${today.open}〜${today.close}` : "本日休み";
  const feeText = gym.minimumFee === null ? "" : `、${formatYen(gym.minimumFee)}円〜`;
  return truncate(`${gym.prefecture}${gym.city}の${types}ジム。${hoursText}${feeText}。住所: ${gym.fullAddress}`, 120);
}

export async function generateMetadata({ params }: PageProps<"/gyms/[id]">): Promise<Metadata> {
  const { id } = await params;
  const gym = await loadGym(id);
  if (!gym) notFound();
  const title = `${gym.name}｜${gym.prefecture}${gym.city}のボルダリングジム`;
  const description = buildDescription(gym);
  const path = `/gyms/${gym.id}`;
  return {
    title,
    description,
    alternates: { canonical: path },
    // OG 画像は同階層の opengraph-image.tsx が自動で付く
    openGraph: { type: "website", title, description, url: path },
    twitter: { card: "summary_large_image", title, description },
  };
}

export default async function GymDetailPage({ params }: PageProps<"/gyms/[id]">) {
  const { id: rawId } = await params;
  const gym = await loadGym(rawId);
  if (!gym) notFound();

  const [photos, tweets, allGyms] = await Promise.all([
    safe("photos", () => getGymPhotos(gym.id), { source: "none" as const, photos: [] }),
    safe("tweets", () => getGymTweets(gym.id, GYM_TWEETS_PAGE_SIZE), { items: [], nextCursor: null }),
    safe("allGyms", () => getAllGyms(), [] as Gym[]),
  ]);

  const nearby: NearbyItem[] = allGyms
    .filter((g) => g.id !== gym.id && g.prefecture === gym.prefecture && Number.isFinite(g.lat) && Number.isFinite(g.lng))
    .map((g) => ({ gym: g, distanceKm: distanceKm(gym.lat, gym.lng, g.lat, g.lng) }))
    .sort((a, b) => a.distanceKm - b.distanceKm)
    .slice(0, NEARBY_COUNT);

  const mapsUrl = googleMapsSearchUrl(gym);

  return (
    <Container className="py-8 md:py-12">
      <GymJsonLd gym={gym} />

      <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_360px] lg:gap-12">
        <div className="flex min-w-0 flex-col gap-8">
          <GymBreadcrumb prefecture={gym.prefecture} />
          <GymHero gym={gym} />
          <PhotoStrip gymName={gym.name} photos={photos} />
          <GymTabs
            boulCount={gym.boulCount}
            info={<FacilityInfo gym={gym} />}
            boulLog={<GymTweetList gymId={gym.id} initial={tweets} emptyCta={<AppCta variant="gym" gymName={gym.name} />} />}
          />
        </div>

        <aside className="flex flex-col gap-4 lg:sticky lg:top-20 lg:self-start" aria-label="地図とアプリ">
          <GymMap name={gym.name} lat={gym.lat} lng={gym.lng} types={gym.types} address={gym.fullAddress} mapsUrl={mapsUrl} />
          <AppCta variant="gym" gymName={gym.name} />
          <AdSlot format="rect" />
        </aside>
      </div>

      <NearbyGyms prefecture={gym.prefecture} items={nearby} className="mt-12 md:mt-16" />
    </Container>
  );
}
