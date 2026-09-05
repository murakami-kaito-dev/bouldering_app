"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import type { MonthlyStats, RawPublicProfile } from "@/lib/api/types";
import type { TweetPage } from "@/lib/api/tweets";
import { bff, BffError, useAuth } from "@/lib/auth";
import { normalizeProfile } from "@/lib/api/users";
import type { FavoriteGym } from "@/app/api/me/favorite-gyms/route";
import { Container, Eyebrow, SectionHeader, Skeleton, Stat } from "@/components/ui/Primitives";
import { LinkButton } from "@/components/ui/Button";
import { Tape } from "@/components/ui/Tape";
import { AppCta } from "@/components/site/AppCta";
import { ProfileHeader } from "./ProfileHeader";
import { UserTweetList } from "./UserTweetList";

export interface SlimGym {
  id: number;
  name: string;
}

interface Loaded {
  profile: ReturnType<typeof normalizeProfile>;
  stats: MonthlyStats;
  favorites: FavoriteGym[];
  tweets: TweetPage;
}

/** 本人データを BFF からまとめて読む（全て要トークン） */
async function fetchMe(token: string): Promise<Loaded> {
  const [me, stats, favorites, tweets] = await Promise.all([
    bff<RawPublicProfile>("/api/me", { token }),
    bff<MonthlyStats>("/api/me/stats?months_ago=0", { token }),
    bff<FavoriteGym[]>("/api/me/favorite-gyms", { token }),
    bff<TweetPage>("/api/me/tweets", { token }),
  ]);
  return { profile: normalizeProfile(me), stats, favorites, tweets };
}

/** /me の本体（RequireAuth の内側で描画）。データは全て BFF 経由・トークン付き */
export function MePage({ gyms }: { gyms: SlimGym[] }) {
  const { user, getIdToken } = useAuth();
  const [data, setData] = useState<Loaded | null>(null);
  const [error, setError] = useState<string | null>(null);

  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    let cancelled = false;
    getIdToken()
      .then((token) => {
        if (!token) throw new BffError(401, "ログインの有効期限が切れました。もう一度ログインしてください。");
        return fetchMe(token);
      })
      .then((loaded) => {
        if (cancelled) return;
        setError(null);
        setData(loaded);
      })
      .catch((e: unknown) => {
        if (cancelled) return;
        setError(e instanceof BffError ? e.message : "読み込みに失敗しました。時間をおいて再度お試しください。");
      });
    return () => {
      cancelled = true;
    };
  }, [getIdToken, reloadKey]);

  const reload = () => {
    setError(null);
    setData(null);
    setReloadKey((k) => k + 1);
  };

  if (error) {
    return (
      <Container className="flex flex-col gap-4 py-12">
        <Eyebrow>MY PAGE</Eyebrow>
        <h1 className="text-h1">マイページ</h1>
        <p role="alert" className="rounded-card border border-hold-red/40 bg-hold-red/10 px-4 py-3 text-small text-hold-red">
          {error}
        </p>
        <div className="flex gap-3">
          <button type="button" onClick={reload} className="pressable rounded-pill border border-crack px-5 py-2 text-[14px] font-bold text-chalk hover:bg-ledge">
            再読み込み
          </button>
          <Link href="/login?next=/me" className="pressable rounded-pill bg-wall px-5 py-2 text-[14px] font-bold text-wall-ink hover:bg-wall-bright">
            ログインし直す
          </Link>
        </div>
      </Container>
    );
  }

  if (!data) {
    return (
      <Container className="flex flex-col gap-8 py-12" aria-busy="true">
        <div className="flex items-start gap-6">
          <span className="inline-block h-[88px] w-[88px] overflow-hidden rounded-pill">
            <Skeleton className="h-full w-full" />
          </span>
          <div className="flex flex-1 flex-col gap-3">
            <Skeleton className="h-9 w-48" />
            <Skeleton className="h-4 w-64" />
          </div>
        </div>
        <Skeleton className="h-32 w-full" />
        <Skeleton className="h-40 w-full" />
      </Container>
    );
  }

  const { profile, stats, favorites, tweets } = data;
  const homeGymName = profile.homeGymId ? (gyms.find((g) => g.id === profile.homeGymId)?.name ?? null) : null;
  const iconUrl = profile.iconUrl ?? user?.photoURL ?? null;

  return (
    <Container className="flex flex-col gap-12 py-10 md:py-12">
      <div className="flex flex-col gap-6">
        <Eyebrow>MY PAGE</Eyebrow>
        <ProfileHeader
          name={profile.name || user?.displayName || ""}
          iconUrl={iconUrl}
          introduce={profile.introduce}
          boulStartDate={profile.boulStartDate}
          homeGymName={homeGymName}
        />
        <div className="flex flex-col gap-3 rounded-card bg-ledge p-4 md:flex-row md:items-center md:justify-between md:p-5">
          <p className="text-small text-dust">プロフィール編集（名前・自己紹介・ホームジム・アイコン）はアプリから行えます。</p>
          <AppCta variant="compact" />
        </div>
      </div>

      <section className="flex flex-col gap-5">
        <SectionHeader eyebrow="THIS MONTH" title="今月" aside={<LinkButton href="/post">ボル活を投稿</LinkButton>} />
        <div className="grid grid-cols-3 gap-4 rounded-card bg-joint p-5 md:p-6">
          <Stat label="ボル活" value={stats.totalVisits} unit="回" />
          <Stat label="ジム数" value={stats.uniqueGyms} unit="件" />
          <Stat label="週あたり" value={stats.weeklyAverage.toFixed(1)} unit="回" tone="dust" />
        </div>
      </section>

      <section className="flex flex-col gap-5">
        <SectionHeader eyebrow={`IKITAI ${favorites.length}`} title="イキタイ" />
        {favorites.length === 0 ? (
          <p className="rounded-card border border-dashed border-crack px-5 py-8 text-center text-dust">
            イキタイはまだありません。
            <Link href="/gyms" className="ml-2 text-wall hover:underline underline-offset-4">
              ジムを探す
            </Link>
          </p>
        ) : (
          <ul className="grid gap-2 md:grid-cols-2">
            {favorites.map((g) => (
              <li key={g.id}>
                <Link
                  href={`/gyms/${g.id}`}
                  className="pressable flex items-center justify-between gap-3 rounded-card border border-transparent bg-joint px-4 py-3 hover:border-crack hover:bg-ledge"
                >
                  <span className="flex min-w-0 flex-col">
                    <span className="truncate font-display text-[16px] font-bold text-chalk">{g.name}</span>
                    <span className="truncate text-small text-dust">{g.city}</span>
                  </span>
                  <Tape tone="yellow">{g.prefecture.replace(/[都府県]$/, "") || "—"}</Tape>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="flex flex-col gap-5">
        <SectionHeader eyebrow="MY LOG" title="自分のボル活" />
        <UserTweetList mode="me" initial={tweets} />
      </section>
    </Container>
  );
}
