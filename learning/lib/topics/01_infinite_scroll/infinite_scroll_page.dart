import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// トピック01: 無限スクロール & Pull-to-Refresh
///
/// 本体の対応箇所:
///   lib/presentation/providers/general_tweets_provider.dart（カーソル方式・20件）
///   lib/presentation/components/tweet/general_tweets_section.dart
///
/// 実装の要点:
///   1. ScrollController でスクロール位置を監視し、
///      「終端の少し手前（-100px）」で次ページをロードする
///      （厳密に == maxScrollExtent で判定すると発火しないことがある。
///        本体でもこの不統一がバグ候補として見つかった）
///   2. isLoading ガードで多重ロードを防止する
///   3. hasMore フラグで「もう次がない」状態を表現する
///   4. リフレッシュはカーソルを捨てて1ページ目から取り直す
/// ============================================================

/// ---- Fake API（サーバの代わり。500ms遅延でカーソルページングを再現）----
class FakeTweetApi {
  static const _total = 65; // 全件数（3ページ+端数で hasMore の変化が見える）
  static const pageSize = 20;

  /// カーソル方式: 「前回返した最後のID」を受け取り、その続きを返す。
  /// オフセット方式（offset/limit）との違いは README 参照。
  Future<({List<String> items, String? nextCursor})> fetch(
      {String? cursor}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, _total);
    final items = [for (var i = start; i < end; i++) 'ボル活投稿 #${i + 1}'];
    return (items: items, nextCursor: end < _total ? '$end' : null);
  }
}

/// ---- 状態とStateNotifier（本体の generalTweetsProvider と同じ構造）----
class TweetListState {
  const TweetListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.cursor,
  });
  final List<String> items;
  final bool isLoading;
  final bool hasMore;
  final String? cursor;

  TweetListState copyWith({
    List<String>? items,
    bool? isLoading,
    bool? hasMore,
    String? cursor,
  }) =>
      TweetListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        cursor: cursor, // カーソルは「毎回上書き」する（?? this.cursor にしない）
      );
}

class TweetListNotifier extends StateNotifier<TweetListState> {
  TweetListNotifier(this._api) : super(const TweetListState()) {
    loadMore(); // 初回ロード
  }
  final FakeTweetApi _api;

  Future<void> loadMore() async {
    // 要点2: 多重ロード防止。スクロールイベントは連続で飛んでくる
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, cursor: state.cursor);

    final page = await _api.fetch(cursor: state.cursor);
    state = state.copyWith(
      items: [...state.items, ...page.items],
      isLoading: false,
      hasMore: page.nextCursor != null,
      cursor: page.nextCursor,
    );
  }

  Future<void> refresh() async {
    // 要点4: カーソルを捨てて最初から。既存リストは成功するまで保持する
    final page = await _api.fetch(cursor: null);
    state = TweetListState(
      items: page.items,
      hasMore: page.nextCursor != null,
      cursor: page.nextCursor,
    );
  }
}

final tweetListProvider =
    StateNotifierProvider.autoDispose<TweetListNotifier, TweetListState>(
        (ref) => TweetListNotifier(FakeTweetApi()));

/// ---- 画面 ----
class InfiniteScrollPage extends ConsumerStatefulWidget {
  const InfiniteScrollPage({super.key});

  @override
  ConsumerState<InfiniteScrollPage> createState() => _InfiniteScrollPageState();
}

class _InfiniteScrollPageState extends ConsumerState<InfiniteScrollPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Controllerは必ず破棄する
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    // 要点1: 終端ぴったりではなく「100px手前」で先読みする
    if (pos.pixels >= pos.maxScrollExtent - 100) {
      ref.read(tweetListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tweetListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('01 無限スクロール')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(tweetListProvider.notifier).refresh(),
        child: ListView.builder(
          controller: _scrollController,
          // RefreshIndicator は「常にスクロール可能」でないと引っ張れない
          physics: const AlwaysScrollableScrollPhysics(),
          // 要点3: hasMore の間だけ末尾にローディング行を1つ足す
          itemCount: state.items.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= state.items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return ListTile(
              leading: const Icon(Icons.terrain),
              title: Text(state.items[i]),
              subtitle: const Text('カーソル方式で ${FakeTweetApi.pageSize} 件ずつ取得'),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          '取得済み ${state.items.length} 件 / hasMore=${state.hasMore}'
          '${state.isLoading ? '（ロード中…）' : ''}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
