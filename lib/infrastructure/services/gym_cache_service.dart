import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// キャッシュ読み出し結果（生JSONリスト + 保存時刻）
class CachedGyms {
  const CachedGyms({required this.data, required this.savedAt});

  final List<dynamic> data;
  final DateTime savedAt;

  /// TTL以内なら新鮮（裏の再取得も不要）
  bool get isFresh =>
      DateTime.now().difference(savedAt) < GymCacheService.ttl;
}

/// ジム全件データの永続キャッシュサービス
///
/// 役割:
/// - GET /gyms の生レスポンス(List<Map>)をローカルファイルにJSON保存する
/// - ジム情報の大半（名前・住所・座標・営業時間・料金）は数日単位で変わらないため、
///   431件×約1MBの取得を起動のたびに行わないようにする（通信量・時間・UXの改善）
///
/// 設計上のポイント:
/// - 「生JSON」のまま保存する。エンティティ変換(_mapToGymEntity)は読み出し側で行うため、
///   Gym.toJson の新設が不要で、マッピング修正が過去の保存分にも自動で効く
/// - schemaVersion で世代管理（バックエンドのキー名変更時に bump して旧キャッシュを無効化）
/// - 保存先は ApplicationSupport（ユーザー非可視。Temporary はOSに消されるため不可）
/// - 読み書きの失敗はすべて「キャッシュなし」に丸め、アプリの動作を壊さない
class GymCacheService {
  /// キャッシュ形式の世代。バックエンドのレスポンスのキー名が変わったら上げること
  static const int schemaVersion = 1;

  /// この期間内は「新鮮」扱い（超えたら即返却しつつ裏で再取得）
  static const Duration ttl = Duration(hours: 24);

  static const String _fileName = 'gyms_cache_v1.json';

  // 同一セッション内のディスク再読込を避けるためのメモリ保持
  List<dynamic>? _memoryData;
  DateTime? _memorySavedAt;

  Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// キャッシュを読み出す。無効・破損時は null（ファイルは削除）
  Future<CachedGyms?> read() async {
    if (_memoryData != null && _memorySavedAt != null) {
      return CachedGyms(data: _memoryData!, savedAt: _memorySavedAt!);
    }

    File? file;
    try {
      file = await _cacheFile();
      if (!await file.exists()) return null;

      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic> ||
          json['schemaVersion'] != schemaVersion) {
        await file.delete();
        return null;
      }

      final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
      final data = json['data'];
      if (savedAt == null || data is! List) {
        await file.delete();
        return null;
      }

      _memoryData = data;
      _memorySavedAt = savedAt;
      return CachedGyms(data: data, savedAt: savedAt);
    } catch (_) {
      // 破損ファイルは削除して「キャッシュなし」として扱う
      try {
        if (file != null && await file.exists()) await file.delete();
      } catch (_) {}
      return null;
    }
  }

  /// 生JSONリストを保存する（失敗しても例外は投げない＝キャッシュなし運用に落ちるだけ）
  Future<void> write(List<dynamic> rawData) async {
    try {
      final file = await _cacheFile();
      final now = DateTime.now();
      await file.writeAsString(jsonEncode({
        'schemaVersion': schemaVersion,
        'savedAt': now.toIso8601String(),
        'data': rawData,
      }));
      _memoryData = rawData;
      _memorySavedAt = now;
    } catch (_) {
      // 書き込み失敗は無視（次回もAPI取得になるだけ）
    }
  }

  /// キャッシュを破棄する
  Future<void> invalidate() async {
    _memoryData = null;
    _memorySavedAt = null;
    try {
      final file = await _cacheFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
