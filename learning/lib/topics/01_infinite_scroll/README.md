# 01 無限スクロール & Pull-to-Refresh

## 本体での対応箇所

- `lib/presentation/providers/general_tweets_provider.dart` — カーソル方式ページネーション（20件ずつ）
- `lib/presentation/providers/my_tweets_provider.dart` — こちらは**オフセット方式**（offset/limit）
- `lib/presentation/components/tweet/general_tweets_section.dart` — スクロール検知とUI

## 学べるポイント

1. **スクロール検知**: `ScrollController` を張り、`pixels >= maxScrollExtent - 100` で「終端の少し手前」から先読みする。
   厳密に `==` で比較すると物理挙動によっては発火しない（本体の `other_user_tweets_section.dart:44` がまさにこのバグ候補だった）。
2. **多重ロード防止**: `isLoading` ガード。スクロールイベントは1フレームに何度も飛んでくるので必須。
3. **終端表現**: `hasMore` フラグ。`itemCount` に `+1` してローディング行を出し分ける。
4. **リフレッシュ**: カーソルを捨てて1ページ目から取り直し、成功するまで既存リストを保持する。

## カーソル方式 vs オフセット方式（面接での比較ポイント）

| | カーソル方式 | オフセット方式 |
|---|---|---|
| リクエスト | 「ID=40 の続きをくれ」 | 「40件目から20件くれ」 |
| 途中で新規投稿が入ると | ズレない（IDを基準に続きを取るため） | **ズレる**（同じ投稿が2回出る/飛ぶ） |
| 任意ページへのジャンプ | 不可 | 可能 |
| 向く用途 | SNSタイムライン | 管理画面のページ番号付き一覧 |

本体はタイムライン系にカーソル方式、自分の投稿一覧にオフセット方式を使い分けている。

## あえて削ぎ落としたもの

- エラーハンドリング（本体では AsyncValue / try-catch で処理）
- Pull-to-Refresh 中の多重リフレッシュ制御
- 実HTTP通信（FakeTweetApi の 500ms 遅延で代替）
