# 03 Riverpod 状態管理入門

## 本体での対応箇所

`lib/presentation/providers/` の22ファイル全部。特に:

- DIコンテナ: `dependency_injection.dart`（Provider 40超で datasource→repository→usecase を配線）
- StateNotifier の代表例: `general_tweets_provider.dart`, `block_provider.dart`, `favorite_user_provider.dart`
- FutureProvider + AsyncValue: `user_provider.dart`, `other_user_provider.dart`
- family: `other_user_tweets_provider.dart`（userIdごと）, `gym_tweets_provider.dart`（gymIdごと）
- autoDispose: `general_tweets_provider.dart`（タイムライン離脱で破棄）

## 学べるポイント

1. **Providerの種類の使い分け**（画面内の(1)〜(6)に対応）。本体の主役は `StateNotifierProvider`。
2. **不変更新**: `state.add()` ではなく `state = [...state, item]`。Riverpodは参照の変化で再ビルドを判定する。
3. **watch vs read**: build内は `watch`（購読）、コールバック内は `read`（1回きり）。
   build内で `read` すると値が変わっても再描画されない（本体の `gym_search_page.dart:156` がこのバグ候補だった）。
4. **AsyncValue**: loading / error / data の3状態を型で強制される。エラーブランチの描き忘れをコンパイル時に防ぐ。
5. **autoDispose**: 画面を離れたら状態を捨てるか、残すか。タイムラインは捨てる（メモリ）、ログインユーザーは残す（アプリ全体で共有）。

## 面接での定番質問

- 「Provider と StateNotifierProvider の違いは？」→ 前者は不変の値/依存の提供、後者は「状態+それを変える操作」のカプセル化。
- 「setState と何が違う？」→ 状態が画面ツリーの外にあるので、複数画面で共有でき、テストがウィジェット無しで書ける。
- 「グローバル変数と何が違う？」→ ProviderScope 単位で差し替え可能（テストで override）、依存関係が明示される、破棄が管理される。

## あえて削ぎ落としたもの

- riverpod_generator / freezed（本体も未使用。手書き copyWith が本体の流儀）
- ref.listen による副作用（スナックバー表示等）
