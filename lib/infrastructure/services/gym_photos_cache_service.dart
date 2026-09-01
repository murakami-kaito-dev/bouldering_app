import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// キャッシュ読み出し結果（写真セットの生JSON + 保存時刻）
class CachedGymPhotos {
  const CachedGymPhotos({required this.data, required this.savedAt});

  final Map<String, dynamic> data;
  final DateTime savedAt;

  /// TTL以内なら新鮮（裏の再取得も不要）
  bool get isFresh =>
      DateTime.now().difference(savedAt) < GymPhotosCacheService.ttl;
}

/// ジム写真URLリストの永続キャッシュサービス
///
/// 役割:
/// - GET /gyms/{id}/photos の生レスポンス(Map)をジムIDごとにJSON保存する
/// - オフラインや通信不安定時でも、一度表示したジムの写真リストを出せるようにする
///   （画像本体のオフライン表示は CachedNetworkImage のディスクキャッシュが担う）
///
/// 設計上のポイント（GymCacheService と同じ方針）:
/// - 「生JSON」のまま保存し、エンティティ変換(GymPhotoSet.fromJson)は読み出し側で行う
/// - schemaVersion で世代管理（レスポンスのキー名変更時に bump して旧キャッシュを無効化）
/// - 保存先は ApplicationSupport（ユーザー非可視。Temporary はOSに消されるため不可）
/// - 読み書きの失敗はすべて「キャッシュなし」に丸め、アプリの動作を壊さない
class GymPhotosCacheService {
  /// キャッシュ形式の世代。レスポンスのキー名が変わったら上げること
  static const int schemaVersion = 1;

  /// この期間内は「新鮮」扱い（バックエンド側の写真キャッシュ7日に合わせる）
  static const Duration ttl = Duration(days: 7);

  static const String _fileName = 'gym_photos_cache_v1.json';

  // 同一セッション内のディスク再読込を避けるためのメモリ保持
  Map<String, dynamic>? _memoryEntries;

  Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// 全エントリ {"<gymId>": {"savedAt": ..., "data": {...}}} を読み出す
  Future<Map<String, dynamic>?> _readEntries() async {
    if (_memoryEntries != null) return _memoryEntries;

    File? file;
    try {
      file = await _cacheFile();
      if (!await file.exists()) return null;

      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic> ||
          json['schemaVersion'] != schemaVersion ||
          json['entries'] is! Map<String, dynamic>) {
        await file.delete();
        return null;
      }

      _memoryEntries = json['entries'] as Map<String, dynamic>;
      return _memoryEntries;
    } catch (_) {
      // 破損ファイルは削除して「キャッシュなし」として扱う
      try {
        if (file != null && await file.exists()) await file.delete();
      } catch (_) {}
      return null;
    }
  }

  /// 指定ジムのキャッシュを読み出す。無効・破損時は null
  Future<CachedGymPhotos?> read(int gymId) async {
    final entries = await _readEntries();
    final entry = entries?['$gymId'];
    if (entry is! Map<String, dynamic>) return null;

    final savedAt = DateTime.tryParse(entry['savedAt'] as String? ?? '');
    final data = entry['data'];
    if (savedAt == null || data is! Map<String, dynamic>) return null;

    return CachedGymPhotos(data: data, savedAt: savedAt);
  }

  /// 指定ジムの写真セット生JSONを保存する（失敗しても例外は投げない）
  Future<void> write(int gymId, Map<String, dynamic> rawData) async {
    try {
      final entries = await _readEntries() ?? <String, dynamic>{};
      entries['$gymId'] = {
        'savedAt': DateTime.now().toIso8601String(),
        'data': rawData,
      };
      _memoryEntries = entries;

      final file = await _cacheFile();
      await file.writeAsString(jsonEncode({
        'schemaVersion': schemaVersion,
        'entries': entries,
      }));
    } catch (_) {
      // 書き込み失敗は無視（次回もAPI取得になるだけ）
    }
  }
}
