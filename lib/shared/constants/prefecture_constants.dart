/// 都道府県・地域データ定数クラス
/// 
/// 役割:
/// - 日本の都道府県データの一元管理
/// - 地域別グルーピング
/// - 検索・フィルタリング用データ提供
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Shared層の定数データ
/// - アプリケーション全体で使用される共通データ
class PrefectureConstants {
  /// 北海道・東北地方
  static const List<String> hokkaidoTohoku = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県'
  ];

  /// 関東地方
  static const List<String> kanto = [
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県'
  ];

  /// 北陸・甲信越地方
  static const List<String> hokurikuKoshinetsu = [
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県'
  ];

  /// 東海地方
  static const List<String> tokai = [
    '岐阜県', '静岡県', '愛知県', '三重県'
  ];

  /// 近畿地方
  static const List<String> kinki = [
    '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県'
  ];

  /// 中国・四国地方
  static const List<String> chugokuShikoku = [
    '鳥取県', '島根県', '岡山県', '広島県', '山口県', 
    '徳島県', '香川県', '愛媛県', '高知県'
  ];

  /// 九州・沖縄地方
  static const List<String> kyushuOkinawa = [
    '福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
  ];

  /// 全都道府県リスト
  static const List<String> allPrefectures = [
    ...hokkaidoTohoku,
    ...kanto,
    ...hokurikuKoshinetsu,
    ...tokai,
    ...kinki,
    ...chugokuShikoku,
    ...kyushuOkinawa,
  ];

  /// 地域マップ（地域名 -> 都道府県リスト）
  static const Map<String, List<String>> regionMap = {
    '北海道・東北': hokkaidoTohoku,
    '関東': kanto,
    '北陸・甲信越': hokurikuKoshinetsu,
    '東海': tokai,
    '近畿': kinki,
    '中国・四国': chugokuShikoku,
    '九州・沖縄': kyushuOkinawa,
  };

  /// 地域名リスト
  static List<String> get regionNames => regionMap.keys.toList();

  /// 指定した都道府県の地域名を取得
  static String? getRegionByPrefecture(String prefecture) {
    for (final entry in regionMap.entries) {
      if (entry.value.contains(prefecture)) {
        return entry.key;
      }
    }
    return null;
  }
}