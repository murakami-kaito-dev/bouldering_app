import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/moderation_result.dart';
import '../../domain/usecases/validate_post_content_usecase.dart';
import '../../domain/services/text_moderation_service.dart';
import '../../infrastructure/services/local_text_moderation_service.dart';

/// モデレーション状態
class ModerationState {
  final bool isChecking;
  final ModerationResult? lastResult;
  final String? errorMessage;

  const ModerationState({
    this.isChecking = false,
    this.lastResult,
    this.errorMessage,
  });

  ModerationState copyWith({
    bool? isChecking,
    ModerationResult? lastResult,
    String? errorMessage,
  }) {
    return ModerationState(
      isChecking: isChecking ?? this.isChecking,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 投稿モデレーションNotifier（MVVM ViewModel）
///
/// 役割:
/// - 投稿コンテンツの適切性を検証
/// - UIとビジネスロジックの仲介
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のViewModel
/// - UI状態管理とユースケース呼び出し
class PostModerationNotifier extends StateNotifier<ModerationState> {
  final ValidatePostContentUseCase _validateUseCase;

  PostModerationNotifier(this._validateUseCase)
      : super(const ModerationState());

  /// 投稿コンテンツを検証
  ModerationResult validateContent(String content) {
    state = state.copyWith(isChecking: true);
    
    try {
      final result = _validateUseCase.execute(content);
      state = state.copyWith(
        isChecking: false,
        lastResult: result,
        errorMessage: null,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        errorMessage: 'エラーが発生しました',
      );
      // エラー時は投稿を許可（フィルタリングの失敗で投稿できないのを防ぐ）
      return const ModerationResult(
        isAllowed: true,
        detectedWords: [],
      );
    }
  }

  /// リアルタイムチェック（入力中の軽量チェック）
  bool quickCheck(String content) {
    try {
      return _validateUseCase.quickCheck(content);
    } catch (e) {
      // エラー時は許可（UXを優先）
      return true;
    }
  }

  /// 状態をリセット
  void reset() {
    state = const ModerationState();
  }
}

/// テキストモデレーションサービスProvider
/// 
/// 【役割】NGワードチェックの実装方法を提供する窓口
/// 
/// 【現在】LocalTextModerationService（アプリ内でチェック）
/// - NGワードリストはアプリに埋め込み
/// - オフラインでも動作
/// 
/// 【将来の切り替え例】
/// ```dart
/// return ServerTextModerationService(); // サーバーAPIでチェック
/// ```
/// これだけで全体のチェック方法が切り替わる（依存性注入の利点）
final textModerationServiceProvider = Provider<TextModerationService>((ref) {
  return LocalTextModerationService();
});

/// 投稿コンテンツ検証UseCaseProvider
/// 
/// 【役割】ビジネスルール（アプリの決まりごと）を管理
/// 
/// 【具体的な処理】
/// 1. 空文字チェック（空ならスキップ）
/// 2. NGワード検証サービスを呼び出し
/// 3. 結果に基づいて投稿可否を判定
/// 4. エラーメッセージの生成
/// 
/// 【なぜ必要？】
/// - UIコードにビジネスロジックを書かない（分離）
/// - 投稿画面でも編集画面でも使い回せる（再利用性）
/// - テストが書きやすい（テスタビリティ）
final validatePostContentUseCaseProvider = Provider<ValidatePostContentUseCase>((ref) {
  final moderationService = ref.read(textModerationServiceProvider);
  return ValidatePostContentUseCase(moderationService);
});

/// 投稿モデレーションProvider
/// 
/// 【役割】UI状態管理（MVVM のViewModel）
/// 
/// 【管理する状態】
/// - isChecking: ローディング表示用フラグ
/// - lastResult: 前回の検証結果（エラー表示用）
/// - errorMessage: エラーメッセージ
/// 
/// 【投稿画面での使い方】
/// ```dart
/// final result = ref.read(postModerationProvider.notifier)
///     .validateContent("投稿テキスト");
/// if (!result.isAllowed) {
///   showDialog("NGワードが含まれています");
/// }
/// ```
final postModerationProvider = StateNotifierProvider<PostModerationNotifier, ModerationState>((ref) {
  final validateUseCase = ref.read(validatePostContentUseCaseProvider);
  return PostModerationNotifier(validateUseCase);
});