import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/comment_datasource.dart';

/// コメントリポジトリ実装
class CommentRepositoryImpl implements CommentRepository {
  final CommentDataSource _dataSource;

  CommentRepositoryImpl(this._dataSource);

  @override
  Future<List<Comment>> getComments(int tweetId,
      {int limit = 50, String? cursor}) {
    return _dataSource.getComments(tweetId, limit: limit, cursor: cursor);
  }

  @override
  Future<Comment> createComment(int tweetId,
      {required String content, int? parentCommentId}) {
    return _dataSource.createComment(tweetId,
        content: content, parentCommentId: parentCommentId);
  }

  @override
  Future<void> deleteComment(int commentId) {
    return _dataSource.deleteComment(commentId);
  }
}
