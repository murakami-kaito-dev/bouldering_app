/// お知らせエンティティ（Issue #81）
///
/// バックエンドの `GET /announcements` の 1 要素に対応する。
/// `gymId` が null なら運営の公式お知らせ、それ以外はジム（ホームジム・イキタイジム）からのお知らせ
class Announcement {
  final int id;
  final int? gymId;
  final String? gymName;
  final String title;
  final String body;
  final String? imageUrl;
  final String? linkUrl;
  final DateTime publishedAt;

  const Announcement({
    required this.id,
    this.gymId,
    this.gymName,
    required this.title,
    required this.body,
    this.imageUrl,
    this.linkUrl,
    required this.publishedAt,
  });

  /// 運営の公式お知らせか
  bool get isOfficial => gymId == null;

  /// 発信元の表示名
  String get senderName => isOfficial ? 'イワノボリタイ 運営' : (gymName ?? 'ジム');

  /// 公開日（YYYY/M/D）
  String get publishedDateDisplay {
    final l = publishedAt.toLocal();
    return '${l.year}/${l.month}/${l.day}';
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['announcement_id'] ?? 0,
      gymId: json['gym_id'],
      gymName: json['gym_name'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imageUrl: json['image_url'],
      linkUrl: json['link_url'],
      publishedAt: DateTime.tryParse(json['published_at'] ?? '')?.toLocal() ??
          DateTime(1990, 1, 1),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Announcement && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
