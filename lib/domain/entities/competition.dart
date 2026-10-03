import '../../shared/utils/app_clock.dart';

/// コンペの開催状態（サーバーが JST の今日と期間を比べて決める）
enum CompetitionStatus {
  upcoming,
  active,
  ended;

  static CompetitionStatus fromString(String? value) {
    switch (value) {
      case 'upcoming':
        return CompetitionStatus.upcoming;
      case 'ended':
        return CompetitionStatus.ended;
      default:
        return CompetitionStatus.active;
    }
  }

  String get label {
    switch (this) {
      case CompetitionStatus.upcoming:
        return '開催前';
      case CompetitionStatus.active:
        return '開催中';
      case CompetitionStatus.ended:
        return '終了';
    }
  }
}

/// コンペティション（デモ機能）
///
/// バックエンドの `GET /competitions…` の 1 要素に対応する。
/// 期間は日本時間の「日付」。開始日の 00:00:00 〜 終了日の 23:59:59（JST）が開催中
class Competition {
  final int id;
  final int gymId;
  final String gymName;
  final String? prefecture;
  final String hostUserId;

  /// 任意のタイトル（空なら「<ジム名> のコンペ」として表示する）
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int problemFrom;
  final int problemTo;

  /// 参加料（円）。0 = 無料
  final int entryFeeYen;
  final CompetitionStatus status;
  final int participantCount;

  /// ログイン中のユーザーが参加済みか
  final bool isJoined;

  /// ログイン中のユーザーが開催者（本人 or 同じジムの管理者）か
  final bool isHost;

  const Competition({
    required this.id,
    required this.gymId,
    required this.gymName,
    this.prefecture,
    required this.hostUserId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.problemFrom,
    required this.problemTo,
    required this.entryFeeYen,
    required this.status,
    required this.participantCount,
    required this.isJoined,
    required this.isHost,
  });

  bool get isFree => entryFeeYen == 0;
  bool get isActive => status == CompetitionStatus.active;

  /// 課題数
  int get problemCount => problemTo - problemFrom + 1;

  /// 表示用タイトル
  String get displayTitle => title.trim().isNotEmpty ? title.trim() : '$gymName のコンペ';

  /// 期間（YYYY/M/D 〜 YYYY/M/D）
  String get periodDisplay => '${_ymd(startDate)} 〜 ${_ymd(endDate)}';

  /// 課題の範囲（例: 1〜30 番・30 課題）
  String get problemRangeDisplay => '$problemFrom〜$problemTo 番（$problemCount 課題）';

  /// 参加料の表示（無料 / 1,000円）
  String get feeDisplay => isFree ? '無料' : '${_formatYen(entryFeeYen)}円';

  /// 有料／無料の種別
  String get feeKindDisplay => isFree ? '無料コンペ' : '有料コンペ';

  /// 開催者向け: 開催期間中の残り日数（終了日を含む）。開催中でなければ null
  int? get remainingDays {
    if (!isActive) return null;
    return endDate.difference(AppClock.todayJst()).inDays + 1;
  }

  factory Competition.fromJson(Map<String, dynamic> json) {
    return Competition(
      id: json['competition_id'] ?? 0,
      gymId: json['gym_id'] ?? 0,
      gymName: json['gym_name'] ?? '',
      prefecture: json['prefecture'],
      hostUserId: json['host_user_id'] ?? '',
      title: json['title'] ?? '',
      startDate: AppClock.parseDateOnly(json['start_date']) ?? DateTime(1990, 1, 1),
      endDate: AppClock.parseDateOnly(json['end_date']) ?? DateTime(1990, 1, 1),
      problemFrom: json['problem_from'] ?? 1,
      problemTo: json['problem_to'] ?? 1,
      entryFeeYen: json['entry_fee_yen'] ?? 0,
      status: CompetitionStatus.fromString(json['status']),
      participantCount: json['participant_count'] ?? 0,
      isJoined: json['is_joined'] == true,
      isHost: json['is_host'] == true,
    );
  }

  static String _ymd(DateTime d) => '${d.year}/${d.month}/${d.day}';

  static String _formatYen(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Competition && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 開催・編集の入力（日付は JST の日付のみ）
class CompetitionInput {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int problemFrom;
  final int problemTo;
  final int entryFeeYen;

  const CompetitionInput({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.problemFrom,
    required this.problemTo,
    required this.entryFeeYen,
  });

  CompetitionInput copyWith({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    int? problemFrom,
    int? problemTo,
    int? entryFeeYen,
  }) =>
      CompetitionInput(
        title: title ?? this.title,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        problemFrom: problemFrom ?? this.problemFrom,
        problemTo: problemTo ?? this.problemTo,
        entryFeeYen: entryFeeYen ?? this.entryFeeYen,
      );

  bool get isFree => entryFeeYen == 0;
  int get problemCount => problemTo - problemFrom + 1;
  String get periodDisplay =>
      '${startDate.year}/${startDate.month}/${startDate.day} 〜 ${endDate.year}/${endDate.month}/${endDate.day}';
  String get problemRangeDisplay => '$problemFrom〜$problemTo 番（$problemCount 課題）';
  String get feeDisplay => isFree ? '無料（0円）' : '${Competition._formatYen(entryFeeYen)}円';

  /// サーバーへ送る形（DATE 列なので 'YYYY-MM-DD' のみ）
  Map<String, dynamic> toJson() => {
        'title': title.trim(),
        'start_date': AppClock.formatDateOnly(startDate),
        'end_date': AppClock.formatDateOnly(endDate),
        'problem_from': problemFrom,
        'problem_to': problemTo,
        'entry_fee_yen': entryFeeYen,
      };
}

/// 順位表の 1 行
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String userName;
  final String? userIconUrl;
  final int completedCount;
  final bool isMe;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    this.userIconUrl,
    required this.completedCount,
    required this.isMe,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] ?? '',
      userIconUrl: json['user_icon_url'],
      completedCount: json['completed_count'] ?? 0,
      isMe: json['is_me'] == true,
    );
  }
}

/// 順位表（コンペ本体＋順位＋本人の完登状況）
class CompetitionLeaderboard {
  final Competition competition;
  final List<LeaderboardEntry> entries;

  /// 本人の順位（未参加なら null）
  final int? myRank;

  /// 本人が完登済みの課題番号
  final Set<int> myCompletedProblems;

  const CompetitionLeaderboard({
    required this.competition,
    required this.entries,
    this.myRank,
    required this.myCompletedProblems,
  });

  /// 本人の行の位置（無ければ -1）
  int get myIndex => entries.indexWhere((e) => e.isMe);

  factory CompetitionLeaderboard.fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List<dynamic>? ?? const [])
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final completed = (json['my_completed_problems'] as List<dynamic>? ?? const [])
        .map((e) => (e as num).toInt())
        .toSet();
    return CompetitionLeaderboard(
      competition: Competition.fromJson(json['competition'] as Map<String, dynamic>),
      entries: entries,
      myRank: json['my_rank'],
      myCompletedProblems: completed,
    );
  }
}
