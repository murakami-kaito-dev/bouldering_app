import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Shared
import '../../shared/config/environment_config.dart';

// Domain Services
import '../../domain/services/auth_service.dart';
import '../../domain/services/image_picker_service.dart';

// Infrastructure
import '../../infrastructure/services/api_client.dart';
import '../../infrastructure/services/storage_service.dart';
import '../../infrastructure/services/firebase_auth_service.dart';
import '../../infrastructure/services/image_picker_service_impl.dart';
import '../../infrastructure/datasources/user_datasource.dart';
// Mock実装（テスト時のみ使用）
// import '../../infrastructure/datasources/mock_user_datasource.dart';
import '../../infrastructure/datasources/gym_datasource.dart';
import '../../infrastructure/datasources/tweet_datasource.dart';
import '../../infrastructure/datasources/favorite_datasource.dart';
import '../../infrastructure/repositories/user_repository_impl.dart';
import '../../infrastructure/repositories/gym_repository_impl.dart';
import '../../infrastructure/repositories/tweet_repository_impl.dart';
import '../../infrastructure/repositories/favorite_repository_impl.dart';
import '../../infrastructure/repositories/storage_repository_impl.dart';

// Domain
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/gym_repository.dart';
import '../../domain/repositories/tweet_repository.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/user_usecases.dart';
import '../../domain/usecases/gym_usecases.dart';
import '../../domain/usecases/tweet_usecases.dart';
import '../../domain/usecases/favorite_usecases.dart';
import '../../domain/usecases/activity_post_usecases.dart';
import '../../domain/usecases/get_monthly_statistics_usecase.dart';
import '../../domain/usecases/image_picker_usecases.dart';
import '../../domain/usecases/get_user_favorite_gyms_usecase.dart';

/// 依存関係注入（DI）コンテナ
///
/// 役割:
/// - アプリケーション全体の依存関係を管理
/// - クリーンアーキテクチャの依存関係逆転原則を実現
/// - シングルトンパターンでインスタンス管理
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のDIコンテナ
/// - 各層の具象クラスを抽象インタフェースにバインド
/// - アプリケーション起動時に初期化される

// ==================== Infrastructure層 ====================

/// 認証サービスProvider
///
/// Firebase Authenticationサービスの提供
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

/// APIクライアントProvider
///
/// 環境設定に基づいてベースURLを設定
/// 開発環境・本番環境で異なるAPIサーバーに自動接続
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: EnvironmentConfig.apiEndpoint);
});

/// ストレージサービスProvider
///
/// Google Cloud Storageの設定
/// 環境に応じて開発用・本番用バケットとサービスアカウントを切り替え
final storageServiceProvider = Provider<StorageService>((ref) {
  // Flutter Flavorに応じてバケット名とサービスアカウントパスを設定
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  const flutterAppFlavor =
      String.fromEnvironment('FLUTTER_APP_FLAVOR', defaultValue: 'Runner Dev');
  const environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  // デバッグ用：環境変数の値を確認
  debugPrint('🔍 [STORAGE DEBUG] FLAVOR: $flavor');
  debugPrint('🔍 [STORAGE DEBUG] FLUTTER_APP_FLAVOR: $flutterAppFlavor');
  debugPrint('🔍 [STORAGE DEBUG] ENVIRONMENT: $environment');

  late String bucketName;
  late String serviceAccountPath;

  // ENVIRONMENTが正しく渡されているため、ENVIRONMENTを使用
  switch (environment) {
    case 'prod':
      bucketName = 'bouldering-app-media-prod';
      serviceAccountPath = 'assets/keys/gcs_storage_prod.json';
      debugPrint('🔍 [STORAGE DEBUG] 本番環境のGCSバケットを選択: $bucketName');
      break;
    case 'dev':
    default:
      bucketName = 'bouldering-app-media-dev';
      serviceAccountPath = 'assets/keys/gcs_storage_dev.json';
      debugPrint('🔍 [STORAGE DEBUG] 開発環境のGCSバケットを選択: $bucketName');
      break;
  }

  return StorageService(
    bucketName: bucketName,
    serviceAccountPath: serviceAccountPath,
  );
});

/// ユーザーデータソースProvider
final userDataSourceProvider = Provider<UserDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final storageService = ref.read(storageServiceProvider);

  // 開発環境・本番環境での実装（実際のクラウドサービスを使用）
  return UserDataSource(apiClient, storageService);

  // Mock実装（テスト時のみ使用、ローカル完結）:
  // return MockUserDataSource.withServices(apiClient, storageService);
});

/// ジムデータソースProvider
///
/// 統合APIクライアントを使用（全てのAPIが同じCloud Runサービスで提供されるため）
final gymDataSourceProvider = Provider<GymDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);

  return GymDataSource(apiClient);
});

/// ツイートデータソースProvider
final tweetDataSourceProvider = Provider<TweetDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final storageService = ref.read(storageServiceProvider);

  return TweetDataSource(apiClient, storageService);
});

/// お気に入りデータソースProvider
final favoriteDataSourceProvider = Provider<FavoriteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);

  return FavoriteDataSource(apiClient);
});

// ==================== Repository層（抽象化） ====================

/// ユーザーリポジトリProvider
///
/// Domain層のUserRepositoryインタフェースを実装
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dataSource = ref.read(userDataSourceProvider);

  return UserRepositoryImpl(dataSource);
});

/// ジムリポジトリProvider
///
/// Domain層のGymRepositoryインタフェースを実装
final gymRepositoryProvider = Provider<GymRepository>((ref) {
  final dataSource = ref.read(gymDataSourceProvider);

  return GymRepositoryImpl(dataSource);
});

/// ツイートリポジトリProvider
///
/// Domain層のTweetRepositoryインタフェースを実装
final tweetRepositoryProvider = Provider<TweetRepository>((ref) {
  final dataSource = ref.read(tweetDataSourceProvider);

  return TweetRepositoryImpl(dataSource);
});

/// お気に入りリポジトリProvider
///
/// Domain層のFavoriteRepositoryインタフェースを実装
final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  final dataSource = ref.read(favoriteDataSourceProvider);

  return FavoriteRepositoryImpl(dataSource);
});

/// ストレージリポジトリProvider
///
/// Domain層のStorageRepositoryインタフェースを実装
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final storageService = ref.read(storageServiceProvider);

  return StorageRepositoryImpl(storageService);
});

// ==================== UseCase層 ====================

/// 認証関連ユースケースProvider
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final userRepository = ref.read(userRepositoryProvider);

  return LoginUseCase(userRepository);
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  final userRepository = ref.read(userRepositoryProvider);

  return SignUpUseCase(userRepository);
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  final authService = ref.read(authServiceProvider);

  return ChangePasswordUseCase(authService);
});

final passwordResetUseCaseProvider = Provider<PasswordResetUseCase>((ref) {
  final authService = ref.read(authServiceProvider);

  return PasswordResetUseCase(authService);
});

/// ユーザー関連ユースケースProvider
final updateUserProfileUseCaseProvider =
    Provider<UpdateUserProfileUseCase>((ref) {
  final userRepository = ref.read(userRepositoryProvider);

  return UpdateUserProfileUseCase(userRepository);
});

final updateUserIconUseCaseProvider = Provider<UpdateUserIconUseCase>((ref) {
  final userRepository = ref.read(userRepositoryProvider);

  return UpdateUserIconUseCase(userRepository);
});

final deleteUserUseCaseProvider = Provider<DeleteUserUseCase>((ref) {
  final userRepository = ref.read(userRepositoryProvider);

  return DeleteUserUseCase(userRepository);
});

final updateUserEmailUseCaseProvider = Provider<UpdateUserEmailUseCase>((ref) {
  final userRepository = ref.read(userRepositoryProvider);

  return UpdateUserEmailUseCase(userRepository);
});

/// ジム関連ユースケースProvider
final searchGymsUseCaseProvider = Provider<SearchGymsUseCase>((ref) {
  final gymRepository = ref.read(gymRepositoryProvider);

  return SearchGymsUseCase(gymRepository);
});

final getNearbyGymsUseCaseProvider = Provider<GetNearbyGymsUseCase>((ref) {
  final gymRepository = ref.read(gymRepositoryProvider);

  return GetNearbyGymsUseCase(gymRepository);
});

final getPopularGymsUseCaseProvider = Provider<GetPopularGymsUseCase>((ref) {
  final gymRepository = ref.read(gymRepositoryProvider);

  return GetPopularGymsUseCase(gymRepository);
});

final getGymDetailsUseCaseProvider = Provider<GetGymDetailsUseCase>((ref) {
  final gymRepository = ref.read(gymRepositoryProvider);

  return GetGymDetailsUseCase(gymRepository);
});

/// ツイート関連ユースケースProvider
final getTweetsUseCaseProvider = Provider<GetTweetsUseCase>((ref) {
  final tweetRepository = ref.read(tweetRepositoryProvider);

  return GetTweetsUseCase(tweetRepository);
});

final getFavoriteTweetsUseCaseProvider =
    Provider<GetFavoriteTweetsUseCase>((ref) {
  final tweetRepository = ref.read(tweetRepositoryProvider);

  return GetFavoriteTweetsUseCase(tweetRepository);
});

final getUserTweetsUseCaseProvider = Provider<GetUserTweetsUseCase>((ref) {
  final tweetRepository = ref.read(tweetRepositoryProvider);

  return GetUserTweetsUseCase(tweetRepository);
});

final getGymTweetsUseCaseProvider = Provider<GetGymTweetsUseCase>((ref) {
  final tweetRepository = ref.read(tweetRepositoryProvider);

  return GetGymTweetsUseCase(tweetRepository);
});

final postTweetUseCaseProvider = Provider<PostTweetUseCase>((ref) {
  final tweetRepository = ref.read(tweetRepositoryProvider);

  return PostTweetUseCase(tweetRepository);
});

final deleteTweetUseCaseProvider = Provider<DeleteTweetUseCase>((ref) {
  final tweetRepository = ref.read(tweetRepositoryProvider);

  return DeleteTweetUseCase(tweetRepository);
});

/// お気に入り関連ユースケースProvider
final manageFavoriteUserUseCaseProvider =
    Provider<ManageFavoriteUserUseCase>((ref) {
  final favoriteRepository = ref.read(favoriteRepositoryProvider);

  return ManageFavoriteUserUseCase(favoriteRepository);
});

final manageFavoriteGymUseCaseProvider =
    Provider<ManageFavoriteGymUseCase>((ref) {
  final favoriteRepository = ref.read(favoriteRepositoryProvider);

  return ManageFavoriteGymUseCase(favoriteRepository);
});

/// お気に入りユーザー詳細取得ユースケースProvider
final getFavoriteUserDetailsUseCaseProvider =
    Provider<GetFavoriteUserDetailsUseCase>((ref) {
  final favoriteRepository = ref.read(favoriteRepositoryProvider);
  final userRepository = ref.read(userRepositoryProvider);

  return GetFavoriteUserDetailsUseCase(favoriteRepository, userRepository);
});

/// お気に入られユーザー詳細取得ユースケースProvider
final getFavoritedByUserDetailsUseCaseProvider =
    Provider<GetFavoritedByUserDetailsUseCase>((ref) {
  final favoriteRepository = ref.read(favoriteRepositoryProvider);
  final userRepository = ref.read(userRepositoryProvider);

  return GetFavoritedByUserDetailsUseCase(favoriteRepository, userRepository);
});

/// 他ユーザーのイキタイジム詳細取得ユースケースProvider
final getUserFavoriteGymsUseCaseProvider =
    Provider<GetUserFavoriteGymsUseCase>((ref) {
  final favoriteRepository = ref.read(favoriteRepositoryProvider);

  return GetUserFavoriteGymsUseCase(favoriteRepository);
});

/// アクティビティ投稿関連ユースケースProvider
final activityPostUseCaseProvider = Provider<ActivityPostUseCase>((ref) {
  final tweetRepository = ref.read(tweetRepositoryProvider);
  final storageRepository = ref.read(storageRepositoryProvider);

  return ActivityPostUseCase(tweetRepository, storageRepository);
});

/// 統計情報関連ユースケースProvider
final getMonthlyStatisticsUseCaseProvider =
    Provider<GetMonthlyStatisticsUseCase>((ref) {
  final userRepository = ref.read(userRepositoryProvider);

  return GetMonthlyStatisticsUseCase(userRepository);
});

// ==================== ImagePicker関連 ====================

/// ImagePickerServiceProvider
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  // contextは使用時に渡すため、ここではnullで初期化
  return ImagePickerServiceImpl();
});

/// プロフィール画像選択ユースケースProvider
final selectProfileImageUseCaseProvider =
    Provider<SelectProfileImageUseCase>((ref) {
  final imagePickerService = ref.read(imagePickerServiceProvider);

  return SelectProfileImageUseCase(imagePickerService);
});

/// 投稿用画像選択ユースケースProvider
final selectPostImagesUseCaseProvider =
    Provider<SelectPostImagesUseCase>((ref) {
  final imagePickerService = ref.read(imagePickerServiceProvider);

  return SelectPostImagesUseCase(imagePickerService);
});
