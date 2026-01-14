# iOS Flutter Flavor セットアップガイド

## 概要
このガイドでは、iOS向けFlutter Flavorを設定して、開発環境と本番環境を異なるBundle IDで分離する方法を説明します：
- 開発環境: `com.km.boulderingapp.dev`
- 本番環境: `com.km.boulderingapp`

## Firebase設定ファイル構造
Firebase設定ファイルは以下のように整理します：
```
ios/Runner/Firebase/
├── dev/
│   └── GoogleService-Info.plist    # 開発環境用Firebase設定
└── prod/
    └── GoogleService-Info.plist    # 本番環境用Firebase設定
```

## ステップ 1: XcodeでBuild Configurationを作成

1. `ios/Runner.xcodeproj`をXcodeで開く
2. ナビゲータでRunnerプロジェクトを選択
3. **PROJECT > Runner**を選択（TARGETSではなくPROJECT）
4. 「Info」タブに移動
5. 「Configurations」の下で、既存の設定を複製：
   - 「Debug」を複製 → 「Debug-Runner Dev」に名前変更
   - 「Debug」を複製 → 「Debug-Runner Prod」に名前変更
   - 「Release」を複製 → 「Release-Runner Dev」に名前変更
   - 「Release」を複製 → 「Release-Runner Prod」に名前変更
   - 「Profile」を複製 → 「Profile-Runner Dev」に名前変更
   - 「Profile」を複製 → 「Profile-Runner Prod」に名前変更
   - 注意: 元の「Debug」「Release」「Profile」は削除しても構いません（Flavorを使用する場合は不要になるため）

## ステップ 2: Bundle Identifierを設定

1. **TARGETS > Runner**を選択
2. 「Build Settings」タブに移動
3. 「Product Bundle Identifier」を検索
4. 各設定のBundle Identifierを設定：
   - Debug-Runner Dev: `com.km.boulderingapp.dev`
   - Debug-Runner Prod: `com.km.boulderingapp`
   - Release-Runner Dev: `com.km.boulderingapp.dev`
   - Release-Runner Prod: `com.km.boulderingapp`
   - Profile-Runner Dev: `com.km.boulderingapp.dev`
   - Profile-Runner Prod: `com.km.boulderingapp`

   **元の設定について（削除しない場合）：**
   - Debug: `com.km.boulderingapp.dev`（または削除）
   - Release: `com.km.boulderingapp.dev`（または削除）
   - Profile: `com.km.boulderingapp.dev`（または削除）

   ※推奨: 元の設定は削除することで、誤って使用することを防げます

## ステップ 3: アプリ表示名を設定

1. **TARGETS > Runner**を選択（継続）
2. 「Build Settings」タブで「Product Name」を検索
3. 表示名を設定：
   - Debug-Runner Dev: `Bouldering App Dev`
   - Debug-Runner Prod: `Bouldering App`
   - Release-Runner Dev: `Bouldering App Dev`
   - Release-Runner Prod: `Bouldering App`
   - Profile-Runner Dev: `Bouldering App Dev`
   - Profile-Runner Prod: `Bouldering App`

## ステップ 4: Xcodeスキームを作成

1. XcodeでProduct → Scheme → Manage Schemesに移動
2. 新しいスキームを作成：
   - 「+」をクリックして新しいスキームを追加
   - 名前を「Runner Dev」に設定
   - RunとTestのBuild Configurationを「Debug-Runner Dev」に設定
   - ArchiveのBuild Configurationを「Release-Runner Dev」に設定
   - 「Shared」チェックボックスをチェック
3. 本番環境用も同様に作成：
   - 名前を「Runner Prod」に設定
   - RunとTestのBuild Configurationを「Debug-Runner Prod」に設定
   - ArchiveのBuild Configurationを「Release-Runner Prod」に設定
   - 「Shared」チェックボックスをチェック

## ステップ 5: Firebase設定スクリプトをセットアップ

1. **TARGETS > Runner**を選択
2. 「Build Phases」タブに移動（Build Rulesタブではない）
   - 既存のビルドフェーズが表示されることを確認（Target Dependencies, Compile Sources, Link Binary With Libraries等）
3. 新しいRun Scriptを追加：
   - 方法1: 左上の「+」ボタンを**長押し**または**クリック**してメニューを表示
   - 方法2: メニューバーから Editor → Add Build Phase → **New Run Script Phase**
4. 新しく追加された「Run Script」フェーズを見つける
   - リストの一番下に追加されている場合が多い
   - 左側の三角マークをクリックして展開
5. Run Scriptの名前を変更：
   - 「Run Script」というテキストをダブルクリック
   - 「Setup Firebase Config」に変更
6. スクリプトフェーズの位置を調整：
   - 「Setup Firebase Config」の左側をドラッグ
   - 「Compile Sources」フェーズの**上**に移動
7. スクリプトエディタ部分の設定：
   - **Shell**: `/bin/sh`（デフォルト値のまま）
   - その他の設定は基本的にデフォルトのまま
8. スクリプト本体を記入：
   - エディタ部分（大きなテキストエリア）にデフォルトで書かれているコメントを削除
   - 以下のスクリプトをコピー&ペースト：

```bash
#!/bin/bash

# Firebase設定ファイルへのパス
FIREBASE_DEV_PATH="${SRCROOT}/Runner/Firebase/dev/GoogleService-Info.plist"
FIREBASE_PROD_PATH="${SRCROOT}/Runner/Firebase/prod/GoogleService-Info.plist"
FIREBASE_TARGET_PATH="${SRCROOT}/Runner/GoogleService-Info.plist"

# 設定に基づいて使用する設定ファイルを決定
if [[ "${CONFIGURATION}" == *"Dev"* ]]; then
    echo "開発環境用Firebase設定を使用"
    if [ -f "$FIREBASE_DEV_PATH" ]; then
        cp "$FIREBASE_DEV_PATH" "$FIREBASE_TARGET_PATH"
    else
        echo "エラー: 開発環境用Firebase設定が見つかりません: $FIREBASE_DEV_PATH"
        exit 1
    fi
elif [[ "${CONFIGURATION}" == *"Prod"* ]]; then
    echo "本番環境用Firebase設定を使用"
    if [ -f "$FIREBASE_PROD_PATH" ]; then
        cp "$FIREBASE_PROD_PATH" "$FIREBASE_TARGET_PATH"
    else
        echo "エラー: 本番環境用Firebase設定が見つかりません: $FIREBASE_PROD_PATH"
        exit 1
    fi
else
    echo "エラー: 不明な設定 $CONFIGURATION"
    exit 1
fi
```

## ステップ 6: Firebaseディレクトリ構造を確認

Firebase設定ファイルが以下の場所に配置されていることを確認：
- 開発環境: `ios/Runner/Firebase/dev/GoogleService-Info.plist`
- 本番環境: `ios/Runner/Firebase/prod/GoogleService-Info.plist`

※すでにディレクトリとファイルが存在する場合は、このステップはスキップして構いません。

## ステップ 7: Flutter起動設定を更新

適切なスキームを使用するようにFlutter起動設定を更新：

### 開発環境での起動
```bash
flutter run --flavor "Runner Dev" --dart-define=ENVIRONMENT=dev --target lib/main_dev.dart
```

### 本番環境での起動
```bash
flutter run --flavor "Runner Prod" --dart-define=ENVIRONMENT=prod --target lib/main_prod.dart
```

## ステップ 8: GitIgnoreを更新

`.gitignore`に以下を追加：
```
# Firebase設定（テンプレート構造は保持）
ios/Runner/GoogleService-Info.plist
```

環境固有の設定はバージョン管理に含める：
- `ios/Runner/Firebase/dev/GoogleService-Info.plist`
- `ios/Runner/Firebase/prod/GoogleService-Info.plist`

## 検証

セットアップ後、以下を確認：

1. **Bundle IDが正しいか**: Xcodeで各ビルド設定が正しいBundle Identifierを使用していることを確認
2. **Firebase設定が適切に切り替わるか**: 異なるFlavorでビルドして正しいFirebase設定がコピーされることを確認
3. **アプリ名が正しく表示されるか**: 開発版と本番版の両方をインストールして、異なる表示名になることを確認
4. **スキームが正常に動作するか**: 「Runner Dev」と「Runner Prod」の両方のスキームでビルドテストを実施

## 異なる環境でのビルド

### 開発環境ビルド
```bash
flutter build ios --flavor "Runner Dev" --dart-define=ENVIRONMENT=dev --target lib/main_dev.dart
```

### 本番環境ビルド
```bash
flutter build ios --flavor "Runner Prod" --dart-define=ENVIRONMENT=prod --target lib/main_prod.dart
```

### App Store用アーカイブ（本番環境）
1. Xcodeを開く
2. 「Runner Prod」スキームを選択
3. Product → Archive
4. 本番環境のBundle IDとFirebase設定が自動的に使用される

## トラブルシューティング

### よくある問題

1. **Firebase設定が見つからない**: Firebaseディレクトリ構造が存在し、ファイルが正しい場所にあることを確認
2. **間違ったBundle ID**: Xcodeでビルド設定が正しく設定されていることを確認
3. **スキームが見つからない**: Xcodeでスキームが「Shared」としてマークされていることを確認
4. **スクリプト実行権限エラー**: 必要に応じてシェルスクリプトに`chmod +x`を実行

### 確認コマンド

現在のBundle IDを確認：
```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist
```

Firebase設定が正しいかを確認：
```bash
/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist
```

