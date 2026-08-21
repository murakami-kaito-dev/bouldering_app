/// インフラ層: データソース（外部との実際の通信担当）
///
/// 本体の対応箇所: lib/infrastructure/datasources/gym_datasource.dart
///   （本体は ApiClient で Cloud Run の GET /api/gyms を叩く）
///
/// 要点:
/// - 外部仕様（JSONのキー名、snake_case、型の揺れ）はこの層で吸収する
/// - ここより内側（domain）に Map<String, dynamic> を漏らさない
class GymDataSource {
  /// サーバのJSONレスポンスを模した生データ。
  /// キーが snake_case なのは実際のAPI仕様に合わせている。
  Future<List<Map<String, dynamic>>> fetchGymsJson() async {
    await Future.delayed(const Duration(milliseconds: 400)); // 通信の代わり
    return [
      {'gym_id': 3, 'gym_name': 'Bホルド', 'prefecture': '大阪府', 'is_bouldering_gym': true},
      {'gym_id': 1, 'gym_name': 'Aウォール', 'prefecture': '東京都', 'is_bouldering_gym': true},
      {'gym_id': 4, 'gym_name': 'Dリード専門', 'prefecture': '東京都', 'is_bouldering_gym': false},
      {'gym_id': 2, 'gym_name': 'Cクライム', 'prefecture': '福岡県', 'is_bouldering_gym': true},
    ];
  }
}
