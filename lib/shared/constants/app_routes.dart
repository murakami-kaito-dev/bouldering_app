/// アプリ内のルート定数
///
/// 役割:
/// - 画面遷移時のルート名を一元管理
/// - タイプセーフなルーティングを実現
/// - 画面間のパラメータ受け渡しを標準化
class AppRoutes {
  static const String loginOrSignup = '/login-signup';
  static const String home = '/home';

  // ジム関連
  static const String gymDetail = '/gym/detail';
  static const String gymSearch = '/gym/search';
  static const String gymNameSearch = '/gym/name-search';
  static const String gymMap = '/gym/map';

  // ツイート関連
  static const String tweetPost = '/tweet/post';
  static const String tweetDetail = '/tweet/detail';

  // ユーザー関連
  static const String userProfile = '/user/profile';
  static const String editProfile = '/user/edit-profile';
  static const String otherUserProfile = '/user/other-profile';

  // お気に入り・イキタイ関連
  static const String favoriteUsers = '/favorites/users';
  static const String favoriteGyms = '/favorites/gyms';

  // 設定関連
  static const String settings = '/settings';
}

/// ルートパラメータ用のクラス
class RouteParams {
  // ジム詳細ページ用
  static const String gymId = 'gymId';

  // ツイート詳細ページ用
  static const String tweetId = 'tweetId';

  // ユーザープロフィールページ用
  static const String userId = 'userId';

  // ツイート投稿ページ用（事前選択ジム）
  static const String preSelectedGymId = 'preSelectedGymId';
}
