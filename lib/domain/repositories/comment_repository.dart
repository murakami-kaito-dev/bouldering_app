import '../entities/comment.dart';

/// コメント（スレッド）リポジトリ
abstract class CommentRepository {
  /// ツイートのコメント一覧（作成日時 昇順・フラット）
  ///
  /// [cursor] 前ページ最後の `createdAt`（ISO8601）。null で先頭から
  Future<List<Comment>> getComments(int tweetId, {int limit = 50, String? cursor});

  /// コメント投稿。[parentCommentId] があれば返信
  Future<Comment> createComment(int tweetId,
      {required String content, int? parentCommentId});

  /// コメント削除（論理削除。本人 or 投稿者のみ）
  Future<void> deleteComment(int commentId);
}
