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
  /// [userId] 新規作成するユーザーID
  /// [email] ユーザーのメールアドレス
  /// 
  /// 返り値:
  /// [bool] 作成成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. REST API: POST /api/users でユーザー作成
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> createUser(String userId, String email) async {
    try {
      // デフォルト値を含むユーザーデータを準備
      final requestBody = {
        'user_id': userId,
        'email': email,
        'user_name': '駆け出しボルダー',
        'user_introduce': '設定から自己紹介を記入しましょう！',
        'favorite_gym': '設定から好きなジムを記入しましょう！',
        'gender': 0,  // 0: 未設定
        'home_gym_id': null,
        'boul_start_date': DateTime.now().toIso8601String(),
      };
      
      // API通信でユーザーを作成
      final response = await _apiClient.post(
        endpoint: '/users',
        body: requestBody,
        requireAuth: false,  // 新規登録時は認証不要
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
      email: userData['email'] ?? '',
      userIconUrl: userData['user_icon_url'],
      userIntroduce: userData['user_introduce'],
      favoriteGym: userData['favorite_gym'],
      gender: userData['gender'],
      birthday: userData['birthday'] != null 
          ? DateTime.tryParse(userData['birthday']) 
          : null,
      boulStartDate: userData['boul_start_date'] != null 
          ? DateTime.tryParse(userData['boul_start_date']) 
          : null,
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
      final response = await _apiClient.delete(
        endpoint: '/users/$userId',
        requireAuth: true,  // 認証必要
      );

      // 削除成功を確認
      return response['success'] == true;
    } catch (e) {
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
  /// [email] 新しいメールアドレス
  /// 
  /// 返り値:
  /// [bool] 更新成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. REST API: PATCH /api/users/{userId}/email でメールアドレス更新
  /// 2. APIエラー時は例外を上位に伝播
  Future<bool> updateUserEmail(String userId, String email) async {
    try {
      // API通信でメールアドレスを更新
      final response = await _apiClient.patch(
        endpoint: '/users/$userId/email',
        body: {'email': email},
        requireAuth: true,  // 認証必要
      );

      // 更新成功を確認
      return response['success'] == true;
    } catch (e) {
      throw Exception('メールアドレス更新に失敗しました: $e');
    }
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
}