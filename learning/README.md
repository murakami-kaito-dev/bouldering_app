# 学習用ミニアプリ集（bouldering_learning）

本体アプリ「イワノボリタイ」の各機能を**復習・再理解する**ための学習用ミニアプリ。
本体から機能の本質だけを抽出し、実行に外部設定（Firebase・APIキー等）が一切不要になるよう Fake で置き換えている。

分割の粒度は「テック企業の技術面接で問われる質問への回答・予習になる単位」。

## 実行方法

```bash
cd learning
flutter pub get
flutter run          # シミュレータでランチャーが起動し、10トピックを選べる
```

トピック05（環境切替）だけは起動オプションで挙動が変わる（`lib/topics/05_env_switching/README.md` 参照）。

## トピック一覧

| # | タイトル | 面接想定質問 | 本体の対応箇所（代表） |
|---|---|---|---|
| [01](lib/topics/01_infinite_scroll/README.md) | 無限スクロール & Pull-to-Refresh | 無限スクロールはどう実装しますか？ | `general_tweets_provider.dart` |
| [02](lib/topics/02_clean_architecture/README.md) | Clean Architecture 最小構成 | 層と依存の向きを説明してください | `lib/` 全体の構造 |
| [03](lib/topics/03_riverpod_basics/README.md) | Riverpod 状態管理入門 | 状態管理に何を使い、なぜですか？ | `providers/` 22ファイル |
| [04](lib/topics/04_auth_flow/README.md) | 認証フローとトークン管理 | トークン失効をどう検知しますか？ | `api_client.dart`, `auth_provider.dart` |
| [05](lib/topics/05_env_switching/README.md) | 環境切替（dev/prod） | 開発と本番をどう分離しますか？ | `main_dev/prod.dart`, `environment_config.dart` |
| [06](lib/topics/06_optimistic_update/README.md) | 楽観的UI更新とロールバック | いいねの即時反映はどう実装しますか？ | `favorite_user_provider.dart` |
| [07](lib/topics/07_search_filter/README.md) | 検索とフィルタリング | インクリメンタル検索の性能問題は？ | `gym_name_search_provider.dart` |
| [08](lib/topics/08_image_upload/README.md) | 画像アップロードのパイプライン | 画像アップロードの設計は？ | `activity_post_usecases.dart`, `storage_service.dart` |
| [09](lib/topics/09_text_moderation/README.md) | テキストモデレーション | 不適切語フィルタをどう作りますか？ | `local_text_moderation_service.dart` |
| [10](lib/topics/10_navigation/README.md) | ルーティングと値渡し | 画面遷移でデータをどう渡しますか？ | `app_routes.dart`, `gym_selection_page.dart` |

## 読み方のガイド

1. まず動かして挙動を見る（各画面に「何が起きているか」の説明を埋め込んである）
2. トピックフォルダの `README.md` で「本体のどこに対応するか」「面接での答え方」を読む
3. 本体の対応ファイルを開いて、ミニアプリとの差分（＝削ぎ落とした複雑さ）を確認する

## 設計方針

- **依存は flutter_riverpod のみ**。Firebase・Maps・file_picker 等のプラグインは使わず Fake で再現（クローン直後に必ず動く）
- 各トピックは `lib/topics/NN_名前/` で完結し、**相互依存なし**（1トピックだけ読める）
- 本体調査で見つかったバグ・リファクタ候補（`.claude/docs/refactor-candidates.md`）のうち学びになるものは、各READMEで「本体の反面教師」として言及している
