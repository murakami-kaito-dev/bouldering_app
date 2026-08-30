# バックエンド開発の標準ワークフロー（知見メモ）

2026-08-31、「バックエンドのデバッグのたびにDockerビルド→Cloud Runアップロードは面倒。標準的な開発はどうしているのか」という疑問への回答を知見化したもの。

## 結論: 「2つのループ」を使い分ける

バックエンド開発は、速さの違う2つのループで回すのが標準。**日常のデバッグにDockerもクラウドも使わない。**

### インナーループ（日常・コード変更のたび・1回数秒）

```bash
cd backend
cp .env.dev .env   # 初回のみ（devのSupabaseに接続するローカル用設定）
npm run dev        # http://localhost:8080 で起動
```

- nodemon + ts-node が**ファイル保存のたびに1〜2秒で自動再起動**する。Dockerビルド（数十秒〜数分）は不要。
- 動作確認: `curl http://localhost:8080/api/gyms/100/photos` / Postman / VSCode REST Client。
- 本格デバッグは **VSCodeデバッガでブレークポイント**を張り、変数を見ながらステップ実行（`console.log` より効率的）。
- Firebase認証の検証・Supabase接続は**ローカルでそのまま動く**（実証済み）。GCS/Cloud Tasksも `gcloud auth application-default login` の認証情報でローカルから動かせる。

### アウターループ（節目だけ・数分）

| タイミング | やること |
|---|---|
| PRを出す前 | ローカルで `docker build` + コンテナ起動 + `/health` 確認（本番と同じ動かし方でのパリティ確認） |
| 機能完成・アプリ実機との結合時 | dev Cloud Run へデプロイ（タグ `dev-YYYYMMDD-<SHA>`、commands.md 参照） |
| リリース時 | prod へデプロイ（`supabase-vX.Y.Z`） |

## アプリ（Flutter）とローカルバックエンドを繋ぐには

- Flutter側の接続先を一時的に `http://localhost:8080/api` に向ける。**iOSシミュレータはMacのlocalhostにそのまま届く**（実機の場合はMacのLAN IPを指定）。
- `environment_config.dart` に「local」環境を追加すれば切替式にできる（未実装・必要になったら5分仕事）。

## 使い分けの目安（表）

| 頻度 | やること | 所要 |
|---|---|---|
| コード変更のたび | `npm run dev` 起動しっぱなし + curl/デバッガ | 保存後1〜2秒 |
| PR前 | ローカルDockerビルド&起動確認 | 1〜2分 |
| 機能完成時 | dev Cloud Run デプロイ | 3〜5分 |
| リリース時 | prod デプロイ | 3〜5分 |

## 補足

- ローカルで完全再現できないもの（Cloud Tasksのキュー実挙動、Cloud Run固有のenv/権限など）だけは最終的にdev Cloud Runで確認する。
- チーム開発ではさらに「push→CIが自動テスト→devへ自動デプロイ」（CI/CD: GitHub Actions / Cloud Build）まで組むのが一般的。本プロジェクトは手動運用で、現規模ではCI/CDは必須ではない（将来の改善候補）。
- 関連: ローカル起動手順とタグ運用は [commands.md](commands.md)、デプロイ記録は [deployment-log.md](deployment-log.md)。
