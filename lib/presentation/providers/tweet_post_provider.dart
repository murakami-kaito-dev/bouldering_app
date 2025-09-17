import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/tweet_usecases.dart';
import 'dependency_injection.dart';

/// ツイート投稿状態管理Provider
///
/// 役割:
/// - ツイート投稿機能の管理
/// - 投稿処理中の状態管理
/// - エラーハンドリング
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層の状態管理
/// - Domain層のUseCaseを呼び出し
/// - UIコンポーネントから参照される
///
/// 使用場所:
/// - tweet_post_page.dart: ツイート投稿画面
/// - activity_post_page.dart: アクティビティ投稿画面
///
/// 単一責任の原則:
/// - ツイート投稿に関する責任のみを持つ
/// - 一覧表示や取得とは分離
/// - 他のプロバイダーとの依存関係なし

/// ツイート投稿状態を管理するStateNotifier
///
/// AsyncValue<bool>の意味:
/// - loading: 投稿処理中
/// - data(true): 投稿成功
/// - data(false): 初期状態または投稿失敗
/// - error: エラー発生
class TweetPostNotifier extends StateNotifier<AsyncValue<bool>> {
  final PostTweetUseCase _postTweetUseCase;

  /// コンストラクタ
  ///
  /// 初期状態はdata(false)
  TweetPostNotifier(this._postTweetUseCase)
      : super(const AsyncValue.data(false));

  /// ツイート投稿
  ///
  /// [userId] 投稿者のユーザーID
  /// [gymId] 投稿対象のジムID
  /// [content] ツイート内容（最大400文字、0文字でも投稿可能）
  /// [visitedDate] ジム訪問日
  /// [movieUrl] 動画URL（オプション）
  /// [mediaUrls] 画像URLリスト（オプション、最大4枚）
  ///
  /// 返り値:
  /// - true: 投稿成功
  /// - false: 投稿失敗
  ///
  /// 処理フロー:
  /// 1. ローディング状態に設定
  /// 2. UseCaseを呼び出して投稿処理実行
  /// 3. 成功/失敗を状態に反映
  /// 4. 結果を返す
  Future<bool> postTweet({
    required String userId,
    required int gymId,
    required String content,
    required DateTime visitedDate,
    String? movieUrl,
    List<String>? mediaUrls,
  }) async {
    // 投稿処理開始（ローディング状態）
    state = const AsyncValue.loading();

    try {
      // ツイート投稿処理を実行
      final success = await _postTweetUseCase.execute(
        userId: userId,
        gymId: gymId,
        content: content,
        visitedDate: visitedDate,
        movieUrl: movieUrl,
        mediaUrls: mediaUrls,
      );

      // 投稿結果を状態に反映
      state = AsyncValue.data(success);
      return success;
    } catch (e, stackTrace) {
      // エラー状態を設定
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// 投稿状態をリセット
  ///
  /// 使用タイミング:
  /// - 投稿画面を離れる時
  /// - 新しい投稿を開始する時
  /// - エラー後に再試行する時
  void resetState() {
    state = const AsyncValue.data(false);
  }

  /// 現在投稿処理中かどうかを判定
  ///
  /// UIでローディング表示の制御に使用
  bool get isPosting {
    return state.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );
  }

  /// 最後の投稿が成功したかを判定
  ///
  /// 成功時のUI処理に使用
  bool get lastPostSuccess {
    return state.maybeWhen(
      data: (success) => success,
      orElse: () => false,
    );
  }

  /// エラーメッセージを取得
  ///
  /// エラー表示用
  String? get errorMessage {
    return state.maybeWhen(
      error: (error, _) => error.toString(),
      orElse: () => null,
    );
  }
}

// ==================== Provider定義 ====================

/// ツイート投稿状態管理Provider
///
/// 使用例:
/// ```dart
/// // 投稿処理
/// final success = await ref.read(tweetPostProvider.notifier).postTweet(
///   userId: userId,
///   gymId: gymId,
///   content: content,
///   visitedDate: visitedDate,
/// );
///
/// // 状態監視
/// final postState = ref.watch(tweetPostProvider);
/// postState.when(
///   loading: () => CircularProgressIndicator(),
///   data: (success) => success ? Text('投稿成功') : SizedBox(),
///   error: (error, _) => Text('エラー: $error'),
/// );
/// ```
final tweetPostProvider =
    StateNotifierProvider<TweetPostNotifier, AsyncValue<bool>>((ref) {
  final postTweetUseCase = ref.read(postTweetUseCaseProvider);
  return TweetPostNotifier(postTweetUseCase);
});

/// ツイート投稿中状態Provider
///
/// 投稿ボタンの有効/無効制御などに使用
/// 
/// 使用例:
/// ```dart
/// final isPosting = ref.watch(isTweetPostingProvider);
/// ElevatedButton(
///   onPressed: isPosting ? null : () => _postTweet(),
///   child: isPosting ? CircularProgressIndicator() : Text('投稿'),
/// );
/// ```
final isTweetPostingProvider = Provider<bool>((ref) {
  final tweetPostState = ref.watch(tweetPostProvider);
  return tweetPostState.maybeWhen(
    loading: () => true,
    orElse: () => false,
  );
});

/// ツイート投稿成功状態Provider
///
/// 最後の投稿が成功したかを判定
///
/// 使用例:
/// ```dart
/// final postSuccess = ref.watch(tweetPostSuccessProvider);
/// if (postSuccess) {
///   Navigator.pop(context);
///   ScaffoldMessenger.of(context).showSnackBar(
///     SnackBar(content: Text('投稿しました！')),
///   );
/// }
/// ```
final tweetPostSuccessProvider = Provider<bool>((ref) {
  final tweetPostState = ref.watch(tweetPostProvider);
  return tweetPostState.maybeWhen(
    data: (success) => success,
    orElse: () => false,
  );
});

/// ツイート投稿エラーProvider
///
/// エラーメッセージの取得
///
/// 使用例:
/// ```dart
/// final error = ref.watch(tweetPostErrorProvider);
/// if (error != null) {
///   showDialog(
///     context: context,
///     builder: (_) => AlertDialog(
///       title: Text('投稿エラー'),
///       content: Text(error),
///     ),
///   );
/// }
/// ```
final tweetPostErrorProvider = Provider<String?>((ref) {
  final tweetPostState = ref.watch(tweetPostProvider);
  return tweetPostState.maybeWhen(
    error: (error, _) => error.toString(),
    orElse: () => null,
  );
});