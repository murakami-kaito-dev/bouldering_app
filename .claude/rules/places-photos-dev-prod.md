# ジム写真（Google Places）の dev / prod 差分ルール（このプロジェクト専用・恒久）

## 結論（守ること）

| 環境 | Google 写真フォールバック | Cloud Run 環境変数 |
|---|---|---|
| **prod**（`bouldering-api-prod`） | **有効**。自前写真が無いジムは Google Places の写真を出す | `PLACES_PHOTOS_ENABLED` 未設定（既定 true）＋ `PLACES_API_KEY` あり |
| **dev**（`bouldering-api-dev`） | **無効**。自前写真（`gym_photos`）だけ返し、Google には一切問い合わせない（`source: 'none'`） | `PLACES_PHOTOS_ENABLED=false` ＋ **`PLACES_API_KEY` を設定しない**（二重の安全弁） |

- **この差分は意図的なもので、解消しない。** dev で Google 写真が出ないのはバグではない。
- dev のデプロイで prod の環境変数一式をコピーしない。dev に `PLACES_API_KEY` を入れない。
- コード側の分岐は `backend/src/config/environment.ts`（`places.photosEnabled`）と
  `backend/src/services/placesService.ts`（`resolvePhotos` の Places 呼び出し前の早期 return）。
  この分岐を外す・既定値を変える変更は、ユーザーの明示的な指示があるときだけ。
- dev で Google 写真の挙動を確認したいときは、ユーザーの許可を得て**一時的に**環境変数を戻し、確認後に必ず元へ戻して
  `.claude/docs/deployment-log.md` に記録する。

## 経緯（なぜこの差分が生まれたか）

- Google Places API (New) の Photo Media は **¥1.1156/件**、無料枠は月 1,000 件。写真の解決結果は Cloud Run の
  **プロセス内メモリ**にしか置いていない（成功 7 日）ため、dev はインスタンスが 0 台に戻るたび（＝ほぼ毎回）取り直しになる。
- 2026-09-02 に検証スクリプトが dev・prod のジム写真を全件走査し、両環境の無料枠を 1 日で使い切った（Issue #89）。
- 2026-09-16〜25 の調査で、dev は「再起動のたびの取り直し」＋「dev Web（Cloud Run `bouldering-web-dev`）への Google 系
  クローラー巡回（`google-proxy-*.google.com` から毎時 10〜27 ページ）」で、誰も使っていない日でも月 3,000〜5,000 件
  （≒ ¥2,000〜4,500）を消費していた。
- ユーザー判断（2026-09-25）: 「写真は本番で表示されていればよい。dev では取得しない」→ 対策 B として dev を無効化。
  記録: `.claude/docs/deployment-log.md` 2026-09-25、Issue #89。

## 関連

- 従量課金 API を検証で全件走査しない: グローバル自動メモリ `never-sweep-paid-apis`
- 残る対策（キャッシュの DB 化＝E、`limit`＝D ほか）: Issue #89
