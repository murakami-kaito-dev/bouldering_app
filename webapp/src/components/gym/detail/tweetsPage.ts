import type { Tweet } from "@/lib/api/types";

/**
 * ボル活タブのページング契約（サーバーの初期取得と BFF のレスポンスで共有）。
 * "use client" モジュールに置くとサーバーから import した値がクライアント参照に化けるので、ここに切り出す。
 */
export interface TweetsPage {
  items: Tweet[];
  nextCursor: string | null;
}

export const GYM_TWEETS_PAGE_SIZE = 10;

/** BFF が受け取る cursor の妥当性（バックエンドの cursor は最後の投稿の tweeted_date＝ISO8601。長さ上限つき） */
export function isValidCursor(v: string | null): v is string {
  return !!v && v.length <= 40 && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?(Z|[+-]\d{2}:\d{2})$/.test(v) && !Number.isNaN(Date.parse(v));
}
