/// 報告エンティティ
/// 
/// ツイートの不適切な内容を報告するためのエンティティ
/// POSTのみでGETは行わないため、最小限の構成
class Report {
  final String reporterUserId;
  final String targetUserId;
  final int targetTweetId;
  final String reportDescription;

  const Report({
    required this.reporterUserId,
    required this.targetUserId,
    required this.targetTweetId,
    required this.reportDescription,
  });

  /// 報告作成用のJSONに変換
  /// 
  /// APIへのPOST送信用
  Map<String, dynamic> toCreateJson() {
    return {
      'reporter_user_id': reporterUserId,
      'target_user_id': targetUserId,
      'target_tweet_id': targetTweetId,
      'report_description': reportDescription,
    };
  }
}