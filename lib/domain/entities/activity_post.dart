/// アクティビティ投稿エンティティ
/// 
/// 役割:
/// - ボルダリングアクティビティの投稿データを表現
/// - 投稿内容、訪問日、関連ジム情報を保持
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のエンティティ
/// - ビジネスロジックの中核となるデータ構造
/// - 他の層に依存しない
class ActivityPost {
  /// 投稿ID
  final int id;
  
  /// 投稿者のユーザーID
  final String userId;
  
  /// 訪問したジムのID
  final int gymId;
  
  /// ジム訪問日
  final DateTime visitedDate;
  
  /// 投稿内容（ツイート本文）
  final String tweetContents;
  
  /// 投稿作成日時
  final DateTime createdAt;
  
  /// 最終更新日時
  final DateTime updatedAt;

  /// コンストラクタ
  /// 
  /// [id] 投稿ID
  /// [userId] ユーザーID
  /// [gymId] ジムID
  /// [visitedDate] 訪問日
  /// [tweetContents] 投稿内容
  /// [createdAt] 作成日時
  /// [updatedAt] 更新日時
  const ActivityPost({
    required this.id,
    required this.userId,
    required this.gymId,
    required this.visitedDate,
    required this.tweetContents,
    required this.createdAt,
    required this.updatedAt,
  });

  /// コピーコンストラクタ
  /// 
  /// 一部のフィールドを変更した新しいインスタンスを作成
  ActivityPost copyWith({
    int? id,
    String? userId,
    int? gymId,
    DateTime? visitedDate,
    String? tweetContents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gymId: gymId ?? this.gymId,
      visitedDate: visitedDate ?? this.visitedDate,
      tweetContents: tweetContents ?? this.tweetContents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// オブジェクトの等価判定
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ActivityPost &&
        other.id == id &&
        other.userId == userId &&
        other.gymId == gymId &&
        other.visitedDate == visitedDate &&
        other.tweetContents == tweetContents &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  /// ハッシュコード
  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        gymId.hashCode ^
        visitedDate.hashCode ^
        tweetContents.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  /// 文字列表現
  @override
  String toString() {
    return 'ActivityPost{'
        'id: $id, '
        'userId: $userId, '
        'gymId: $gymId, '
        'visitedDate: $visitedDate, '
        'tweetContents: $tweetContents, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        '}';
  }

  /// JSON形式への変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'gymId': gymId,
      'visitedDate': visitedDate.toIso8601String(),
      'tweetContents': tweetContents,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// JSON形式からの変換
  factory ActivityPost.fromJson(Map<String, dynamic> json) {
    return ActivityPost(
      id: json['id'] as int,
      userId: json['userId'] as String,
      gymId: json['gymId'] as int,
      visitedDate: DateTime.parse(json['visitedDate'] as String),
      tweetContents: json['tweetContents'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 投稿内容の有効性チェック
  /// 
  /// 返り値:
  /// - 有効: true
  /// - 無効: false
  bool isValid() {
    // ユーザーIDの検証
    if (userId.trim().isEmpty) return false;
    
    // ジムIDの検証
    if (gymId <= 0) return false;
    
    // 投稿内容の文字数検証
    if (tweetContents.length > 400) return false;
    
    // 訪問日の検証（未来日は不可）
    if (visitedDate.isAfter(DateTime.now())) return false;
    
    return true;
  }

  /// 投稿内容が編集されたかどうかを判定
  /// 
  /// [original] 元の投稿データ
  /// 
  /// 返り値:
  /// - 編集されている: true
  /// - 編集されていない: false
  bool isModified(ActivityPost original) {
    return gymId != original.gymId ||
           visitedDate != original.visitedDate ||
           tweetContents != original.tweetContents;
  }
}