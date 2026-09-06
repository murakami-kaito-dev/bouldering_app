import '../services/api_client.dart';
import '../../domain/entities/comment.dart';

/// コメント（スレッド）データソース
///
/// 役割:
/// - コメント関連の API 通信を担当
/// - API レスポンスと Domain エンティティ間の変換
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure 層のデータソース
/// - Repository 実装から呼び出される
class CommentDataSource {
  final ApiClient _apiClient;

  CommentDataSource(this._apiClient);

  /// コメント一覧取得
  ///
  /// REST API: GET /api/tweets/{tweetId}/comments?limit=&cursor=
  /// 未ログインでも取得可（ログイン時はブロック関係が除外される）
  Future<List<Comment>> getComments(
    int tweetId, {
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final parameters = <String, String>{
        'limit': limit.toString(),
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      };

      final response = await _apiClient.get(
        endpoint: '/tweets/$tweetId/comments',
        parameters: parameters,
      );

      final List<dynamic> data = response['data'] ?? [];
      return data
          .map((item) => Comment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('コメント取得に失敗しました: $e');
    }
  }

  /// コメント投稿（返信は parentCommentId を付ける）
  ///
  /// REST API: POST /api/tweets/{tweetId}/comments（認証必須）
  Future<Comment> createComment(
    int tweetId, {
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final response = await _apiClient.post(
        endpoint: '/tweets/$tweetId/comments',
        body: {
          'content': content,
          if (parentCommentId != null) 'parent_comment_id': parentCommentId,
        },
        requireAuth: true,
      );

      return Comment.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('コメント投稿に失敗しました: $e');
    }
  }

  /// コメント削除（論理削除）
  ///
  /// REST API: DELETE /api/comments/{commentId}（認証必須・本人 or 投稿者）
  Future<void> deleteComment(int commentId) async {
    try {
      await _apiClient.delete(
        endpoint: '/comments/$commentId',
        requireAuth: true,
      );
    } catch (e) {
      throw Exception('コメント削除に失敗しました: $e');
    }
  }
}
