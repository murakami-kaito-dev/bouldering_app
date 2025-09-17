/// 型変換ユーティリティ
/// 
/// 役割:
/// - ID型の安全な変換処理
/// - エラーハンドリングを含む型変換
/// - アプリ全体で一貫した型変換ルール
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - 共通ユーティリティ層
/// - 各層から参照可能
/// - ビジネスロジックの一部として型変換を管理
class TypeConverter {
  /// int型IDをString型に変換
  static String idToString(int id) {
    return id.toString();
  }
  
  /// String型IDをint型に安全に変換
  /// 変換失敗時はnullを返す
  static int? stringToId(String idString) {
    return int.tryParse(idString);
  }
  
  /// String型IDをint型に変換（例外をスロー）
  /// 変換失敗時はInvalidIdFormatExceptionをスロー
  static int stringToIdOrThrow(String idString) {
    final id = int.tryParse(idString);
    if (id == null) {
      throw InvalidIdFormatException('Invalid ID format: $idString');
    }
    return id;
  }
  
  /// 動的型からint型への安全な変換
  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
  
  /// 動的型からString型への変換
  static String toStringValue(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
}

/// 無効なID形式の例外
class InvalidIdFormatException implements Exception {
  final String message;
  
  InvalidIdFormatException(this.message);
  
  @override
  String toString() => 'InvalidIdFormatException: $message';
}