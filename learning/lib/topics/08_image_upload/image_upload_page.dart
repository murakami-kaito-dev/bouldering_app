import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// トピック08: 画像アップロードのパイプライン
///
/// 本体の対応箇所:
///   lib/presentation/pages/activity_post_page.dart（file_pickerで最大5枚選択）
///   lib/domain/usecases/activity_post_usecases.dart（投稿+アップロードの統合）
///   lib/infrastructure/services/storage_service.dart（GCSへ直接アップロード）
///
/// 本体のパイプライン:
///   ①選択(file_picker) → ②バリデーション(枚数/サイズ) →
///   ③UUIDでパス生成 → ④並列アップロード(進捗表示) →
///   ⑤成功したURL群を添えて投稿API → ⑥途中失敗ならアップ済み分を削除(後始末)
///
/// このミニアプリはプラグインなしで動くよう、
/// 「選択」= ランダム色の擬似画像生成、「アップロード」= 遅延+乱数失敗
/// に置き換えて、②〜⑥の流れだけを抽出している。
/// ============================================================

const maxImages = 5; // 本体と同じ上限
const maxSizeMB = 10;

enum UploadStatus { pending, uploading, done, failed }

class PickedImage {
  PickedImage({
    required this.id,
    required this.color,
    required this.sizeMB,
    this.status = UploadStatus.pending,
    this.progress = 0,
    this.uploadedPath,
  });
  final String id; // 本体はUUID。ここでは連番+乱数で代用
  final Color color; // 擬似画像
  final double sizeMB;
  UploadStatus status;
  double progress;
  String? uploadedPath;
}

/// 本体の StoragePathService に相当するパス設計。
/// 「ユーザー/年月/投稿UUID/アセットUUID」の階層にしておくと、
/// 投稿削除時に prefix 一括削除できる（本体はCloud Tasksで非同期削除）。
String buildStoragePath(String userId, String postUuid, String assetId) {
  final now = DateTime.now();
  final yyyy = now.year.toString();
  final mm = now.month.toString().padLeft(2, '0');
  return 'v1/public/users/$userId/posts/$yyyy/$mm/$postUuid/$assetId/original.jpg';
}

class UploadNotifier extends StateNotifier<List<PickedImage>> {
  UploadNotifier() : super([]);
  final _random = Random();
  int _seq = 0;

  String? pick() {
    // ②バリデーション: 枚数上限
    if (state.length >= maxImages) {
      return '画像は最大 $maxImages 枚までです';
    }
    final sizeMB = 1 + _random.nextInt(14) + _random.nextDouble();
    final image = PickedImage(
      id: 'asset-${++_seq}-${_random.nextInt(9999)}',
      color: Colors
          .primaries[_random.nextInt(Colors.primaries.length)].shade400,
      sizeMB: double.parse(sizeMB.toStringAsFixed(1)),
    );
    // ②バリデーション: サイズ上限（本体は10MB）
    if (image.sizeMB > maxSizeMB) {
      return '${image.sizeMB}MB の画像は上限 ${maxSizeMB}MB を超えています'
          '（たまに大きい画像が引かれるので何回か試すと見られる）';
    }
    state = [...state, image];
    return null;
  }

  void remove(String id) =>
      state = state.where((e) => e.id != id).toList();

  /// ④並列アップロード → ⑤/⑥
  Future<String> uploadAll() async {
    final postUuid = 'post-${DateTime.now().millisecondsSinceEpoch}';
    final targets =
        state.where((e) => e.status != UploadStatus.done).toList();

    // Future.wait で並列実行（本体のような直列forループawaitはN+1で遅い）
    final results = await Future.wait(
        targets.map((img) => _uploadOne(img, postUuid)));

    if (results.contains(false)) {
      // ⑥後始末: 1枚でも失敗したら、成功済み分を削除して部分成功を残さない
      final orphans =
          state.where((e) => e.status == UploadStatus.done).length;
      for (final img in state) {
        img
          ..status = UploadStatus.pending
          ..progress = 0
          ..uploadedPath = null;
      }
      state = [...state];
      return '失敗があったため中断。アップ済み $orphans 枚を削除（ロールバック）した。\n'
          '※これを怠ると誰からも参照されない「孤児画像」がストレージに残る';
    }
    return '全 ${targets.length} 枚アップロード成功。'
        'このURL群を添えて投稿APIを呼ぶのが本体の流れ（⑤）';
  }

  Future<bool> _uploadOne(PickedImage img, String postUuid) async {
    img.status = UploadStatus.uploading;
    // 進捗を10%刻みで再現
    for (var p = 0.0; p <= 1.0; p += 0.1) {
      await Future.delayed(Duration(milliseconds: 60 + _random.nextInt(120)));
      img.progress = p;
      state = [...state]; // 参照差し替えで再描画をトリガ
    }
    if (_random.nextInt(5) == 0) {
      img.status = UploadStatus.failed;
      state = [...state];
      return false;
    }
    img
      ..status = UploadStatus.done
      ..uploadedPath = buildStoragePath('user-123', postUuid, img.id);
    state = [...state];
    return true;
  }
}

final uploadProvider =
    StateNotifierProvider.autoDispose<UploadNotifier, List<PickedImage>>(
        (ref) => UploadNotifier());

class ImageUploadPage extends ConsumerWidget {
  const ImageUploadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);
    final uploading =
        images.any((e) => e.status == UploadStatus.uploading);

    void showMessage(String m) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 4)));

    return Scaffold(
      appBar: AppBar(title: const Text('08 画像アップロード')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              '「画像を選ぶ」= 擬似画像生成（サイズ乱数、10MB超は弾かれる）。\n'
              '「アップロード」は並列実行・進捗表示・1/5で失敗。\n'
              '失敗すると成功済み分もロールバックされる（孤児画像を作らない）。',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: uploading
                      ? null
                      : () {
                          final error = notifier.pick();
                          if (error != null) showMessage(error);
                        },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text('画像を選ぶ (${images.length}/$maxImages)'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: images.isEmpty || uploading
                      ? null
                      : () async =>
                          showMessage(await notifier.uploadAll()),
                  child: const Text('アップロード'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                for (final img in images)
                  ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: img.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    title: Text('${img.id}  (${img.sizeMB}MB)'),
                    subtitle: switch (img.status) {
                      UploadStatus.pending => const Text('未アップロード'),
                      UploadStatus.uploading =>
                        LinearProgressIndicator(value: img.progress),
                      UploadStatus.done => Text(
                          img.uploadedPath!,
                          style: const TextStyle(fontSize: 9),
                        ),
                      UploadStatus.failed => const Text('失敗',
                          style: TextStyle(color: Colors.red)),
                    },
                    trailing: img.status == UploadStatus.uploading
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => notifier.remove(img.id),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
