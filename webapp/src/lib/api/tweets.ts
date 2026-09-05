import { apiRequest, toNumber } from "./client";
import type { RawTweet, Tweet } from "./types";

export function normalizeTweet(r: RawTweet): Tweet {
  return {
    id: r.tweet_id,
    content: r.tweet_contents ?? "",
    visitedDate: (r.visited_date ?? "").slice(0, 10),
    tweetedAt: r.tweeted_date,
    likedCount: toNumber(r.liked_counts),
    movieUrl: r.movie_url ?? null,
    userId: r.user_id,
    userName: r.user_name ?? "",
    userIconUrl: r.user_icon_url ?? null,
    gymId: r.gym_id,
    gymName: (r.gym_name ?? "").trim(),
    prefecture: r.prefecture ?? "",
    mediaUrls: Array.isArray(r.media_urls) ? r.media_urls.filter(Boolean) : [],
  };
}

/** カーソルは最後の投稿の tweeted_date（ISO8601）。バックエンドは `tweeted_date < cursor` で次ページを返す */
export interface TweetPage {
  items: Tweet[];
  nextCursor: string | null;
}

/** みんなのボル活（新しい順）。ログイン時はトークンを渡すとブロック関係が反映される */
export async function getAllTweets(limit = 20, cursor?: string | null, token?: string | null): Promise<TweetPage> {
  const qs = new URLSearchParams({ limit: String(limit) });
  if (cursor) qs.set("cursor", cursor);
  const raw = await apiRequest<RawTweet[]>(`/tweets?${qs}`, token ? { token } : { revalidate: 60, tags: ["tweets"] });
  const items = raw.map(normalizeTweet);
  return { items, nextCursor: items.length === limit ? items[items.length - 1].tweetedAt : null };
}

/** あるユーザーのボル活 */
export async function getUserTweets(userId: string, limit = 20, cursor?: string | null, token?: string | null): Promise<TweetPage> {
  const qs = new URLSearchParams({ limit: String(limit) });
  if (cursor) qs.set("cursor", cursor);
  const raw = await apiRequest<RawTweet[]>(`/tweets/users/${encodeURIComponent(userId)}?${qs}`, token ? { token } : { revalidate: 60 });
  const items = raw.map(normalizeTweet);
  return { items, nextCursor: items.length === limit ? items[items.length - 1].tweetedAt : null };
}

/** 投稿（要ログイン） */
export interface CreateTweetInput {
  gymId: number;
  content: string;
  /** 'YYYY-MM-DD'（JST の今日以前） */
  visitedDate: string;
  mediaUrls?: string[];
}

export async function createTweet(input: CreateTweetInput, token: string): Promise<Tweet> {
  const raw = await apiRequest<RawTweet>("/tweets", {
    method: "POST",
    token,
    body: {
      gym_id: input.gymId,
      tweet_contents: input.content,
      visited_date: input.visitedDate,
      media_urls: input.mediaUrls ?? [],
    },
  });
  return normalizeTweet(raw);
}

export async function deleteTweet(tweetId: number, token: string): Promise<void> {
  await apiRequest<unknown>(`/tweets/${tweetId}`, { method: "DELETE", token });
}
