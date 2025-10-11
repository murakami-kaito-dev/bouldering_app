import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
// import 'mock_api_client.dart'; // Mock環境用

/// APIクライアントクラス
///
/// 役割:
/// - HTTPリクエストの共通処理を担当
/// - Firebase Authentication IDトークンの自動付与
/// - リクエストパラメータの構築とレスポンス処理
/// - エラーハンドリングの統一
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のサービスコンポーネント
/// - 外部APIとの通信を抽象化し、Repository実装で使用される
class ApiClient {
  final String baseUrl;
  final Duration timeout;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Mock環境での実装
  // final MockApiClient _mockApiClient = MockApiClient();

  /// コンストラクタ
  ///
  /// [baseUrl] APIのベースURL
  /// [timeout] リクエストタイムアウト時間（デフォルト30秒）
  ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  /// Firebase Auth IDトークンを取得
  ///
  /// 返り値:
  /// [String?] IDトークン（未認証の場合はnull）
  /// Firebase Auth IDトークンを取得
  /// 
  /// 返り値:
  /// [String?] IDトークン（未認証の場合はnull）
  Future<String?> _getIdToken() async {
    try {
      // 現在のユーザーを取得
      final user = _firebaseAuth.currentUser;
      
      // 未認証の場合はnullを返す
      if (user == null) {
        print('Firebase Auth: ユーザーは未ログイン状態');
        return null;
      }
      
      print('Firebase Auth: ログイン中のユーザーID: ${user.uid}');
      
      // IDトークンを取得して返す
      final token = await user.getIdToken();
      return token;
    } catch (e) {
      // トークン取得失敗時はnullを返す
      print('Firebase Auth: トークン取得エラー: $e');
      return null;
    }
  }

  /// 共通HTTPヘッダーを構築
  ///
  /// [requireAuth] 認証が必要かどうか（デフォルト: false）
  ///
  /// 返り値:
  /// [Map<String, String>] HTTPヘッダー
  Future<Map<String, String>> _buildHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // Firebase認証トークンを取得（ユーザーがログインしている場合のみ取得可能）
    // このトークンにはユーザーIDが含まれている
    final userIdToken = await _getIdToken();
    
    // 認証処理の分岐（3パターン）
    if (userIdToken != null) {
      // パターン1: ログイン中の場合
      // → 認証トークンをヘッダーに追加（ブロック機能などが有効になる）
      headers['Authorization'] = 'Bearer $userIdToken';
    } else if (requireAuth) {
      // パターン2: 未ログイン かつ 認証必須（requireAuth=true）の場合
      // → エラーを投げる（例：プロフィール編集など、ログイン必須の機能）
      throw ApiException('認証が必要ですが、ログインしていません');
    }
    // パターン3（else節なし）: 未ログイン かつ 認証任意（requireAuth=false）の場合
    // → そのまま続行（例：ツイート一覧表示。未ログインでも見られるが、ブロック機能は無効）

    return headers;
  }

  /// GETリクエストを実行
  ///
  /// [endpoint] APIエンドポイント（例: '/api/users'）
  /// [parameters] クエリパラメータのMap
  /// [requireAuth] 認証が必要かどうか（デフォルト: false）
  ///
  /// 返り値:
  /// [Map<String, dynamic>] レスポンスをJSON形式で返す
  ///
  /// 例外:
  /// [ApiException] APIエラーやネットワークエラー時にスロー
  Future<Map<String, dynamic>> get({
    required String endpoint,
    Map<String, String>? parameters,
    bool requireAuth = false,
  }) async {
    try {
      // URLの構築
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: parameters,
      );

      // ヘッダーの構築（認証が必要な場合はIDトークンを含む）
      final headers = await _buildHeaders(requireAuth: requireAuth);
      
      // デバッグ：認証情報の送信状況を確認
      print('API GET Request: $endpoint');
      print('RequireAuth: $requireAuth');
      print('Headers contain Authorization: ${headers.containsKey('Authorization')}');
      if (headers.containsKey('Authorization')) {
        print('Authorization header exists (token hidden for security)');
      }

      // GETリクエストの実行
      final response = await http
          .get(
            uri,
            headers: headers,
          )
          .timeout(timeout);

      // レスポンスの処理
      return _handleResponse(response);
    } catch (e) {
      // エラーを上位層に伝播
      throw ApiException('APIリクエストに失敗しました: $e');
    }
  }

  /// POSTリクエストを実行
  ///
  /// [endpoint] APIエンドポイント
  /// [body] リクエストボディ
  /// [parameters] クエリパラメータのMap
  /// [requireAuth] 認証が必要かどうか（デフォルト: true）
  Future<Map<String, dynamic>> post({
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? parameters,
    bool requireAuth = true,
  }) async {
    try {
      // URLの構築
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: parameters,
      );

      // ヘッダーの構築（認証が必要な場合はIDトークンを含む）
      final headers = await _buildHeaders(requireAuth: requireAuth);

      // POSTリクエストの実行
      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      // レスポンスの処理
      return _handleResponse(response);
    } catch (e) {
      // エラーを上位層に伝播
      throw ApiException('APIリクエストに失敗しました: $e');
    }
  }

  /// PUTリクエストを実行
  ///
  /// [endpoint] APIエンドポイント
  /// [body] リクエストボディ
  /// [parameters] クエリパラメータのMap
  /// [requireAuth] 認証が必要かどうか（デフォルト: true）
  Future<Map<String, dynamic>> put({
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? parameters,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: parameters,
      );

      // ヘッダーの構築（認証が必要な場合はIDトークンを含む）
      final headers = await _buildHeaders(requireAuth: requireAuth);

      // PUTリクエストの実行
      final response = await http
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      // レスポンスの処理
      return _handleResponse(response);
    } catch (e) {
      // エラーを上位層に伝播
      throw ApiException('APIリクエストに失敗しました: $e');
    }
  }

  /// PATCHリクエストを実行
  ///
  /// [endpoint] APIエンドポイント
  /// [body] リクエストボディ
  /// [parameters] クエリパラメータのMap
  /// [requireAuth] 認証が必要かどうか（デフォルト: true）
  Future<Map<String, dynamic>> patch({
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? parameters,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: parameters,
      );

      // ヘッダーの構築（認証が必要な場合はIDトークンを含む）
      final headers = await _buildHeaders(requireAuth: requireAuth);

      // PATCHリクエストの実行
      final response = await http
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      // レスポンスの処理
      return _handleResponse(response);
    } catch (e) {
      // エラーを上位層に伝播
      throw ApiException('APIリクエストに失敗しました: $e');
    }
  }

  /// DELETEリクエストを実行
  ///
  /// [endpoint] APIエンドポイント
  /// [parameters] クエリパラメータのMap
  /// [requireAuth] 認証が必要かどうか（デフォルト: true）
  Future<Map<String, dynamic>> delete({
    required String endpoint,
    Map<String, String>? parameters,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: parameters,
      );

      // ヘッダーの構築（認証が必要な場合はIDトークンを含む）
      final headers = await _buildHeaders(requireAuth: requireAuth);

      // DELETEリクエストの実行
      final response = await http
          .delete(
            uri,
            headers: headers,
          )
          .timeout(timeout);

      // レスポンスの処理
      return _handleResponse(response);
    } catch (e) {
      // エラーを上位层に伝播
      throw ApiException('APIリクエストに失敗しました: $e');
    }
  }

  /// レスポンス処理の共通ロジック
  ///
  /// [response] HTTPレスポンス
  ///
  /// 返り値:
  /// [Map<String, dynamic>] パースされたJSONレスポンス
  Map<String, dynamic> _handleResponse(http.Response response) {
    // 認証エラーを優先処理
    if (response.statusCode == 401) {
      throw ApiException(
        '認証エラー: ログインが必要です',
        statusCode: response.statusCode,
      );
    }

    // ステータスコードのチェック
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'APIエラー: Status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    try {
      // 204 No Contentの場合は成功として空のMapを返す
      if (response.statusCode == 204) {
        return {'success': true};
      }

      // レスポンスボディが空の場合も成功として扱う
      if (response.body.isEmpty) {
        return {'success': true};
      }

      // JSONのパース
      final responseBody = jsonDecode(response.body);

      // レスポンスがMapの場合はそのまま返す
      if (responseBody is Map<String, dynamic>) {
        return responseBody;
      }

      // レスポンスがListの場合は、dataキーでラップして返す
      if (responseBody is List) {
        return {'data': responseBody};
      }

      // その他の場合は値をラップして返す
      return {'value': responseBody};
    } catch (e) {
      throw ApiException('レスポンスのパースに失敗しました: $e');
    }
  }
}

/// API例外クラス
///
/// 役割:
/// - API関連のエラー情報を保持
/// - ステータスコードやエラーメッセージの管理
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}
