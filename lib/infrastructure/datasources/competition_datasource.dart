import '../../domain/entities/competition.dart';
import '../services/api_client.dart';

/// コンペティションデータソース（デモ機能）
///
/// 役割:
/// - コンペ API との通信と、JSON → エンティティ変換
/// - サーバーのエラーコード（403/404/409 等）は [CompetitionApiException] に包んで上位へ伝える
///   （画面が「権限がない」「開催期間外」などを案内できるようにする）
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure 層のデータソース
class CompetitionDataSource {
  final ApiClient _apiClient;

  CompetitionDataSource(this._apiClient);

  /// GET /api/competitions（任意認証。ログイン時はホームジムのコンペが先頭）
  Future<List<Competition>> getActiveCompetitions() async {
    final response = await _call(() => _apiClient.get(
          endpoint: '/competitions',
          requireAuth: false,
        ));
    return _toList(response['data']);
  }

  /// GET /api/competitions/hosted（要認証）
  Future<List<Competition>> getHostedCompetitions() async {
    final response = await _call(() => _apiClient.get(
          endpoint: '/competitions/hosted',
          requireAuth: true,
        ));
    return _toList(response['data']);
  }

  /// GET /api/competitions/joined（要認証）
  Future<List<Competition>> getJoinedCompetitions() async {
    final response = await _call(() => _apiClient.get(
          endpoint: '/competitions/joined',
          requireAuth: true,
        ));
    return _toList(response['data']);
  }

  /// GET /api/competitions/{id}
  Future<Competition> getCompetition(int competitionId) async {
    final response = await _call(() => _apiClient.get(
          endpoint: '/competitions/$competitionId',
          requireAuth: false,
        ));
    return Competition.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// POST /api/competitions（要認証・ジム管理者のみ）
  Future<Competition> createCompetition(CompetitionInput input) async {
    final response = await _call(() => _apiClient.post(
          endpoint: '/competitions',
          body: input.toJson(),
          requireAuth: true,
        ));
    return Competition.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// PATCH /api/competitions/{id}（要認証・開催者のみ）
  Future<Competition> updateCompetition(int competitionId, CompetitionInput input) async {
    final response = await _call(() => _apiClient.patch(
          endpoint: '/competitions/$competitionId',
          body: input.toJson(),
          requireAuth: true,
        ));
    return Competition.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// POST /api/competitions/{id}/entries（要認証・開催中のみ・冪等）
  Future<Competition> joinCompetition(int competitionId) async {
    final response = await _call(() => _apiClient.post(
          endpoint: '/competitions/$competitionId/entries',
          requireAuth: true,
        ));
    return Competition.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// GET /api/competitions/{id}/leaderboard
  Future<CompetitionLeaderboard> getLeaderboard(int competitionId) async {
    final response = await _call(() => _apiClient.get(
          endpoint: '/competitions/$competitionId/leaderboard',
          requireAuth: false,
        ));
    return CompetitionLeaderboard.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// PUT / DELETE /api/competitions/{id}/results/{problemNo}
  Future<Set<int>> setProblemCompleted(int competitionId, int problemNo, bool completed) async {
    final endpoint = '/competitions/$competitionId/results/$problemNo';
    final response = await _call(() => completed
        ? _apiClient.put(endpoint: endpoint, requireAuth: true)
        : _apiClient.delete(endpoint: endpoint, requireAuth: true));
    final data = response['data'] as Map<String, dynamic>;
    final list = data['completed_problems'] as List<dynamic>? ?? const [];
    return list.map((e) => (e as num).toInt()).toSet();
  }

  List<Competition> _toList(dynamic data) {
    final List<dynamic> items = data ?? [];
    return items.map((e) => Competition.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// ステータスコード付きの API エラーを、画面が案内文に変換できる例外へ包み替える
  Future<Map<String, dynamic>> _call(Future<Map<String, dynamic>> Function() request) async {
    try {
      return await request();
    } on ApiException catch (e) {
      throw CompetitionApiException(statusCode: e.statusCode, message: e.message);
    }
  }
}

/// コンペ API のエラー（ステータスコードで原因を判定できる）
class CompetitionApiException implements Exception {
  final int? statusCode;
  final String message;

  const CompetitionApiException({this.statusCode, required this.message});

  /// 利用者向けの説明
  String get displayMessage {
    switch (statusCode) {
      case 401:
        return 'ログインが必要です';
      case 403:
        return 'この操作を行う権限がありません';
      case 404:
        return 'コンペが見つかりません';
      case 409:
        return 'このコンペは開催期間外です';
      case 400:
        return '入力内容を確認してください';
      default:
        return '通信に失敗しました。時間をおいて再度お試しください';
    }
  }

  @override
  String toString() => 'CompetitionApiException($statusCode): $message';
}
