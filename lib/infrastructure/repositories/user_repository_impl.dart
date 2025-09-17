import '../../domain/entities/user.dart';
import '../../domain/entities/bouldering_stats.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_datasource.dart';

/// ユーザーリポジトリ実装クラス
/// 
/// 役割:
/// - Domainレイヤーで定義されたUserRepositoryインタフェースの実装
/// - データソースとDomainレイヤー間の橋渡し
/// - ビジネスロジックに必要なデータ加工・変換処理
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のRepository実装
/// - Domain層のRepository抽象クラスに依存（依存関係逆転の原則）
/// - UseCase層から使用される
/// 
/// 依存関係:
/// - UserDataSource（Infrastructure層） ← この実装
/// - UserRepository（Domain層） ← インタフェース
class UserRepositoryImpl implements UserRepository {
  final UserDataSource _dataSource;

  /// コンストラクタ
  /// 
  /// [_dataSource] ユーザーデータソース
  UserRepositoryImpl(this._dataSource);

  /// ユーザーID指定による情報取得（自分のデータ用）
  /// 
  /// [userId] 取得対象のユーザーID
  /// 
  /// 返り値:
  /// [User?] ユーザーエンティティ、存在しない場合はnull
  /// 
  /// ビジネスルール:
  /// - ユーザーIDが空文字の場合はnullを返す
  /// - データソースで例外が発生した場合は再スロー
  @override
  Future<User?> getUserById(String userId) async {
    if (userId.trim().isEmpty) {
      return null;
    }

    try {
      return await _dataSource.getUserById(userId);
    } catch (e) {
      // データソースの例外をそのまま再スロー
      // 必要に応じてログ出力やエラー変換を行う
      rethrow;
    }
  }

  /// 他ユーザーの公開プロフィール取得
  /// 
  /// [userId] 取得対象のユーザーID
  /// 
  /// 返り値:
  /// [User?] ユーザーエンティティ、存在しない場合はnull
  /// 
  /// ビジネスルール:
  /// - ユーザーIDが空文字の場合はnullを返す
  /// - 認証不要で公開プロフィールを取得
  @override
  Future<User?> getUserProfile(String userId) async {
    if (userId.trim().isEmpty) {
      return null;
    }

    try {
      return await _dataSource.getUserProfile(userId);
    } catch (e) {
      rethrow;
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
  /// ビジネスルール:
  /// - ユーザーIDとメールアドレスは必須
  /// - 空文字やnullの場合は作成失敗とする
  /// - メールアドレスの形式チェック（簡易）
  @override
  Future<bool> createUser(String userId, String email) async {
    // 入力値検証
    if (userId.trim().isEmpty || email.trim().isEmpty) {
      return false;
    }

    // 簡易メールアドレス形式チェック
    if (!_isValidEmail(email)) {
      return false;
    }

    try {
      return await _dataSource.createUser(userId, email);
    } catch (e) {
      // エラーログ出力などの処理を追加可能
      return false;
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
  /// ビジネスルール:
  /// - ユーザー名は1文字以上50文字以下
  /// - 空文字や空白のみの名前は許可しない
  @override
  Future<bool> updateUserName(String userId, String userName) async {
    // 入力値検証
    if (userId.trim().isEmpty || userName.trim().isEmpty) {
      return false;
    }

    // ユーザー名の長さチェック
    if (userName.trim().length > 50) {
      return false;
    }

    try {
      return await _dataSource.updateUserName(userId, userName.trim());
    } catch (e) {
      return false;
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
  /// ビジネスルール:
  /// - URLの形式チェック（簡易）
  /// - HTTPS URLのみ許可
  @override
  Future<bool> updateUserIconUrl(String userId, String iconUrl) async {
    if (userId.trim().isEmpty || iconUrl.trim().isEmpty) {
      return false;
    }

    // HTTPS URLの簡易チェック
    if (!iconUrl.startsWith('https://')) {
      return false;
    }

    try {
      return await _dataSource.updateUserIconUrl(userId, iconUrl);
    } catch (e) {
      return false;
    }
  }

  /// ユーザープロフィール更新
  /// 
  /// [userId] 更新対象のユーザーID
  /// [userIntroduce] 自己紹介文（オプション）
  /// [favoriteGym] お気に入りジム（オプション）
  /// 
  /// 返り値:
  /// [bool] 更新成功時はtrue、失敗時はfalse
  /// 
  /// ビジネスルール:
  /// - 自己紹介文は500文字以内
  /// - お気に入りジムは200文字以内
  /// - 両方nullの場合は処理をスキップ
  @override
  Future<bool> updateUserProfile({
    required String userId,
    String? userIntroduce,
    String? favoriteGym,
  }) async {
    if (userId.trim().isEmpty) {
      return false;
    }

    // 両方nullの場合は処理をスキップ
    if (userIntroduce == null && favoriteGym == null) {
      return true;
    }

    // 文字数制限チェック
    if (userIntroduce != null && userIntroduce.length > 500) {
      return false;
    }

    if (favoriteGym != null && favoriteGym.length > 200) {
      return false;
    }

    try {
      return await _dataSource.updateUserProfile(
        userId: userId,
        userIntroduce: userIntroduce?.trim(),
        favoriteGym: favoriteGym?.trim(),
      );
    } catch (e) {
      return false;
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
  /// ビジネスルール:
  /// - 性別は0, 1, 2のいずれかのみ許可
  @override
  Future<bool> updateUserGender(String userId, int gender) async {
    if (userId.trim().isEmpty) {
      return false;
    }

    // 性別値の検証
    if (gender < 0 || gender > 2) {
      return false;
    }

    try {
      return await _dataSource.updateUserGender(userId, gender);
    } catch (e) {
      return false;
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
  /// ビジネスルール:
  /// - 生年月日は現在日より過去
  /// - ボルダリング開始日は現在日以前
  /// - 両方nullの場合は処理をスキップ
  @override
  Future<bool> updateUserDates({
    required String userId,
    DateTime? birthday,
    DateTime? boulStartDate,
  }) async {
    if (userId.trim().isEmpty) {
      return false;
    }

    // 両方nullの場合は処理をスキップ
    if (birthday == null && boulStartDate == null) {
      return true;
    }

    final now = DateTime.now();

    // 日付の妥当性チェック
    if (birthday != null && birthday.isAfter(now)) {
      return false; // 生年月日は現在より過去である必要がある
    }

    if (boulStartDate != null && boulStartDate.isAfter(now)) {
      return false; // ボルダリング開始日は現在以前である必要がある
    }

    try {
      return await _dataSource.updateUserDates(
        userId: userId,
        birthday: birthday,
        boulStartDate: boulStartDate,
      );
    } catch (e) {
      return false;
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
  /// ビジネスルール:
  /// - ジムIDは正の整数または0（選択なし）
  @override
  Future<bool> updateHomeGym(String userId, int gymId) async {
    // ユーザーIDの妥当性チェック
    if (userId.trim().isEmpty) {
      return false;
    }
    
    // ジムIDの妥当性チェック（gymId = 0 は「選択なし」として許可）
    if (gymId < 0) {
      return false;
    }

    try {
      // データソースでホームジム情報を更新
      final result = await _dataSource.updateHomeGym(userId, gymId);
      return result;
    } catch (e) {
      // エラー時は失敗として処理
      return false;
    }
  }

  /// ユーザーアイコン画像アップロード
  /// 
  /// [userId] アップロードするユーザーID
  /// [imagePath] アップロードする画像ファイルのパス
  /// 
  /// 返り値:
  /// [String?] アップロード成功時は公開URL、失敗時はnull
  /// 
  /// ビジネスルール:
  /// - 対応ファイル形式: jpg, jpeg, png, gif
  /// - ファイルサイズ制限などは実装可能
  @override
  Future<String?> uploadUserIcon(String userId, String imagePath) async {
    // 入力パラメータの妥当性チェック
    if (userId.trim().isEmpty || imagePath.trim().isEmpty) {
      return null;
    }

    // ファイル形式の妥当性チェック
    if (!_isValidImageFormat(imagePath)) {
      return null;
    }

    try {
      // データソースでアイコン画像をアップロードし、公開URLを取得
      final result = await _dataSource.uploadUserIcon(imagePath, userId: userId);
      return result;
    } catch (e) {
      // アップロード失敗時はnullを返す
      return null;
    }
  }

  /// メールアドレス形式の簡易チェック
  /// 
  /// [email] チェック対象のメールアドレス
  /// 
  /// 返り値:
  /// [bool] 有効な形式の場合はtrue
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  /// 画像ファイル形式の簡易チェック
  /// 
  /// [filePath] チェック対象のファイルパス
  /// 
  /// 返り値:
  /// [bool] 対応形式の場合はtrue
  bool _isValidImageFormat(String filePath) {
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
    final lowerPath = filePath.toLowerCase();
    return allowedExtensions.any((ext) => lowerPath.endsWith(ext));
  }

  /// ユーザー削除
  /// 
  /// [userId] 削除対象のユーザーID
  /// 
  /// 返り値:
  /// [bool] 削除成功時はtrue、失敗時はfalse
  /// 
  /// 処理フロー:
  /// 1. ユーザーIDの妥当性チェック
  /// 2. データソースでユーザー削除実行
  @override
  Future<bool> updateUserEmail(String userId, String email) async {
    if (userId.trim().isEmpty || email.trim().isEmpty) {
      return false;
    }

    try {
      return await _dataSource.updateUserEmail(userId, email);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteUser(String userId) async {
    if (userId.trim().isEmpty) {
      return false;
    }

    try {
      return await _dataSource.deleteUser(userId);
    } catch (e) {
      return false;
    }
  }
  
  /// 月間統計情報取得
  /// 
  /// [userId] 統計を取得するユーザーID
  /// [monthsAgo] 何ヶ月前の統計か（0: 今月、1: 先月）
  /// 
  /// 返り値:
  /// [BoulderingStats] 月間統計情報エンティティ
  /// 
  /// ビジネスルール:
  /// - monthsAgoは0以上12以下のみ許可
  /// - データが存在しない場合は0値での統計を返す
  @override
  Future<BoulderingStats> getMonthlyStatistics(String userId, int monthsAgo) async {
    if (userId.trim().isEmpty) {
      return BoulderingStats(
        totalVisits: 0,
        totalGymCount: 0,
        weeklyVisitRate: 0.0,
        topGyms: [],
      );
    }
    
    // monthsAgoの範囲チェック（0-12ヶ月）
    if (monthsAgo < 0 || monthsAgo > 12) {
      throw Exception('monthsAgoは0以上12以下である必要があります');
    }

    try {
      final data = await _dataSource.getMonthlyStatistics(userId, monthsAgo);
      
      // バックエンドのレスポンス形式に合わせてマッピング
      return BoulderingStats(
        totalVisits: int.tryParse(data['total_visits']?.toString() ?? '0') ?? 0,
        totalGymCount: int.tryParse(data['unique_gyms']?.toString() ?? '0') ?? 0,
        weeklyVisitRate: double.tryParse(data['weekly_average']?.toString() ?? '0.0') ?? 0.0,
        topGyms: (data['top_gyms'] as List<dynamic>?)
            ?.map((gym) => TopGym.fromJson(gym as Map<String, dynamic>))
            .toList() ?? [],
      );
    } catch (e) {
      // エラー時は0値の統計を返す（アプリが落ちない対策）
      return BoulderingStats(
        totalVisits: 0,
        totalGymCount: 0,
        weeklyVisitRate: 0.0,
        topGyms: [],
      );
    }
  }
}