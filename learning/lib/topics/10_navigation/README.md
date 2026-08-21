# 10 ルーティングと画面間の値渡し

## 本体での対応箇所

- `lib/shared/constants/app_routes.dart` — ルート名（AppRoutes）とパラメータキー（RouteParams）の定数
- `lib/presentation/pages/app.dart:58-90` — `MaterialApp.routes` へのルート登録
- `lib/shared/utils/navigation_helper.dart` — pushNamed のラッパ（型安全化の入口）
- `lib/presentation/pages/gym_selection_page.dart` — **値を返す画面**の実例（`selectionMode` で「詳細遷移」か「選択値を返す」かを切り替える設計）

## 学べるポイント

1. **A) pushNamed + arguments(Map)**: 本体の主流。キーは `RouteParams` 定数に集約してタイプミスを減らす。ただし型・キーの誤りは実行時まで分からない。
2. **B) 値を返す遷移**: `final result = await Navigator.push<String>(...)` → 遷移先で `Navigator.pop(context, value)`。**戻るボタンで帰ると null** なので必ずnull処理する。フォームの選択画面の定石。
3. **C) 型安全ラッパ**: 遷移関数を1つ作り引数を型で受ける。`go_router` の型付きルートはこの発展形。
4. **登録漏れに注意**: `pushNamed` は登録されていないルート名だと**実行時例外**。本体には「定数だけあってルート未登録」が5件あり、呼べば落ちる状態（`refactor-candidates.md` 参照）。宣言的ルーティング（go_router）ならこれをビルド時に近い段階で検出しやすい。

## 本体のナビゲーションの現状（学びの反面教師）

調査の結果、本体には遷移方法が**3方式混在**している:

1. `NavigationHelper`（pushNamedラッパ）
2. `NavigationService`（MaterialPageRoute直）
3. 各画面での `MaterialPageRoute` 直書き

機能は同じでも書き方が散らばると、修正時に探す場所が増える。「1方式に寄せる」のがリファクタ候補になっている。go_router がpubspecに入っているのに未使用、というのも調査で判明した事実。

## 面接での定番質問

- 「Navigator 1.0 と 2.0 / go_router の違いは？」→ 命令的（push/pop）vs 宣言的（URL⇄画面状態の同期）。ディープリンクやWeb対応が要るなら宣言的が有利。
- 「画面間で大きなデータはどう渡す？」→ IDだけ渡して遷移先で再取得（本体方式）か、状態管理層（Provider）経由で共有。オブジェクトをargumentsに直接詰めるのは画面復元（state restoration）で壊れる。

## あえて削ぎ落としたもの

- `MaterialApp.routes` への一括登録（ミニアプリはトピック間の独立性を優先して `RouteSettings` で再現）
- ディープリンク
