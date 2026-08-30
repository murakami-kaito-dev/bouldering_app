/// ジム写真エンティティ
///
/// 役割:
/// - ジムに紐づく写真1枚と、その出どころ・帰属情報を表す
///
/// 出どころ（GymPhotoSet.source）はバックエンドが決める:
/// - 'own'    : 自前写真（許諾取得済み・GCS保存）
/// - 'google' : Google Places API 由来（規約により Google 帰属表示が必須）
/// - 'none'   : 写真なし
class GymPhoto {
  const GymPhoto({
    required this.url,
    this.authorName,
    this.authorUri,
  });

  final String url;

  /// 撮影者名（Google写真の帰属表示に使用。自前写真では null）
  final String? authorName;
  final String? authorUri;

  factory GymPhoto.fromJson(Map<String, dynamic> json) => GymPhoto(
        url: json['url'] as String,
        authorName: json['authorName'] as String?,
        authorUri: json['authorUri'] as String?,
      );
}

/// ジム1件分の写真セット（出どころ + 写真リスト）
class GymPhotoSet {
  const GymPhotoSet({required this.source, required this.photos});

  /// 'own' | 'google' | 'none'
  final String source;
  final List<GymPhoto> photos;

  bool get isFromGoogle => source == 'google';
  bool get isEmpty => photos.isEmpty;

  static const empty = GymPhotoSet(source: 'none', photos: []);

  factory GymPhotoSet.fromJson(Map<String, dynamic> json) => GymPhotoSet(
        source: json['source'] as String? ?? 'none',
        photos: (json['photos'] as List<dynamic>? ?? [])
            .map((e) => GymPhoto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
