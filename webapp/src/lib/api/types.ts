/**
 * バックエンド API（Cloud Run / Express）の JSON 形。**コードが正**（backend/src/routes, repositories）。
 * 生の形（snake_case・数値が文字列）をここで受け、正規化した型（Gym など）に変換して UI へ渡す。
 */

/** 共通のレスポンス封筒 */
export interface ApiEnvelope<T> {
  success: boolean;
  data: T;
  message?: string;
}

// ---------------------------------------------------------------- Gym

/** GET /gyms, /gyms/:id の生データ。COUNT は pg の bigint なので文字列で来る */
export interface RawGym {
  gym_id: number;
  gym_name: string;
  hp_link: string | null;
  prefecture: string;
  city: string;
  address_line: string;
  latitude: string | number;
  longitude: string | number;
  tel_no: string | null;
  fee: string | null;
  minimum_fee: number | null;
  equipment_rental_fee: string | null;
  is_bouldering_gym: boolean;
  is_lead_gym: boolean;
  is_speed_gym: boolean;
  ikitai_count: string | number;
  boul_count: string | number;
  sun_open: string | null; sun_close: string | null;
  mon_open: string | null; mon_close: string | null;
  tue_open: string | null; tue_close: string | null;
  wed_open: string | null; wed_close: string | null;
  thu_open: string | null; thu_close: string | null;
  fri_open: string | null; fri_close: string | null;
  sat_open: string | null; sat_close: string | null;
}

export type GymType = "bouldering" | "lead" | "speed";

/** 曜日ごとの営業時間。"HH:MM"（秒は落とす）。休みは null */
export interface DayHours {
  open: string | null;
  close: string | null;
}

/** 0=日 … 6=土（JavaScript の getDay と同じ並び） */
export type WeekHours = [DayHours, DayHours, DayHours, DayHours, DayHours, DayHours, DayHours];

export interface Gym {
  id: number;
  name: string;
  hpLink: string | null;
  prefecture: string;
  city: string;
  addressLine: string;
  /** 都道府県＋市区町村＋番地 */
  fullAddress: string;
  lat: number;
  lng: number;
  tel: string | null;
  /** 料金の全文（改行区切り） */
  fee: string;
  /** 最低料金（円）。不明は null */
  minimumFee: number | null;
  /** レンタル料金の全文 */
  rentalFee: string;
  types: GymType[];
  ikitaiCount: number;
  boulCount: number;
  hours: WeekHours;
}

// ---------------------------------------------------------------- Photos

export interface GymPhoto {
  url: string;
  /** Google Places 由来のときは投稿者名（表示義務あり） */
  authorName: string | null;
  authorUri: string | null;
}

export interface GymPhotosResponse {
  source: "own" | "google" | "none";
  photos: GymPhoto[];
}

// ---------------------------------------------------------------- Tweet（ボル活）

export interface RawTweet {
  tweet_id: number;
  tweet_contents: string;
  /** DATE 列は 'YYYY-MM-DD'（JST 統一 PR #72 以降） */
  visited_date: string;
  tweeted_date: string;
  liked_counts: string | number;
  movie_url: string | null;
  user_id: string;
  user_name: string;
  user_icon_url: string | null;
  gym_id: number;
  gym_name: string;
  prefecture: string;
  media_urls: string[] | null;
}

export interface Tweet {
  id: number;
  content: string;
  /** 'YYYY-MM-DD' */
  visitedDate: string;
  /** ISO 文字列（UTC） */
  tweetedAt: string;
  likedCount: number;
  movieUrl: string | null;
  userId: string;
  userName: string;
  userIconUrl: string | null;
  gymId: number;
  gymName: string;
  prefecture: string;
  mediaUrls: string[];
}

// ---------------------------------------------------------------- User

/** GET /users/:id/profile（公開プロフィール） */
export interface RawPublicProfile {
  user_id: string;
  user_name: string;
  user_icon_url: string | null;
  user_introduce: string | null;
  gender: number | null;
  boul_start_date: string | null;
  birthday: string | null;
  home_gym_id: number | null;
}

export interface PublicProfile {
  id: string;
  name: string;
  iconUrl: string | null;
  introduce: string;
  /** 'YYYY-MM-DD' */
  boulStartDate: string | null;
  homeGymId: number | null;
}

/** GET /users/:id/stats/monthly */
export interface RawMonthlyStats {
  total_visits: string | number;
  unique_gyms: string | number;
  weekly_average: string | number;
  top_gyms?: Array<{ gym_id: number; gym_name: string; visit_count: string | number }>;
}

export interface MonthlyStats {
  totalVisits: number;
  uniqueGyms: number;
  weeklyAverage: number;
  topGyms: Array<{ gymId: number; gymName: string; visitCount: number }>;
}
