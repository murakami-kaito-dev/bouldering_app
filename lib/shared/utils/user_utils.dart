/// ユーザー関連のユーティリティ関数
/// 
/// 役割:
/// - ユーザー情報に関する共通の計算・変換処理
/// - 経験年数の計算
/// - ホームジム名の取得
/// 
/// クリーンアーキテクチャにおける位置づき:
/// - Shared層のUtility
/// - ドメインロジックを含まない純粋な変換・計算処理
library user_utils;

/// 経験年数の計算
/// 
/// ボルダリング開始日から現在までの経験年数を計算する
/// [startDate] ボルダリング開始日（null許容）
/// 戻り値: "X年Yヶ月" 形式の文字列
String calculateExperience(DateTime? startDate) {
  if (startDate == null) return '未設定';
  
  final now = DateTime.now();
  final difference = now.difference(startDate);
  final years = (difference.inDays / 365).floor();
  final months = ((difference.inDays % 365) / 30).floor();
  
  if (years > 0) {
    return '${years}年${months}ヶ月';
  } else {
    return '${months}ヶ月';
  }
}

/// ホームジム名の取得
/// 
/// ユーザーのホームジムIDから対応するジム名を取得する
/// [homeGymId] ホームジムのID（null許容）
/// [gymMap] ジム情報のマップ（ID -> ジム情報）
/// 戻り値: ジム名またはハイフン
String getHomeGymName(int? homeGymId, Map<int, dynamic>? gymMap) {
  if (homeGymId == null || homeGymId == 0 || gymMap == null || !gymMap.containsKey(homeGymId)) {
    return '-';
  }
  
  final gym = gymMap[homeGymId];
  // Gymエンティティのnameプロパティ、またはレガシー形式のgymNameを使用
  if (gym?.name != null) {
    return gym.name;
  } else if (gym?.gymName != null) {
    return gym.gymName;
  }
  return '-';
}