# iPhone実機ビルド手順書（開発版）

## 📱 概要

開発版アプリをiPhoneにビルドして、MacBookと切り離しても動作させる方法を説明します。これには **Development Certificate** と **Development Provisioning Profile** が必要です。

## 🎯 前提条件

- Apple Developer Program に登録済み
- 開発版のエイリアスが設定済み
- 開発版バックエンドが稼働中

### 開発版ビルドコマンド（エイリアス）
```bash
alias fdev='flutter run --flavor "Runner Dev" --dart-define=ENVIRONMENT=dev --target lib/main_dev.dart'
alias fbdev='flutter build ios --flavor "Runner Dev" --dart-define=ENVIRONMENT=dev --target lib/main_dev.dart'
```

---

## Phase 1: Apple Developer設定

### ✅ 1.1 Apple Developer Account確認
- [ ] Apple Developer Program に登録済みであることを確認
- [ ] Apple Developer Portal (https://developer.apple.com) にログイン

### ✅ 1.2 デバイス登録
- [ ] Apple Developer Portal > Certificates, Identifiers & Profiles > Devices
- [ ] 「+」ボタンで新しいデバイス追加
- [ ] Platform: iOS
- [ ] Device Name: 任意の名前（例: "[YOUR_NAME] iPhone" - あなたの名前を入力）
- [ ] Device ID (UDID): iPhoneのUDIDを取得

**UDIDの取得方法:**
```bash
# iPhoneをMacに接続後
system_profiler SPUSBDataType | grep "Serial Number:" | head -1
```
または
- iTunesでデバイス情報を確認
- iPhone設定 > 一般 > 情報 でUDIDをコピー

---

## Phase 2: 証明書・プロビジョニング設定

### ✅ 2.1 Development Certificate作成
- [ ] Apple Developer Portal > Certificates, Identifiers & Profiles > Certificates
- [ ] 「+」ボタンで新規証明書作成
- [ ] **iOS App Development** を選択
- [ ] Certificate Signing Request (CSR) をアップロード

**CSR作成方法:**
```bash
# キーチェーンアクセス.app を開く
# キーチェーンアクセス > 証明書アシスタント > 認証局に証明書を要求
# ユーザーのメールアドレス: 開発者のメールアドレス
# 通称: 開発者名
# CAのメールアドレス: 空白
# 要求の処理：ディスクに保存
```

### ✅ 2.2 App ID確認・作成

**Step 1: 既存のApp IDを確認**
- [ ] Apple Developer Portal > Identifiers をクリック
- [ ] リストから `com.yourcompany.yourapp.dev` を探す
- [ ] 存在する場合はStep 3へスキップ

**Step 2: 新規App ID作成（存在しない場合）**
- [ ] 「+」ボタンをクリックして新規作成
- [ ] 「App IDs」を選択して「Continue」
- [ ] 「App」を選択して「Continue」
- [ ] 以下を入力:
  - **Description**: `Bouldering App Dev`（管理用の名前）
  - **Bundle ID**: 「Explicit」を選択
  - **Bundle ID入力欄**: `com.yourcompany.yourapp.dev` を正確に入力
- [ ] Capabilitiesセクション:
  - **Maps**: ✅ チェック（Google Maps使用のため）
  - その他は不要（Push Notifications等は使用していない）
- [ ] 「Continue」をクリック
- [ ] 内容を確認して「Register」をクリック

**Step 3: 作成完了確認**
- [ ] Identifiersリストに `com.yourcompany.yourapp.dev` が表示されることを確認

### ✅ 2.3 Development Provisioning Profile作成
- [ ] Apple Developer Portal > Profiles
- [ ] 「+」ボタンで新規プロファイル作成
- [ ] **iOS App Development** を選択
- [ ] App ID: `com.yourcompany.yourapp.dev` を選択
- [ ] Certificates: 作成したDevelopment Certificateを選択
- [ ] Devices: 登録したiPhoneを選択
- [ ] Profile Name: "Bouldering App Dev Profile"

---

## Phase 3: Xcode設定

### ✅ 3.1 証明書の確認
- [ ] Development Certificate（.cer）がダブルクリック済みか確認
- [ ] Development Provisioning Profile（.mobileprovision）がダブルクリック済みか確認
- [ ] キーチェーンアクセスで「Apple Development: あなたの名前」が表示されているか確認

### ✅ 3.2 プロジェクトを開く
```bash
# プロジェクトを開く
open ios/Runner.xcworkspace
```

### ✅ 3.3 Signing & Capabilities設定

**基本手順**:
- [ ] Xcodeでプロジェクトを選択 > Runner > Signing & Capabilities

**各Configuration別の設定方法**:

#### **1. Debug-Runner Dev（開発デバッグ用）**
- [ ] 上部で「Debug-Runner Dev」を選択
- [ ] **Automatically manage signing**: ✅ チェックを入れる
- [ ] **Team**: あなたのApple Developer Team を選択
- [ ] **Bundle Identifier**: `com.yourcompany.yourapp.dev` が自動設定されることを確認
- [ ] **Signing Certificate**: Apple Development（自動）
- [ ] **Status**: エラーなし

#### **2. Debug-Runner Prod（本番デバッグ用）**
- [ ] 上部で「Debug-Runner Prod」を選択
- [ ] **Automatically manage signing**: ✅ チェックを入れる
- [ ] **Team**: あなたのApple Developer Team を選択
- [ ] **Bundle Identifier**: `com.yourcompany.yourapp` が自動設定されることを確認
- [ ] **Signing Certificate**: Apple Development（自動）
- [ ] **Status**: エラーなし

#### **3. Release-Runner Dev（開発リリース用）**
- [ ] 上部で「Release-Runner Dev」を選択
- [ ] **Automatically manage signing**: ✅ チェックを入れる
- [ ] **Team**: あなたのApple Developer Team を選択
- [ ] **Bundle Identifier**: `com.yourcompany.yourapp.dev` が自動設定されることを確認
- [ ] **Build Settings**で**Code Signing Identity**を**Apple Development**に設定
- [ ] **Status**: エラーなし

#### **4. Release-Runner Prod（App Store提出用）⚠️最重要**
- [ ] 上部で「Release-Runner Prod」を選択
- [ ] **Automatically manage signing**: ❌ **チェックを外す（手動署名）**
- [ ] **Team**: あなたのApple Developer Team を選択
- [ ] **Bundle Identifier**: `com.yourcompany.yourapp` を確認
- [ ] **Provisioning Profile**: 「Bouldering App Distribution v2」を手動選択
- [ ] **Signing Certificate**: Apple Distribution（自動設定される）
- [ ] **Status**: エラーなし

#### **5. Profile-Runner Dev（開発パフォーマンス測定用）**
- [ ] 上部で「Profile-Runner Dev」を選択
- [ ] **Automatically manage signing**: ✅ チェックを入れる
- [ ] **Team**: あなたのApple Developer Team を選択
- [ ] **Bundle Identifier**: `com.yourcompany.yourapp.dev` が自動設定されることを確認
- [ ] **Signing Certificate**: Apple Development（自動）
- [ ] **Status**: エラーなし

#### **6. Profile-Runner Prod（本番パフォーマンス測定用）**
- [ ] 上部で「Profile-Runner Prod」を選択
- [ ] **Automatically manage signing**: ✅ チェックを入れる
- [ ] **Team**: あなたのApple Developer Team を選択
- [ ] **Bundle Identifier**: `com.yourcompany.yourapp` が自動設定されることを確認
- [ ] **Signing Certificate**: Apple Development（自動）
- [ ] **Status**: エラーなし

> **⚠️ 注意事項**:
> - **Release-Runner Prod**のみ手動署名（Apple Distribution証明書使用）
> - 他の5つは自動署名でOK
> - すべての設定で**Status**にエラーがないことを確認

---

## Phase 4: iPhone側設定（初回のみ）

### ✅ 4.1 iPhoneをMacに接続
- [ ] Lightning/USB-CケーブルでiPhoneをMacに接続
- [ ] iPhone側で「このコンピュータを信頼しますか？」で「信頼」をタップ

### ✅ 4.2 開発者信頼設定
初回インストール後に必要:
- [ ] iPhone設定 > 一般 > VPNとデバイス管理
- [ ] 「デベロッパApp」セクションで開発者アカウントを選択
- [ ] 「[開発者名]を信頼」をタップ
- [ ] 確認ダイアログで「信頼」をタップ

---

## Phase 5: 実機ビルド実行

### ✅ 5.1 デバイス確認
```bash
# 接続されているデバイスを確認
flutter devices
```

### ✅ 5.2 実機へ直接インストール（コマンドで完結）

**方法1: 既存のfdevコマンドを使用（最も簡単）**
```bash
# fdevコマンドで接続デバイスを選択
fdev
# 表示されるデバイス一覧から実機（例: [YOUR_INITIALS]-iPhone）を選択
```

**方法2: デバイスIDを直接指定**
```bash
# デバイスIDを指定して実行（例: iPhone実機のID）
flutter run -d [device-id] --flavor "Runner Dev" --dart-define=ENVIRONMENT=dev --target lib/main_dev.dart
```

**方法3: 実機用エイリアスを作成（オプション）**
`.zshrc`に追加:
```bash
# 実機用開発ビルド（接続された最初のiPhoneで自動実行）
alias fdev-device='flutter run -d $(flutter devices | grep iPhone | head -1 | awk "{print \$3}") --flavor "Runner Dev" --dart-define=ENVIRONMENT=dev --target lib/main_dev.dart'
```

### ✅ 5.3 アプリ動作確認
- [ ] ホーム画面にアプリアイコンが表示されることを確認
- [ ] アプリをタップして起動
- [ ] 開発版APIエンドポイントに接続されることを確認
- [ ] 主要機能が動作することを確認

---

## Phase 6: リリースモードで実機インストール（オプション）

ケーブルを抜いてもアプリを高速動作させたい場合：

### ✅ 6.1 リリースモードでインストール（コマンド1つで完結）

**開発版をリリースモードで(実行と同時に)インストール**:
```bash
flutter run --release --flavor "Runner Dev" --dart-define=ENVIRONMENT=dev --target lib/main_dev.dart
```

**エイリアスを作成（.zshrcに追加）**:
```bash
# 開発版リリースモードインストール
alias fdev-release='flutter run --release --flavor "Runner Dev" --dart-define=ENVIRONMENT=dev --target lib/main_dev.dart'
```

### ✅ 6.2 動作確認
- [ ] アプリが高速で動作することを確認（デバッグ情報なし）
- [ ] MacBookからケーブルを抜いても動作継続
- [ ] ホットリロード不可（リリースモードのため）

---

## 🎯 重要なポイント

### 有効期限について
- **Development Certificate**: 1年間有効
- **Provisioning Profile**: 1年間有効
- **アプリインストール**: 証明書有効期限まで動作（通常1年）

### トラブルシューティング

#### ビルドエラー
```bash
# 証明書エラーの場合
flutter clean
cd ios
pod install
cd ..
```

#### 署名エラー
- Apple Developer Portalで証明書・プロファイルを再確認
- Xcodeで「Automatically manage signing」のオン・オフを切り替え

#### デバイス認識しない
```bash
# デバイス確認
flutter devices
```
- iOSが最新でない場合はアップデート
- Xcodeが最新でない場合はアップデート

### 更新手順
証明書期限切れ時:
1. 新しいDevelopment Certificateを作成
2. 新しいProvisioning Profileを作成
3. 再ビルド・再インストール

---

## ✅ 最終チェックリスト

開発版実機ビルドの最終確認:

### Apple Developer設定
- [ ] デバイスがApple Developer Portalに登録済み
- [ ] Development Certificateが有効
- [ ] Provisioning Profileが作成済み
- [ ] App ID `com.yourcompany.yourapp.dev` が設定済み

### Xcode設定
- [ ] 署名設定が正しく構成済み
- [ ] 証明書がKeychainにインストール済み
- [ ] Provisioning Profileがインストール済み

### iPhone設定
- [ ] 開発者が信頼済み
- [ ] アプリが正常に起動
- [ ] MacBook切断後も動作継続

**これで開発版アプリがiPhoneに永続的にインストールされ、MacBookと切り離しても動作するようになります！**
