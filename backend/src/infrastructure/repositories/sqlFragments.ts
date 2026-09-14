/**
 * 複数リポジトリで共有する SQL 断片
 */

/**
 * ツイート一覧・詳細の SELECT 句に加える `liked_by_me` 列
 *
 * @param userIdParamIndex リクエストユーザーIDを渡すプレースホルダ番号（$N の N）
 *
 * 未認証時はパラメータに null を渡す。`tl.user_id = NULL` は真にならないので
 * EXISTS は false になり、CASE 分岐なしで「未認証は false」が満たされる。
 */
export function likedByMeSql(userIdParamIndex: number): string {
  return `EXISTS(
              SELECT 1 FROM tweet_likes AS tl
              WHERE tl.tweet_id = t.tweet_id AND tl.user_id = $${userIdParamIndex}
            ) AS liked_by_me`;
}
