import 'dart:io';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../../domain/entities/user.dart';

/// ユーザーデータソースクラス
/// 
/// 役割:
/// - ユーザー関連のAPI通信を担当
/// - APIレスポンスとDomainエンティティ間の変換
/// - 外部APIの詳細を隠蔽し、Repository実装に抽象化されたインタフェースを提供
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のデータソースコンポーネント
/// - 外部API（バックエンド）との通信窓口
/// - Repository実装から呼び出される
class UserDataSource {
  final ApiClient _apiClient;
  final StorageService _storageService;

  /// コンストラクタ
  /// 
  /// [_apiClient] API通信クライアント
  /// [_storageService] ファイルストレージサービス
  UserDataSource(this._apiClient, this._storageService);

  /// ユーザーIDによるユーザー情報取得（自分のデータ用）
  /// 
  /// [userId] 取得対象のユーザーID
  /// 
  /// 返り値:
  /// [User?] ユーザーエンティティ、存在しない場合はnull
  /// 
  /// 処理フロー:
  /// 1. REST API: GET /api/users/{userId} でユーザー情報取得（認証必要）
  /// 2. APIエラー時は例外を上位に伝播
  Future<User?> getUserById(String userId) async {
    try {
      // API通信でユーザー情報を取得
      final response = await _apiClient.get(
        endpoint: '/users/$userId',
        requireAuth: true,  // 認証必要（自分のデータのみ）
      );

      // レスポンスからユーザーデータを抽出
      final userData = response['data'];
      if (userData == null) {
        return null;
      }
      
      // エンティティに変換して返却
      return _mapToUserEntity(userData);
    } on ApiException catch (e) {
      // 404 = DB にまだ行が無い（SNS ログイン直後の未登録状態）。呼び出し側が登録へ進む
      if (e.statusCode == 404) return null;
      throw Exception('ユーザー情報の取得に失敗しました: $e');
    } catch (e) {
      throw Exception('ユーザー情報の取得に失敗しました: $e');
    }
  }

  /// 他のユーザーの公開プロフィール取得
  /// 
  /// [userId] 取得対象のユーザーID
  /// 
  /// 返り値:
  /// [User?] ユーザーエンティティ、存在しない場合はnull
  /// 
  /// 処理フロー:
  /// 1. REST API: GET /api/users/{userId}/profile でユーザー公開プロフィール取得（認証不要）
  /// 2. APIエラー時は例外を上位に伝播
  Future<User?> getUserProfile(String userId) async {
    try {
      // API通信で他ユーザーの公開プロフィールを取得
      final response = await _apiClient.get(
        endpoint: '/users/$userId/profile',
        requireAuth: false,  // 認証不要（公開プロフィール）
      );

      // レスポンスからユーザーデータを抽出
      final userData = response['data'];
      if (userData == null) {
        return null;
      }
      
      // エンティティに変換して返却
      return _mapToUserEntity(userData);
    } catch (e) {
      throw Exception('他ユーザープロフィールの取得に失敗しました: $e');
    }
  }

  /// 新規ユーザー作成
  /// 
  /// [userId] 新規作成するユーザーID（Firebase uid）
  /// 
  /// 返り値:
  /// [bool] 作成成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. REST API: POST /api/users でユーザー作成（要認証。本人の uid のみ作れる）
  /// 2. APIエラー時は例外を上位に伝播
  /// メールアドレスは送らない（設定画面から任意で登録する）
  Future<bool> createUser(String userId) async {
    try {
      // デフォルト値を含むユーザーデータを準備
      final requestBody = {
        'user_id': userId,
        'user_name': '駆け出しボルダー',
        'user_introduce': '設定から自己紹介を記入しましょう！',
        'favorite_gym': '設定から好きなジムを記入しましょう！',
        'gender': 0,  // 0: 未設定
        'home_gym_id': null,
        // DATE 列なので日付だけを送る（時刻付きの ISO 文字列だとサーバー側 UTC 解釈で日付がずれる）
        'boul_start_date': _formatDate(DateTime.now()),
      };
      
      // API通信でユーザーを作成（Firebase ログイン済みなのでトークンを付ける）
      final response = await _apiClient.post(
        endpoint: '/users',
        body: requestBody,
        requireAuth: true,
      );

      // 作成成功を確認
      return response['success'] == true;
    } catch (e) {
      throw Exception('ユーザー作成に失敗しました: $e');
    }
  }

  /// ユーザー名更新
  /// 
  /// [userId] 更新対象のユーザーID
  /// [userName] 新しいユーザー名
  /// 
  /// 返り値:
  /// [bool] 更新成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. REST API: PATCH /api/users/{userId} でユーザー名更新
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> updateUserName(String userId, String userName) async {
    try {
      // API通信でユーザー名を更新
      final response = await _apiClient.patch(
        endpoint: '/users/$userId',
        body: {'user_name': userName},
      );

      // 更新成功を確認
      final success = response['success'] == true;
      
      return success;
    } catch (e) {
      throw Exception('ユーザー名の更新に失敗しました: $e');
    }
  }

  /// ユーザーアイコンURL更新
  /// 
  /// [userId] 更新対象のユーザーID
  /// [iconUrl] 新しいアイコンのURL
  /// 
  /// 返り値:
  /// [bool] 更新成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. REST API: PATCH /api/users/{userId} でアイコンURL更新
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> updateUserIconUrl(String userId, String iconUrl) async {
    try {
      // API通信でアイコンURLを更新
      final response = await _apiClient.patch(
        endpoint: '/users/$userId/icon-url',
        body: {'user_icon_url': iconUrl},
      );

      // 更新成功を確認
      final success = response['success'] == true;
      
      return success;
    } catch (e) {
      throw Exception('ユーザーアイコンURLの更新に失敗しました: $e');
    }
  }

  /// ユーザープロフィール情報更新
  /// 
  /// [userId] 更新対象のユーザーID
  /// [userIntroduce] 自己紹介文（オプション）
  /// [favoriteGym] お気に入りジム（オプション）
  /// 
  /// 返り値:
  /// [bool] 更新成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. REST API: PATCH /api/users/{userId} でプロフィール更新（単一リクエスト）
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> updateUserProfile({
    required String userId,
    String? userIntroduce,
    String? favoriteGym,
  }) async {
    try {
      // バックエンドAPIの仕様に合わせて、自己紹介とお気に入りジムを個別に更新
      bool success = true;
      
      // 自己紹介の更新（"-"の場合も更新される）
      if (userIntroduce != null) {
        final response = await _apiClient.patch(
          endpoint: '/users/$userId/profile/texts',
          body: {
            'description': userIntroduce,
            'type': 'true'  // バックエンドの仕様に合わせて 'true' = user_introduce
          },
        );
        success &= response['success'] == true;
      }
      
      // お気に入りジムの更新（"-"の場合も更新される）
      if (favoriteGym != null) {
        final response = await _apiClient.patch(
          endpoint: '/users/$userId/profile/texts',
          body: {
            'description': favoriteGym,
            'type': 'false'  // バックエンドの仕様に合わせて 'false' = favorite_gym
          },
        );
        success &= response['success'] == true;
      }
      
      return success;
    } catch (e) {
      throw Exception('プロフィール情報の更新に失敗しました: $e');
    }
  }

  /// ユーザー性別更新
  /// 
  /// [userId] 更新対象のユーザーID
  /// [gender] 性別（1: 男性, 2: 女性, 0: 未回答）
  /// 
  /// 返り値:
  /// [bool] 更新成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. REST API: PATCH /api/users/{userId}/gender で性別更新
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> updateUserGender(String userId, int gender) async {
    try {
      // API通信で性別情報を更新
      final response = await _apiClient.patch(
        endpoint: '/users/$userId/gender',
        body: {'gender': gender},
      );

      // 更新成功を確認
      final success = response['success'] == true;
      
      return success;
    } catch (e) {
      throw Exception('性別情報の更新に失敗しました: $e');
    }
  }

  /// ユーザーの日付情報更新
  /// 
  /// [userId] 更新対象のユーザーID
  /// [birthday] 生年月日（オプション）
  /// [boulStartDate] ボルダリング開始日（オプション）
  /// 
  /// 返り値:
  /// [bool] 更新成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. REST API: PATCH /api/users/{userId}/dates で日付情報更新
  /// 2. バックエンドは update_date と is_bouldering_debut を期待
  /// 3. APIエラー時は例外を上位に伝播
  Future<bool> updateUserDates({
    required String userId,
    DateTime? birthday,
    DateTime? boulStartDate,
  }) async {
    try {
      bool allSuccess = true;
      
      // 誕生日の更新
      if (birthday != null) {
        final updateDateStr = _formatDate(birthday);
        
        final response = await _apiClient.patch(
          endpoint: '/users/$userId/dates',
          body: {
            'update_date': updateDateStr,
            'is_bouldering_debut': false,  // false = 誕生日
          },
        );
        
        if (response['success'] != true) {
          allSuccess = false;
        }
      }
      
      // ボルダリング開始日の更新
      if (boulStartDate != null) {
        final updateDateStr = _formatDate(boulStartDate);
        
        final response = await _apiClient.patch(
          endpoint: '/users/$userId/dates',
          body: {
            'update_date': updateDateStr,
            'is_bouldering_debut': true,  // true = ボルダリング開始日
          },
        );
        
        if (response['success'] != true) {
          allSuccess = false;
        }
      }
      
      // 更新対象がない場合は成功として処理
      if (birthday == null && boulStartDate == null) {
        return true;
      }
      
      return allSuccess;
    } catch (e) {
      throw Exception('日付情報の更新に失敗しました: $e');
    }
  }

  /// ホームジム更新
  /// 
  /// [userId] 更新対象のユーザーID
  /// [gymId] 新しいホームジムのID
  /// 
  /// 返り値:
  /// [bool] 更新成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. REST API: PATCH /api/users/{userId} でホームジム更新
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> updateHomeGym(String userId, int gymId) async {
    try {
      // API通信でホームジムを更新
      final response = await _apiClient.patch(
        endpoint: '/users/$userId/home-gym',
        body: {'home_gym_id': gymId},
      );

      // 更新成功を確認
      final success = response['success'] == true;
      
      return success;
    } catch (e) {
      throw Exception('ホームジムの更新に失敗しました: $e');
    }
  }

  /// ユーザーアイコン画像アップロード
  /// 
  /// [imagePath] アップロードする画像ファイルのパス
  /// [userId] ユーザーID
  /// 
  /// 返り値:
  /// [String?] アップロード成功時は公開URL、失敗時はnull
  Future<String?> uploadUserIcon(String imagePath, {required String userId}) async {
    try {
      // 画像ファイルを準備
      final imageFile = File(imagePath);
      
      // ストレージサービスでアイコンをアップロード
      final result = await _storageService.uploadUserIcon(imageFile, userId: userId);
      
      return result;
    } catch (e) {
      throw Exception('ユーザーアイコンのアップロードに失敗しました: $e');
    }
  }

  /// APIレスポンスからUserエンティティにマッピング
  /// 
  /// [userData] APIから取得したユーザーデータ
  /// 
  /// 返り値:
  /// [User] ユーザーエンティティ
  User _mapToUserEntity(Map<String, dynamic> userData) {
    return User(
      id: userData['user_id']?.toString() ?? '',
      userName: userData['user_name'] ?? '',
      email: userData['email'] as String?,
      userIconUrl: userData['user_icon_url'],
      userIntroduce: userData['user_introduce'],
      favoriteGym: userData['favorite_gym'],
      gender: userData['gender'],
      birthday: _parseDateOnly(userData['birthday']),
      boulStartDate: _parseDateOnly(userData['boul_start_date']),
      homeGymId: userData['home_gym_id'],
    );
  }

  /// ユーザー削除
  /// 
  /// [userId] 削除対象のユーザーID
  /// 
  /// 返り値:
  /// [bool] 削除成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. REST API: DELETE /api/users/{userId} でユーザー削除
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> deleteUser(String userId) async {
    try {
      // API通信でユーザーを削除
      print('[DEBUG] DB削除API呼び出し開始 - userId: $userId');
      
      final response = await _apiClient.delete(
        endpoint: '/users/$userId',
        requireAuth: true,  // 認証必要
      );
      
      // レスポンスの詳細をログ出力
      print('[DEBUG] DB削除APIレスポンス: $response');
      print('[DEBUG] response type: ${response.runtimeType}');
      
      // レスポンスがMapの場合
      if (response is Map) {
        print('[DEBUG] success field: ${response['success']}');
        return response['success'] == true;
      }
      
      // レスポンスがMap以外の場合（nullや他の型）
      print('[DEBUG] 予期しないレスポンス形式');
      return false;
      
    } catch (e) {
      print('[ERROR] DB削除API呼び出しエラー: $e');
      throw Exception('ユーザー削除に失敗しました: $e');
    }
  }

  /// ユーザーの月間統計情報を取得
  /// 
  /// [userId] ユーザーのID
  /// [monthsAgo] 何ヶ月前の統計を取得するか（0: 今月、1: 先月）
  /// 
  /// 返り値:
  /// 月間統計情報のJSONデータ
  /// 
  /// エラーハンドリング:
  /// - ユーザーが存在しない場合は404エラー
  /// - 認証エラーの場合は401エラー
  Future<Map<String, dynamic>> getMonthlyStatistics(String userId, int monthsAgo) async {
    try {
      // API通信で月間統計を取得
      final response = await _apiClient.get(
        endpoint: '/users/$userId/stats/monthly',
        parameters: {'months_ago': monthsAgo.toString()},
        requireAuth: false,  // 認証不要（公開統計情報）
      );
      
      // 統計データを返却
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('月間統計の取得に失敗しました: $e');
    }
  }

  /// ユーザーのメールアドレス更新
  /// 
  /// [userId] 更新対象のユーザーID
  /// [email] 登録するメールアドレス。null なら未登録に戻す
  /// 
  /// 返り値:
  /// [bool] 更新成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. REST API: PATCH /api/users/{userId}/email
  ///    バックエンドは body の値を信用せず、Firebase トークンに載っている
  ///    「本人確認済みのメールアドレス」を保存する（body は null=削除 の指示にだけ使う）
  /// 2. 重複（409）等の ApiException はそのまま上位へ伝播（UseCase が判定する）
  Future<bool> updateUserEmail(String userId, String? email) async {
    final response = await _apiClient.patch(
      endpoint: '/users/$userId/email',
      body: {'email': email},
      requireAuth: true, // 認証必要
    );
    return response['success'] == true;
  }

  /// 通知用メールアドレスの登録申請（本人確認メールの送信）
  ///
  /// [userId] 本人の uid / [email] 登録したいメールアドレス
  ///
  /// 返り値: 'sent'（確認メールを送った）/ 'already_registered'（既にそのメールで登録済み）
  ///
  /// 処理フロー:
  /// 1. REST API: POST /api/users/{userId}/email/request（要認証）
  /// 2. バックエンドが Brevo で確認メールを送り、リンク押下で DB に確定する
  /// 3. 409（別アカウントで登録済み）/ 429（連打）/ 503（未設定）等は ApiException のまま上位へ
  Future<String> requestEmailVerification(String userId, String email) async {
    final response = await _apiClient.post(
      endpoint: '/users/$userId/email/request',
      body: {'email': email},
      requireAuth: true,
    );
    final data = response['data'];
    return (data is Map && data['state'] is String) ? data['state'] as String : 'sent';
  }

  /// 日付をAPIで使用する形式にフォーマット
  /// 
  /// [date] フォーマット対象の日付
  /// 
  /// 返り値:
  /// [String] YYYY-MM-DD形式の日付文字列
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// DATE 列（生年月日・ボルダリング開始日）を「その日の 0 時（端末のローカル）」として読む
  ///
  /// バックエンドは DATE を "2026-09-05T00:00:00.000Z" のように UTC 深夜の時刻付きで返す。
  /// これを DateTime.parse でそのまま使うと日本では 09:00 になり、当日の午前中に
  /// 「未来の日付」と誤判定される（保存時の日付チェックで失敗する原因になっていた）
  DateTime? _parseDateOnly(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
    if (m != null) {
      return DateTime(
          int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
    }
    return DateTime.tryParse(s);
  }
}
