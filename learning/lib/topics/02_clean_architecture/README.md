# 02 Clean Architecture 最小構成

## 本体での対応箇所

本体の `lib/` 全体がこの構造。1機能（ジム一覧）だけで層を貫通させたのがこのミニアプリ。

| このミニアプリ | 本体 |
|---|---|
| `domain/gym.dart` | `lib/domain/entities/gym.dart` |
| `domain/gym_repository.dart` | `lib/domain/repositories/gym_repository.dart` |
| `domain/get_gyms_usecase.dart` | `lib/domain/usecases/gym_usecases.dart` |
| `infrastructure/gym_datasource.dart` | `lib/infrastructure/datasources/gym_datasource.dart` |
| `infrastructure/gym_repository_impl.dart` | `lib/infrastructure/repositories/gym_repository_impl.dart` |
| `presentation/providers.dart` | `lib/presentation/providers/dependency_injection.dart` |
| `presentation/gym_list_page.dart` | `lib/presentation/pages/gym_search_result_page.dart` |

## 学べるポイント

1. **依存の向き**: `presentation → domain ← infrastructure`。ドメインが中心で、外側が内側に依存する。
   domain は Flutter にも HTTP にも依存しない純粋 Dart。
2. **依存性逆転（DIP）**: usecase は `GymRepository`（抽象）にだけ依存。実装（Impl）は DI で外から注入。
   → データ源を API から Fake / DB に差し替えてもドメイン層は無変更。
3. **各層の責務**:
   - entity: ビジネスの関心事
   - usecase: アプリの操作1つ（ビジネスルールはここ。例: 並び順）
   - datasource: 外部仕様（snake_case JSON）の吸収。内側に `Map` を漏らさない
   - repository impl: JSON → エンティティ変換
   - 画面: watch して描画するだけ

## 面接での定番質問

- 「なぜ層を分けるのか」→ 変更理由の分離。API仕様変更は infrastructure だけ、ビジネスルール変更は domain だけで済む。テスト容易性（抽象をモックできる）。
- 「やりすぎでは？」→ 小規模なら過剰。本体規模（画面23・API30超）だと datasource の差し替えやルールの置き場が効いてくる、と答えられるように。

## あえて削ぎ落としたもの

- 例外の層別変換（本体は `AppException` 階層に変換する）
- 入力バリデーション（本体は repository impl にもある — 実は usecase と重複しており本体のリファクタ候補）
