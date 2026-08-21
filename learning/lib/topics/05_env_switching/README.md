# 05 環境切替（dev/prod）

## 本体での対応箇所

- `lib/main_dev.dart` / `lib/main_prod.dart` — エントリポイント。importする firebase_options と `EnvironmentConfig.setEnvironment()` で環境確定
- `lib/shared/config/environment_config.dart` — dev/prod のAPI接続先定義
- `lib/shared/config/app_env.dart` — `String.fromEnvironment('ENVIRONMENT')` の読み取りと整合性検証
- `lib/presentation/providers/dependency_injection.dart:87-114` — dart-define によるGCSバケット/鍵の分岐
- `ios/Runner.xcodeproj` — Flavor（Runner Dev / Runner Prod）。Bundle ID と GoogleService-Info.plist の切替

## 本体の「3点セット」

| 仕組み | 指定方法 | 決まるもの | 決まるタイミング |
|---|---|---|---|
| ① エントリポイント | `--target lib/main_dev.dart` | API接続先・Firebaseプロジェクト | 実行時（main関数） |
| ② dart-define | `--dart-define=ENVIRONMENT=dev` | GCSバケット・鍵パス | **コンパイル時**（const） |
| ③ Flavor | `--flavor "Runner Dev"` | Bundle ID・アプリ名・GoogleService-Info.plist | ビルド設定（Xcode） |

3つは**独立して動く**ため、片方だけ指定すると環境が混在する。だから本体は `fdev` / `fprod` エイリアスで必ず3点同時指定する。

## 学べるポイント

1. **`String.fromEnvironment` はコンパイル時定数**。実行中に変えられない。`const` で受けるのが正しい。
2. **エントリポイント分割の利点**: dev専用の初期化（設定ダンプ・検証ログ）を prod バイナリに一切含めない。
3. **整合性検証の重要性**: 本体の `AppEnv.validateConsistency()` は②と③の一致しか見ておらず、①とのズレは検出できない（調査で判明した本体の弱点。`refactor-candidates.md` 参照）。このミニアプリでは①と②の照合を実装した。
4. **Flavorの役割**: Bundle IDを分けることで dev/prod を**同じ端末に同時インストール**できる。Firebaseプロジェクトの分離も Flavor 連動の Run Script（GoogleService-Info.plist のコピー）で実現している。

## 面接での定番質問

- 「dev/stg/prod をどう分けていますか？」→ この3点セット＋バックエンド側も Cloud Run サービス・DB・Firebaseプロジェクトごと分離、と答えられるように。
- 「APIキーをコードに埋めないためには？」→ dart-define / 環境別設定ファイル（gitignore）/ CI のシークレット注入。

## 試し方

```bash
cd learning
flutter run                                              # dev一致（正常）
flutter run --dart-define=ENVIRONMENT=prod               # ミスマッチを体験
flutter run -t lib/main_prod.dart --dart-define=ENVIRONMENT=prod  # prod一致
```

## あえて削ぎ落としたもの

- Flavor（③）: Xcodeプロジェクト設定が必要なため。仕組みは上表とREADMEで理解する
- Firebaseプロジェクト切替（firebase_options の import 差し替え）
