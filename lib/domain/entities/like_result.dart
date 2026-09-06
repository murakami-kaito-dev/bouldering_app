/// いいね操作の結果（サーバーが確定した値）
///
/// `POST/DELETE /api/tweets/:id/like` の応答 `{ liked, liked_count }` に対応する。
/// 楽観的更新の後、この値で一覧の表示を確定させる。
class LikeResult {
  final bool liked;
  final int likedCount;

  const LikeResult({required this.liked, required this.likedCount});

  factory LikeResult.fromJson(Map<String, dynamic> json) {
    return LikeResult(
      liked: json['liked'] == true,
      likedCount: (json['liked_count'] as num?)?.toInt() ?? 0,
    );
  }
}
