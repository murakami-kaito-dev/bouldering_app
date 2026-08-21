import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// トピック06: 楽観的UI更新とロールバック
///
/// 本体の対応箇所:
///   lib/presentation/providers/favorite_user_provider.dart（お気に入りユーザー）
///   lib/presentation/pages/gym_detail_page.dart（イキタイ登録）
///   lib/presentation/providers/block_provider.dart（ブロック）
///
/// 楽観的更新（Optimistic Update）とは:
///   APIの成功を待たずに先にUIを書き換え、失敗したら巻き戻す。
///   「いいね」のような高頻度・低リスク操作で体感速度を上げる定石。
///
/// 要点:
///   1. 先にUIを更新 → API実行 → 失敗したら元に戻す + エラー通知
///   2. 連打対策: 実行中の項目は追加操作を無視する（inFlight管理）
///   3. 巻き戻しは「操作前の値」ではなく「反転」で行うと、
///      連続操作との競合で壊れにくい（このデモでは反転方式）
/// ============================================================

class FavoriteGym {
  const FavoriteGym(this.id, this.name, {required this.isFavorite});
  final int id;
  final String name;
  final bool isFavorite;

  FavoriteGym copyWith({bool? isFavorite}) =>
      FavoriteGym(id, name, isFavorite: isFavorite ?? this.isFavorite);
}

/// Fake API: 3回に1回くらいの確率で失敗する
class FakeFavoriteApi {
  final _random = Random();
  Future<void> setFavorite(int gymId, bool value) async {
    await Future.delayed(const Duration(milliseconds: 800)); // 遅い回線を再現
    if (_random.nextInt(3) == 0) {
      throw Exception('サーバエラー (500)');
    }
  }
}

class FavoriteState {
  const FavoriteState({required this.gyms, this.inFlight = const {}});
  final List<FavoriteGym> gyms;
  final Set<int> inFlight; // 通信中のジムID（連打対策）
}

class FavoriteNotifier extends StateNotifier<FavoriteState> {
  FavoriteNotifier()
      : super(FavoriteState(gyms: [
          for (var i = 1; i <= 8; i++)
            FavoriteGym(i, 'ジム #$i', isFavorite: false),
        ]));

  final _api = FakeFavoriteApi();

  /// 巻き戻しコールバックを外から受け取る（スナックバー表示用）
  Future<void> toggle(int gymId, void Function(String) onRollback) async {
    // 要点2: 通信中の項目は無視（連打でリクエストが交差するのを防ぐ）
    if (state.inFlight.contains(gymId)) return;

    final newValue =
        !state.gyms.firstWhere((g) => g.id == gymId).isFavorite;

    // 要点1-a: まずUIを先に書き換える（楽観的更新）
    _apply(gymId, newValue, addInFlight: true);

    try {
      await _api.setFavorite(gymId, newValue);
      _apply(gymId, newValue, removeInFlight: true); // 確定
    } catch (e) {
      // 要点1-b: 失敗したら反転して巻き戻す + 通知
      _apply(gymId, !newValue, removeInFlight: true);
      onRollback('ジム #$gymId の更新に失敗したため巻き戻しました（$e）');
    }
  }

  void _apply(int gymId, bool value,
      {bool addInFlight = false, bool removeInFlight = false}) {
    state = FavoriteState(
      gyms: [
        for (final g in state.gyms)
          g.id == gymId ? g.copyWith(isFavorite: value) : g,
      ],
      inFlight: {
        ...state.inFlight,
        if (addInFlight) gymId,
      }..removeWhere((id) => removeInFlight && id == gymId),
    );
  }
}

final favoriteProvider =
    StateNotifierProvider.autoDispose<FavoriteNotifier, FavoriteState>(
        (ref) => FavoriteNotifier());

class OptimisticUpdatePage extends ConsumerWidget {
  const OptimisticUpdatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoriteProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('06 楽観的UI更新')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'ハートを押すと「即座に」切り替わるが、裏でAPI（800ms、1/3で失敗）が走っている。\n'
              '失敗すると自動で巻き戻り、スナックバーが出る。通信中は連打しても無視される。',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final gym in state.gyms)
                  ListTile(
                    title: Text(gym.name),
                    subtitle: state.inFlight.contains(gym.id)
                        ? const Text('通信中…', style: TextStyle(fontSize: 11))
                        : null,
                    trailing: IconButton(
                      icon: Icon(
                        gym.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: gym.isFavorite ? Colors.pink : Colors.grey,
                      ),
                      onPressed: () => ref
                          .read(favoriteProvider.notifier)
                          .toggle(gym.id, (message) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text(message)));
                      }),
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
