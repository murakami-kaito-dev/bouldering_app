import '../entities/bouldering_stats.dart';
import '../repositories/user_repository.dart';

/// 月間統計情報取得UseCase
/// 
/// 役割:
/// - ユーザーの月間統計情報を取得するビジネスロジック
/// - Repository層とPresentation層の橋渡し
/// - 統計データの取得に関するビジネスルールの実装
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のUseCase
/// - Repository抽象クラスに依存（依存関係逆転の原則）
/// - Presentation層から呼び出される
/// 
/// ビジネスルール:
/// - 月数指定は0-12の範囲のみ許可
/// - ユーザーIDは必須
/// - データが存在しない場合は0値での統計を返す
class GetMonthlyStatisticsUseCase {
  final UserRepository _userRepository;

  /// コンストラクタ
  /// 
  /// [_userRepository] ユーザーリポジトリ
  GetMonthlyStatisticsUseCase(this._userRepository);

  /// 月間統計情報を取得
  /// 
  /// [userId] ユーザーID
  /// [monthsAgo] 何ヶ月前の統計か（0: 今月、1: 先月）
  /// 
  /// 返り値:
  /// [BoulderingStats] 月間統計情報エンティティ
  /// 
  /// 例外:
  /// [ArgumentException] 不正な引数の場合にスロー
  /// [Exception] リポジトリ層でのエラー時にスロー
  Future<BoulderingStats> execute({
    required String userId,
    required int monthsAgo,
  }) async {
    // 入力値検証
    if (userId.trim().isEmpty) {
      throw ArgumentError('ユーザーIDは必須です');
    }

    if (monthsAgo < 0 || monthsAgo > 12) {
      throw ArgumentError('monthsAgoは0以上12以下である必要があります');
    }

    try {
      // Repository経由で統計データを取得
      final statistics = await _userRepository.getMonthlyStatistics(userId, monthsAgo);
      return statistics;
    } catch (e) {
      // ログ出力（必要に応じて）
      // 例外を再スローしてPresentation層で適切にハンドリング
      rethrow;
    }
  }
}