import '../../domain/entities/gym.dart';

/// 都道府県の地理的順序（北から南）でジムをソートするユーティリティ
/// 
/// 役割:
/// - 都道府県の地理的な順序を定義
/// - 同一都道府県内では名前のあいうえお順でソート
/// - 英語名・漢字名にも対応
class PrefectureOrderUtils {
  
  /// 都道府県の地理的順序（北海道→本州→四国→九州→沖縄）
  static const List<String> _prefectureOrder = [
    // 北海道
    '北海道',
    
    // 東北
    '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    
    // 関東
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    
    // 中部
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県', '静岡県', '愛知県',
    
    // 関西
    '三重県', '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県',
    
    // 中国
    '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    
    // 四国
    '徳島県', '香川県', '愛媛県', '高知県',
    
    // 九州
    '福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県',
    
    // 沖縄
    '沖縄県',
  ];
  
  /// 都道府県の順序インデックスを取得
  /// 
  /// [prefecture] 都道府県名
  /// 
  /// 返り値:
  /// [int] 順序インデックス（見つからない場合は999を返す）
  static int _getPrefectureOrder(String prefecture) {
    final index = _prefectureOrder.indexOf(prefecture);
    return index == -1 ? 999 : index; // 見つからない場合は最後に配置
  }
  
  /// ジムリストを地理的順序でソート
  /// 
  /// [gyms] ソート対象のジムリスト
  /// 
  /// 返り値:
  /// [List<Gym>] 地理的順序でソートされたジムリスト
  static List<Gym> sortGymsByGeographicOrder(List<Gym> gyms) {
    final sortedGyms = List<Gym>.from(gyms);
    
    sortedGyms.sort((a, b) {
      // 1. まず都道府県の地理的順序で比較
      final prefOrderA = _getPrefectureOrder(a.prefecture);
      final prefOrderB = _getPrefectureOrder(b.prefecture);
      
      if (prefOrderA != prefOrderB) {
        return prefOrderA.compareTo(prefOrderB);
      }
      
      // 2. 同じ都道府県内では名前のあいうえお順で比較
      // Collatorを使用して日本語の文字順序に対応
      return a.name.compareTo(b.name);
    });
    
    return sortedGyms;
  }
  
  /// デバッグ用：都道府県の順序を確認
  /// 
  /// [gyms] 確認対象のジムリスト
  /// 
  /// 返り値:
  /// [Map<String, List<String>>] 都道府県ごとのジム名リスト
  static Map<String, List<String>> getGymsByPrefecture(List<Gym> gyms) {
    final result = <String, List<String>>{};
    
    for (final gym in gyms) {
      if (!result.containsKey(gym.prefecture)) {
        result[gym.prefecture] = [];
      }
      result[gym.prefecture]!.add(gym.name);
    }
    
    // 都道府県ごとにジム名をソート
    for (final prefecture in result.keys) {
      result[prefecture]!.sort();
    }
    
    return result;
  }
  
  /// 都道府県リストを地理的順序で取得
  /// 
  /// 返り値:
  /// [List<String>] 地理的順序の都道府県リスト
  static List<String> get prefectureOrder => List.from(_prefectureOrder);
}