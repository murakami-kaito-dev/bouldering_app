import '../entities/comment.dart';
import '../exceptions/app_exceptions.dart';
import '../repositories/comment_repository.dart';

/// コメント文字数の上限（バックエンドのバリデーションと一致）
const int kCommentMaxLength = 400;

/// コメント一覧取得
class GetTweetCommentsUseCase {
  final CommentRepository _repository;

  GetTweetCommentsUseCase(this._repository);

  Future<List<Comment>> execute(int tweetId,
      {int limit = 50, String? cursor}) async {
    try {
      return await _repository.getComments(tweetId,
          limit: limit, cursor: cursor);
    } catch (e) {
      throw DataFetchException(
        message: 'コメントの取得に失敗しました',
        originalError: e,
      );
    }
  }
}

/// コメント投稿（返信を含む）
class CreateCommentUseCase {
  final CommentRepository _repository;

  CreateCommentUseCase(this._repository);

  Future<Comment> execute(int tweetId,
      {required String content, int? parentCommentId}) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException(
          message: 'コメントを入力してください', errors: {'content': 'empty'});
    }
    if (trimmed.length > kCommentMaxLength) {
      throw const ValidationException(
          message: 'コメントは$kCommentMaxLength文字以内で入力してください',
          errors: {'content': 'too_long'});
    }
    try {
      return await _repository.createComment(tweetId,
          content: trimmed, parentCommentId: parentCommentId);
    } catch (e) {
      throw DataSaveException(
        message: 'コメントの投稿に失敗しました',
        originalError: e,
      );
    }
  }
}

/// コメント削除（論理削除）
class DeleteCommentUseCase {
  final CommentRepository _repository;

  DeleteCommentUseCase(this._repository);

  Future<void> execute(int commentId) async {
    try {
      await _repository.deleteComment(commentId);
    } catch (e) {
      throw DataSaveException(
        message: 'コメントの削除に失敗しました',
        originalError: e,
      );
    }
  }
}
