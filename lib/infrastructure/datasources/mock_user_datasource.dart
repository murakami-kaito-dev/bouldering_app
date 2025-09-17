import '../../domain/entities/user.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/config/environment_config.dart';
import 'user_datasource.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

/// モック用ユーザーデータソース（ローカル完結）
///
/// 役割:
/// - テスト・デモ用のユーザーデータソース
/// - MockDataからユーザー情報を取得（ローカル完結、クラウドサービス不使用）
/// - ネットワーク接続不要で動作確認可能
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のモック実装
/// - UserDataSourceと同じインタフェースを実装
///
/// 注意: このクラスは本当のMock実装です。
/// 開発環境・本番環境では通常のUserDataSourceを使用し、
/// ApiClientとStorageServiceの設定で環境を切り替えます。
class MockUserDataSource extends UserDataSource {
  MockUserDataSource()
      : super(
            ApiClient(baseUrl: EnvironmentConfig.apiEndpoint),
            StorageService(
              bucketName: 'bouldering-app-media-dev',
              serviceAccountPath: 'assets/keys/gcs_storage_dev.json',
            ));

  /// DIコンテナからサービスを注入するためのコンストラクタ（Mock実装では使用しない）
  MockUserDataSource.withServices(
      ApiClient apiClient, StorageService storageService)
      : super(apiClient, storageService);

  @override
  Future<User?> getUserById(String userId) async {
    // ローカルのMockDataからユーザー情報を取得（クラウドサービス不使用）
    await Future.delayed(const Duration(milliseconds: 100));

    // MockDataからユーザー情報を取得
    return MockData.mockUsers[userId];
  }

  @override
  Future<bool> createUser(String userId, String email) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // MockDataにユーザーを作成
    return MockData.createUser(userId, email);
  }

  @override
  Future<bool> updateUserName(String userId, String userName) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final user = MockData.mockUsers[userId];
    if (user == null) return false;

    // copyWithを使用して更新
    MockData.mockUsers[userId] = user.copyWith(userName: userName);
    return true;
  }

  @override
  Future<bool> updateUserIconUrl(String userId, String iconUrl) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final user = MockData.mockUsers[userId];
    if (user == null) return false;

    MockData.mockUsers[userId] = user.copyWith(userIconUrl: iconUrl);
    return true;
  }

  @override
  Future<bool> updateUserProfile({
    required String userId,
    String? userIntroduce,
    String? favoriteGym,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final user = MockData.mockUsers[userId];
    if (user == null) return false;

    MockData.mockUsers[userId] = user.copyWith(
      userIntroduce: userIntroduce ?? user.userIntroduce,
      favoriteGym: favoriteGym ?? user.favoriteGym,
    );
    return true;
  }

  @override
  Future<bool> updateUserGender(String userId, int gender) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final user = MockData.mockUsers[userId];
    if (user == null) return false;

    MockData.mockUsers[userId] = user.copyWith(gender: gender);
    return true;
  }

  @override
  Future<bool> updateUserDates({
    required String userId,
    DateTime? birthday,
    DateTime? boulStartDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final user = MockData.mockUsers[userId];
    if (user == null) return false;

    MockData.mockUsers[userId] = user.copyWith(
      birthday: birthday ?? user.birthday,
      boulStartDate: boulStartDate ?? user.boulStartDate,
    );
    return true;
  }

  @override
  Future<bool> updateHomeGym(String userId, int gymId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final user = MockData.mockUsers[userId];
    if (user == null) return false;

    MockData.mockUsers[userId] = user.copyWith(homeGymId: gymId);
    return true;
  }

  @override
  Future<String?> uploadUserIcon(String imagePath, {required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // ローカル環境では仮のURLを返す（実際のGCSは使用しない）
    return 'https://via.placeholder.com/100/4ECDC4/FFFFFF?text=UPLOADED';
  }
}
