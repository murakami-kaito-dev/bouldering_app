# 08 画像アップロードのパイプライン

## 本体での対応箇所

- `lib/presentation/pages/activity_post_page.dart:109` — `file_picker` で最大5枚選択
- `lib/domain/usecases/activity_post_usecases.dart` — 投稿＋アップロードの統合ユースケース
- `lib/domain/usecases/image_picker_usecases.dart` — バリデーション（サイズ上限）
- `lib/infrastructure/services/storage_service.dart` — GCSへ**フロントから直接**アップロード
- バックエンド側: `backend/src/domain/services/StoragePathService.ts` — パス設計、`storageCleanupPublisher.ts` — 投稿削除時のprefix一括削除（Cloud Tasks）

## 本体のパイプライン（このミニアプリが抽出した流れ）

```
①選択 → ②バリデーション(枚数≤5, サイズ≤10MB) → ③UUIDパス生成
→ ④アップロード(進捗) → ⑤URL群を添えて投稿API → ⑥失敗時は後始末
```

## 学べるポイント

1. **パス設計が削除を決める**: `v1/public/users/{userId}/posts/{yyyy}/{mm}/{postUuid}/{assetUuid}/original.jpg` のように階層化しておくと、投稿削除時に「postUuid配下をprefix一括削除」できる。フラットに置くとDBを引かないと消せない。
2. **並列アップロード**: `Future.wait` で並列に。直列forループ+awaitはN倍遅い（本体の `favorite_usecases.dart` に直列awaitのN+1があり、リファクタ候補になっている）。
3. **部分失敗の後始末**: 1枚でも失敗したら成功済み分を削除してロールバック。怠ると誰からも参照されない**孤児画像**がストレージに溜まり続ける（本体でもenv設定漏れ時に削除がサイレントスキップされる問題が調査で見つかっている）。
4. **不変リスト更新と進捗表示**: 進捗のような高頻度更新でも `state = [...state]` の参照差し替えで再描画をトリガする。

## 面接での定番質問

- 「クライアントから直接ストレージに上げますか？サーバ経由？」→ 本体は直接方式（＋サービスアカウント鍵をアプリ同梱 — これはセキュリティ上の弱点として調査で指摘済み）。模範解答は**サーバが発行する署名付きURL**方式: 鍵を配らず、権限を最小化できる。
- 「アップロード中にアプリが落ちたら？」→ 孤児画像が残る。対策は定期クリーンアップバッチ or 投稿確定時にのみ参照を張り、未参照を削除。
- 「進捗表示はどう実装しますか？」→ HTTPのchunk送信コールバック（dio等）で進捗イベントを受けてUIへ流す。

## あえて削ぎ落としたもの

- 実際のファイル選択（file_pickerプラグイン）と実ストレージ（擬似画像＋遅延で代替）
- 画像圧縮・EXIF除去（本番アプリでは検討事項）
