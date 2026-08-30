import '../../domain/entities/user.dart';
import '../../domain/entities/gym.dart';
import '../../domain/entities/tweet.dart';

/// モック用の仮データクラス
///
/// 役割:
/// - 開発・テスト用の仮データを提供
/// - 外部API未実装時のローカル開発用
/// - 一貫性のあるテストデータの管理
class MockData {
  /// モックユーザーデータ
  static final Map<String, User> mockUsers = {
    'user001': User(
      id: 'user001',
      userName: '山田太郎',
      email: 'yamada@example.com',
      userIconUrl: 'https://via.placeholder.com/100/FF6B6B/FFFFFF?text=YT',
      userIntroduce: 'ボルダリング歴3年です！最近5級に挑戦中。よろしくお願いします！',
      favoriteGym: 'クライミングジム・ロックス',
      gender: 1, // 1: 男性, 2: 女性, 0: その他
      birthday: DateTime(1990, 5, 15),
      boulStartDate: DateTime(2021, 3, 1),
      homeGymId: 1,
    ),
    'user002': User(
      id: 'user002',
      userName: '佐藤花子',
      email: 'sato@example.com',
      userIconUrl: 'https://via.placeholder.com/100/4ECDC4/FFFFFF?text=SH',
      userIntroduce: 'ボルダリング初心者です。楽しく登っています♪',
      favoriteGym: 'ボルダリングパーク東京',
      gender: 2,
      birthday: DateTime(1995, 8, 22),
      boulStartDate: DateTime(2023, 6, 1),
      homeGymId: 2,
    ),
    'user003': User(
      id: 'user003',
      userName: '田中健一',
      email: 'tanaka@example.com',
      userIconUrl: 'https://via.placeholder.com/100/45B7D1/FFFFFF?text=TK',
      userIntroduce: 'ボルダリング大好き！週5で通ってます。目標は1級クリア！',
      favoriteGym: 'アーバンクライミング',
      gender: 1,
      birthday: DateTime(1988, 12, 3),
      boulStartDate: DateTime(2019, 1, 15),
      homeGymId: 3,
    ),
  };

  /// モックジム営業時間
  static const GymHours _defaultHours = GymHours(
    sunOpen: '10:00',
    sunClose: '22:00',
    monOpen: '10:00',
    monClose: '22:00',
    tueOpen: '10:00',
    tueClose: '22:00',
    wedOpen: '10:00',
    wedClose: '22:00',
    thuOpen: '10:00',
    thuClose: '22:00',
    friOpen: '10:00',
    friClose: '22:00',
    satOpen: '10:00',
    satClose: '22:00',
  );

  /// モックジムデータ
  static final Map<int, Gym> mockGyms = {
    1: const Gym(
      id: 1,
      name: 'クライミングジム・ロックス',
      hpLink: 'https://rocks-climbing.com',
      prefecture: '東京都',
      city: '渋谷区',
      addressLine: '道玄坂1-2-3 ロックスビル3F',
      latitude: 35.6581,
      longitude: 139.7414,
      telNo: '03-1234-5678',
      fee: '平日 1,800円 / 土日祝 2,200円',
      minimumFee: 1800,
      equipmentRentalFee: 'シューズ 300円',
      ikitaiCount: 150,
      boulCount: 45,
      isBoulderingGym: true,
      isLeadGym: true,
      isSpeedGym: false,
      hours: _defaultHours,
    ),
    2: const Gym(
      id: 2,
      name: 'ボルダリングパーク東京',
      hpLink: 'https://bp-tokyo.com',
      prefecture: '東京都',
      city: '新宿区',
      addressLine: '歌舞伎町2-10-5 東京ビル2F',
      latitude: 35.6895,
      longitude: 139.6917,
      telNo: '03-2345-6789',
      fee: '平日 1,500円 / 土日祝 1,800円',
      minimumFee: 1500,
      equipmentRentalFee: 'シューズ・チョーク セット 400円',
      ikitaiCount: 220,
      boulCount: 78,
      isBoulderingGym: true,
      isLeadGym: false,
      isSpeedGym: false,
      hours: GymHours(
        sunOpen: '9:00', sunClose: '23:00',
        monOpen: '-', monClose: '-', // 月曜休み
        tueOpen: '9:00', tueClose: '23:00',
        wedOpen: '9:00', wedClose: '23:00',
        thuOpen: '9:00', thuClose: '23:00',
        friOpen: '9:00', friClose: '23:00',
        satOpen: '9:00', satClose: '23:00',
      ),
    ),
    3: const Gym(
      id: 3,
      name: 'アーバンクライミング',
      hpLink: 'https://urban-climbing.jp',
      prefecture: '東京都',
      city: '品川区',
      addressLine: '大崎1-5-8 アーバンビル1F',
      latitude: 35.6284,
      longitude: 139.7386,
      telNo: '03-3456-7890',
      fee: '平日 2,000円 / 土日祝 2,500円',
      minimumFee: 2000,
      equipmentRentalFee: 'シューズ 500円 / ハーネス 300円',
      ikitaiCount: 180,
      boulCount: 62,
      isBoulderingGym: true,
      isLeadGym: true,
      isSpeedGym: true,
      hours: GymHours(
        sunOpen: '11:00', sunClose: '21:00',
        monOpen: '11:00', monClose: '21:00',
        tueOpen: '-', tueClose: '-', // 火曜休み
        wedOpen: '11:00', wedClose: '21:00',
        thuOpen: '11:00', thuClose: '21:00',
        friOpen: '11:00', friClose: '21:00',
        satOpen: '11:00', satClose: '21:00',
      ),
    ),
    4: const Gym(
      id: 4,
      name: 'クライミングファクトリー',
      hpLink: 'https://climbing-factory.com',
      prefecture: '神奈川県',
      city: '横浜市',
      addressLine: '港北区新横浜2-3-4 ファクトリービル3F',
      latitude: 35.4437,
      longitude: 139.6380,
      telNo: '045-1234-5678',
      fee: '平日 1,600円 / 土日祝 2,000円',
      minimumFee: 1600,
      equipmentRentalFee: 'シューズ 200円',
      ikitaiCount: 95,
      boulCount: 38,
      isBoulderingGym: true,
      isLeadGym: true,
      isSpeedGym: true,
      hours: GymHours(
        sunOpen: '10:00', sunClose: '22:00',
        monOpen: '10:00', monClose: '22:00',
        tueOpen: '10:00', tueClose: '22:00',
        wedOpen: '-', wedClose: '-', // 水曜休み
        thuOpen: '10:00', thuClose: '22:00',
        friOpen: '10:00', friClose: '22:00',
        satOpen: '10:00', satClose: '22:00',
      ),
    ),
    5: const Gym(
      id: 5,
      name: 'ロックオン大阪',
      hpLink: 'https://rockon-osaka.jp',
      prefecture: '大阪府',
      city: '大阪市',
      addressLine: '中央区心斎橋1-8-9 ロックオンビル2F',
      latitude: 34.6937,
      longitude: 135.5023,
      telNo: '06-1234-5678',
      fee: '平日 1,400円 / 土日祝 1,700円',
      minimumFee: 1400,
      equipmentRentalFee: 'シューズ 250円',
      ikitaiCount: 130,
      boulCount: 52,
      isBoulderingGym: true,
      isLeadGym: false,
      isSpeedGym: false,
      hours: GymHours(
        sunOpen: '10:00', sunClose: '22:00',
        monOpen: '10:00', monClose: '22:00',
        tueOpen: '10:00', tueClose: '22:00',
        wedOpen: '10:00', wedClose: '22:00',
        thuOpen: '-', thuClose: '-', // 木曜休み
        friOpen: '10:00', friClose: '22:00',
        satOpen: '10:00', satClose: '22:00',
      ),
    ),
  };

  /// モックツイートデータ
  static final List<Tweet> mockTweets = [
    Tweet(
      id: 1,
      userId: 'user001',
      userName: '山田太郎',
      userIconUrl: 'https://via.placeholder.com/100/FF6B6B/FFFFFF?text=YT',
      gymId: 1,
      gymName: 'クライミングジム・ロックス',
      prefecture: '東京都',
      content: '今日は5級の課題を3本クリアできました！だんだんホールドの感覚が掴めてきた感じです。次回は4級に挑戦してみます！',
      visitedDate: DateTime(2024, 1, 15),
      tweetedDate: DateTime(2024, 1, 15, 18, 30),
      likedCount: 12,
      mediaUrls: [
        'https://via.placeholder.com/300x200/FF6B6B/FFFFFF?text=Climbing+Photo+1',
        'https://via.placeholder.com/300x200/4ECDC4/FFFFFF?text=Climbing+Photo+2',
      ],
    ),
    Tweet(
      id: 2,
      userId: 'user002',
      userName: '佐藤花子',
      userIconUrl: 'https://via.placeholder.com/100/4ECDC4/FFFFFF?text=SH',
      gymId: 2,
      gymName: 'ボルダリングパーク東京',
      prefecture: '東京都',
      content: 'ボルダリング始めて半年が経ちました！最初は6級も難しかったのに、今では5級もクリアできるように。継続は力なりですね✨',
      visitedDate: DateTime(2024, 1, 14),
      tweetedDate: DateTime(2024, 1, 14, 20, 15),
      likedCount: 8,
      mediaUrls: [
        'https://via.placeholder.com/300x200/45B7D1/FFFFFF?text=Progress+Photo',
      ],
    ),
    Tweet(
      id: 3,
      userId: 'user003',
      userName: '田中健一',
      userIconUrl: 'https://via.placeholder.com/100/45B7D1/FFFFFF?text=TK',
      gymId: 3,
      gymName: 'アーバンクライミング',
      prefecture: '東京都',
      content: '今日は新しい1級課題に挑戦！まだクリアできないけど、ムーブの研究が楽しい。明日も頑張ります💪',
      visitedDate: DateTime(2024, 1, 13),
      tweetedDate: DateTime(2024, 1, 13, 19, 45),
      likedCount: 15,
      mediaUrls: [],
    ),
    Tweet(
      id: 4,
      userId: 'user001',
      userName: '山田太郎',
      userIconUrl: 'https://via.placeholder.com/100/FF6B6B/FFFFFF?text=YT',
      gymId: 2,
      gymName: 'ボルダリングパーク東京',
      prefecture: '東京都',
      content: '久しぶりに違うジムに行ってきました！ホールドの種類が違うと全然違う感覚で新鮮でした。',
      visitedDate: DateTime(2024, 1, 12),
      tweetedDate: DateTime(2024, 1, 12, 17, 20),
      likedCount: 6,
      mediaUrls: [
        'https://via.placeholder.com/300x200/96CEB4/FFFFFF?text=New+Gym+Visit',
      ],
    ),
    Tweet(
      id: 5,
      userId: 'user002',
      userName: '佐藤花子',
      userIconUrl: 'https://via.placeholder.com/100/4ECDC4/FFFFFF?text=SH',
      gymId: 1,
      gymName: 'クライミングジム・ロックス',
      prefecture: '東京都',
      content: '友達と一緒にボルダリング！お互いにアドバイスし合いながら登るとより楽しいです😊',
      visitedDate: DateTime(2024, 1, 11),
      tweetedDate: DateTime(2024, 1, 11, 16, 10),
      likedCount: 20,
      mediaUrls: [
        'https://via.placeholder.com/300x200/FFEAA7/FFFFFF?text=Friends+Climbing+1',
        'https://via.placeholder.com/300x200/DDA0DD/FFFFFF?text=Friends+Climbing+2',
        'https://via.placeholder.com/300x200/98D8C8/FFFFFF?text=Friends+Climbing+3',
      ],
    ),
  ];

  /// モック認証情報
  static final Map<String, Map<String, String>> mockAuthCredentials = {
    'yamada@example.com': {
      'password': 'password123',
      'userId': 'user001',
    },
    'sato@example.com': {
      'password': 'password456',
      'userId': 'user002',
    },
    'tanaka@example.com': {
      'password': 'password789',
      'userId': 'user003',
    },
  };

  /// 現在ログイン中のユーザーID（モック用）
  static String? currentLoggedInUserId;

  /// モックお気に入りユーザー関係
  static final Map<String, List<String>> mockFavoriteUsers = {
    'user001': ['user002', 'user003'],
    'user002': ['user001'],
    'user003': ['user001', 'user002'],
  };

  /// モックお気に入りジム関係
  static final Map<String, List<int>> mockFavoriteGyms = {
    'user001': [1, 2],
    'user002': [2, 3],
    'user003': [1, 3, 4],
  };

  /// 指定されたユーザーのツイートを取得
  static List<Tweet> getTweetsByUserId(String userId) {
    return mockTweets.where((tweet) => tweet.userId == userId).toList();
  }

  /// 指定されたジムのツイートを取得
  static List<Tweet> getTweetsByGymId(int gymId) {
    return mockTweets.where((tweet) => tweet.gymId == gymId).toList();
  }

  /// ユーザーのお気に入りユーザーのツイートを取得
  static List<Tweet> getFavoriteTweets(String userId) {
    final favoriteUserIds = mockFavoriteUsers[userId] ?? [];
    return mockTweets
        .where((tweet) => favoriteUserIds.contains(tweet.userId))
        .toList();
  }

  /// ジム名で検索
  static List<Gym> searchGyms(String query) {
    if (query.isEmpty) return mockGyms.values.toList();

    return mockGyms.values
        .where((gym) =>
            gym.name.toLowerCase().contains(query.toLowerCase()) ||
            gym.prefecture.toLowerCase().contains(query.toLowerCase()) ||
            gym.city.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// 新しいツイートを追加（モック用）
  static int addTweet({
    required String userId,
    required int gymId,
    required String content,
    required DateTime visitedDate,
    required List<String> mediaUrls,
  }) {
    final user = mockUsers[userId];
    final gym = mockGyms[gymId];

    if (user == null || gym == null) {
      throw Exception('User or Gym not found');
    }

    final newId = mockTweets.length + 1;
    final newTweet = Tweet(
      id: newId,
      userId: userId,
      userName: user.userName,
      userIconUrl: user.userIconUrl ?? '',
      gymId: gymId,
      gymName: gym.name,
      prefecture: gym.prefecture,
      content: content,
      visitedDate: visitedDate,
      tweetedDate: DateTime.now(),
      likedCount: 0,
      mediaUrls: mediaUrls,
    );

    mockTweets.insert(0, newTweet); // 最新が最初に来るように
    return newId;
  }

  /// ログイン状態を設定
  static void setLoggedInUser(String? userId) {
    currentLoggedInUserId = userId;
  }

  /// 現在ログイン中のユーザーを取得
  static User? getCurrentUser() {
    if (currentLoggedInUserId == null) return null;
    return mockUsers[currentLoggedInUserId];
  }

  /// ログイン認証（モック）
  static bool authenticateUser(String email, String password) {
    final credentials = mockAuthCredentials[email];
    if (credentials != null && credentials['password'] == password) {
      currentLoggedInUserId = credentials['userId'];
      return true;
    }
    return false;
  }

  /// ログアウト（モック）
  static void logout() {
    currentLoggedInUserId = null;
  }

  /// 新規ユーザー作成（モック）
  static bool createUser(String userId, String email) {
    if (mockUsers.containsKey(userId)) {
      return false; // 既存ユーザー
    }

    final newUser = User(
      id: userId,
      userName: 'ユーザー${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      userIntroduce: 'よろしくお願いします！',
    );

    mockUsers[userId] = newUser;
    return true;
  }
}
