import '../../domain/entities/gym.dart';

/// ジム営業時間ユーティリティ
/// 
/// 役割:
/// - 営業時間の判定ロジック
/// - 現在の営業状態の計算
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - 共通ユーティリティ層
/// - 状態を持たない純粋な関数の集合
/// - 各層から参照可能
class GymHoursUtils {
  /// 現在営業中かどうかを判定
  /// 
  /// 唯一の営業時間判定関数 - 全ての営業時間チェックはこの関数を使用
  /// 動作確認済みのロジックを統一実装
  static bool isCurrentlyOpen(GymHours hours) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    String? openTime;
    String? closeTime;
    
    switch (weekday) {
      case DateTime.sunday:
        openTime = hours.sunOpen;
        closeTime = hours.sunClose;
        break;
      case DateTime.monday:
        openTime = hours.monOpen;
        closeTime = hours.monClose;
        break;
      case DateTime.tuesday:
        openTime = hours.tueOpen;
        closeTime = hours.tueClose;
        break;
      case DateTime.wednesday:
        openTime = hours.wedOpen;
        closeTime = hours.wedClose;
        break;
      case DateTime.thursday:
        openTime = hours.thuOpen;
        closeTime = hours.thuClose;
        break;
      case DateTime.friday:
        openTime = hours.friOpen;
        closeTime = hours.friClose;
        break;
      case DateTime.saturday:
        openTime = hours.satOpen;
        closeTime = hours.satClose;
        break;
    }

    if (openTime == null || closeTime == null || openTime == '-' || closeTime == '-') {
      return false;
    }

    return time.compareTo(openTime) >= 0 && time.compareTo(closeTime) <= 0;
  }
}