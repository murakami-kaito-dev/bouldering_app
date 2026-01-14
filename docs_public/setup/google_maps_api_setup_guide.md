# Google Maps API 実装ガイド（iOS版）

## 概要
FlutterアプリのiOS版にGoogle Mapsを統合し、ジムの位置を地図上に表示する機能を実装するためのガイドです。
**開発環境と本番環境の両方の設定手順を含みます。**

## 必要な機能
- 地図表示（iOS版）
- カスタムマーカー（ピン）の表示
- 現在地の取得と表示
- マーカータップ時の連動処理

## 実装日
2025-08-21

---

## 📋 Part 1: Google Cloud Console 設定

### 1. Google Cloud プロジェクトの準備

#### 1.1 プロジェクトの選択

**🔄 環境別の設定：**

##### 開発環境の場合：
[Google Cloud Console](https://console.cloud.google.com) にアクセスして：
1. 画面上部のプロジェクト選択ボタンをクリック
2. `[YOUR_GCP_PROJECT_ID_DEV]` を選択
3. 現在のプロジェクトが `[YOUR_GCP_PROJECT_ID_DEV]` になっていることを確認

##### 本番環境の場合：
1. 画面上部のプロジェクト選択ボタンをクリック
2. `[YOUR_GCP_PROJECT_ID_PROD]` を選択（本番プロジェクト名に合わせて調整）
3. 現在のプロジェクトが本番プロジェクトになっていることを確認

#### 1.2 Maps SDK for iOS の有効化

**🟢 共通手順（開発・本番共通）：**

[Google Cloud Console](https://console.cloud.google.com) で：

1. **左側メニュー**から「APIとサービス」→「ライブラリ」をクリック
2. **検索バー**に「Maps SDK for iOS」と入力
3. **「Maps SDK for iOS」**を選択（Androidではない！）
4. **「有効にする」**ボタンをクリック

※ 開発環境と本番環境の両方のプロジェクトで実施する必要があります

### 2. APIキーの作成と制限

#### 2.1 APIキーの作成

**🟢 共通手順（開発・本番共通）：**

1. **左側メニュー**から「APIとサービス」→「認証情報」をクリック
2. **「+ 認証情報を作成」**ボタンをクリック
3. **「APIキー」**を選択
4. APIキーが作成されたら、**鉛筆アイコン（編集）**をクリック

#### 2.2 APIキーの設定と制限

**🔄 環境別の設定：**

##### 開発環境の場合：

**表示名の設定：**
- **名前**: `iOS Maps API Key - Dev`

**アプリケーションの制限：**
1. **「iOSアプリ」**を選択
2. **「項目を追加」**をクリック
3. **バンドルID**を入力：
   ```
   com.yourcompany.yourapp.dev
   ```
4. **「完了」**をクリック

##### 本番環境の場合：

**表示名の設定：**
- **名前**: `iOS Maps API Key - Prod`

**アプリケーションの制限：**
1. **「iOSアプリ」**を選択
2. **「項目を追加」**をクリック
3. **バンドルID**を入力：
   ```
   com.yourcompany.yourapp
   ```
4. **「完了」**をクリック

**🟢 共通手順（開発・本番共通）：**

**APIの制限：**
1. **「キーを制限」**を選択
2. **「Maps SDK for iOS」**にチェックを入れる（他は選択しない）
3. **「保存」**ボタンをクリック

#### 2.3 APIキーの保存

**🔄 環境別の管理：**
- **開発環境用APIキー**: 開発チーム内で共有
- **本番環境用APIキー**: セキュアに管理（限定されたメンバーのみアクセス可能）

両方のAPIキーを安全な場所に保存してください。

### 3. 料金設定の確認
- Google Maps APIには無料枠があります（月額$200分のクレジット）
- [料金計算ツール](https://mapsplatformtransition.withgoogle.com/calculator)で使用量を見積もり
- 請求先アカウントの設定が必要（クレジットカード登録）

---

## 🔧 Part 2: Flutter プロジェクト設定（iOS版）

### 1. 依存関係の確認

**🟢 共通手順（開発・本番共通）：**

```yaml
# pubspec.yaml - 既に設定済みを確認
dependencies:
  google_maps_flutter: ^2.10.1
  geolocator: ^11.0.0

dependency_overrides:
  geolocator_android: 4.5.5
```

### 2. iOS設定

#### 2.1 APIキーの設定

**🔄 環境別の設定：**

APIキーは環境によって異なるため、環境変数や設定ファイルで管理することを推奨します。

##### 方法1: 直接記述（簡易版）

```swift
// ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import GoogleMaps  // 追加

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Flavor判定による環境別APIキー設定
    #if DEBUG
      // 開発環境用APIキー
      GMSServices.provideAPIKey("YOUR_DEV_IOS_API_KEY_HERE")
    #else
      // 本番環境用APIキー
      GMSServices.provideAPIKey("YOUR_PROD_IOS_API_KEY_HERE")
    #endif

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

##### 方法2: Config.plist別設定（推奨・実装済み）

**1. Config.plistファイルを作成:**
```xml
<!-- ios/Runner/Config.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!--
APIキー管理ファイル
- このファイルはGit管理対象外（.gitignoreに登録済み）
- 新メンバーには安全な方法で共有
- Bundle IDに応じてAppDelegate.swiftが自動選択
-->
<plist version="1.0">
<dict>
	<!-- 開発環境用 (Bundle ID: com.yourcompany.yourapp.dev) -->
	<key>GOOGLE_MAPS_IOS_DEV_API_KEY</key>
	<string>[YOUR_DEV_API_KEY]</string> <!-- ← Google Cloud Consoleで生成した開発環境用APIキーを入力 -->

	<!-- 本番環境用 (Bundle ID: com.yourcompany.yourapp) -->
	<key>GOOGLE_MAPS_IOS_PROD_API_KEY</key>
	<string>[YOUR_PROD_API_KEY]</string> <!-- ← Google Cloud Consoleで生成した本番環境用APIキーを入力 -->
</dict>
</plist>
```

**2. AppDelegate.swiftでConfig.plistから読み込み:**
```swift
// ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Config.plistからAPIキーを読み込み
    guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
          let config = NSDictionary(contentsOfFile: configPath) else {
      fatalError("Config.plist not found or invalid")
    }

    // Build Configurationに基づいたAPIキー取得
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    var apiKey = ""

    if bundleId.contains(".dev") {
      // 開発環境用APIキー
      apiKey = config["GOOGLE_MAPS_IOS_DEV_API_KEY"] as? String ?? ""
    } else {
      // 本番環境用APIキー
      apiKey = config["GOOGLE_MAPS_IOS_PROD_API_KEY"] as? String ?? ""
    }

    if apiKey.isEmpty {
      fatalError("Google Maps API key not found in Config.plist")
    }

    GMSServices.provideAPIKey(apiKey)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**3. .gitignoreの設定（既に設定済み）:**
```
# API Keys（秘匿情報のため）
ios/Runner/Config.plist
```

**✅ メリット：**
- APIキーがソースコードに含まれない
- Git管理から完全に除外
- 一元管理で保守性が高い

#### 2.2 Info.plist設定（位置情報権限）

**🟢 共通手順（開発・本番共通）：**

```xml
<!-- ios/Runner/Info.plist -->
<!-- Google Maps用の位置情報権限設定 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>ジムの位置情報を地図上に表示するため、現在地を使用します</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>ジムの位置情報を地図上に表示するため、現在地を使用します</string>
```

**説明：**
- 位置情報を取得する際に、ユーザーに表示される許可ダイアログの説明文を設定
- この設定がないと、位置情報の取得でアプリがクラッシュする可能性があります

**注意：** NSAppTransportSecurityの設定は不要です。すべてのAPI通信（Cloud Run、Google Maps、Firebase、GCS）がHTTPS通信のため。

#### 2.3 Podfile確認と更新

**🟢 共通手順（開発・本番共通）：**

```ruby
# ios/Podfile - 既存設定の確認
platform :ios, '13.0'  # 13.0以上であることを確認

# 必要に応じて追加（パフォーマンス最適化）
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

Podfile更新後：
```bash
cd ios
pod install
```

---

## 💻 Part 3: Flutter 実装

**🟢 共通実装（開発・本番共通）：**

以下のFlutterコードは開発環境・本番環境の両方で共通で使用できます。APIキーの切り替えはiOS側の設定で行われるため、Flutterコード側での環境別処理は不要です。

### 1. 地図ページの実装

```dart
// lib/presentation/pages/gym_map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GymMapPage extends ConsumerStatefulWidget {
  const GymMapPage({super.key});

  @override
  ConsumerState<GymMapPage> createState() => _GymMapPageState();
}

class _GymMapPageState extends ConsumerState<GymMapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  BitmapDescriptor? _customMarker;

  // 東京駅をデフォルト中心点に
  static const LatLng _defaultCenter = LatLng(35.681236, 139.767125);

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _initializeLocation();
  }

  // カスタムマーカーアイコンの読み込み
  Future<void> _loadCustomMarker() async {
    _customMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/gym_pin.png',  // カスタムピン画像
    );
  }

  // 現在地の取得と初期化
  Future<void> _initializeLocation() async {
    final currentLocation = await _getCurrentLocation();
    if (currentLocation != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 14),
      );
    }
  }

  // 現在地を取得
  Future<LatLng?> _getCurrentLocation() async {
    try {
      // 位置情報サービスが有効か確認
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // 権限確認
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // 設定画面へ誘導
        return null;
      }

      // 現在地取得
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('位置情報取得エラー: $e');
      return null;
    }
  }

  // マーカーの生成
  void _updateMarkers(List<Gym> gyms) {
    setState(() {
      _markers = gyms
          .where((gym) =>
            gym.latitude != null &&
            gym.longitude != null &&
            gym.latitude != 0 &&
            gym.longitude != 0
          )
          .map((gym) => Marker(
            markerId: MarkerId(gym.id.toString()),
            position: LatLng(gym.latitude!, gym.longitude!),
            icon: _customMarker ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: gym.name,
              snippet: gym.address,
            ),
            onTap: () {
              // マーカータップ時の処理
              _onMarkerTapped(gym);
            },
          ))
          .toSet();
    });
  }

  // マーカータップ時の処理
  void _onMarkerTapped(Gym gym) {
    // ジム詳細カードを表示したり、画面遷移したり
    showModalBottomSheet(
      context: context,
      builder: (context) => GymDetailCard(gym: gym),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gyms = ref.watch(gymProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ジムマップ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GoogleMap(
        onMapCreated: (controller) async {
          _mapController = controller;

          // カスタムスタイル適用（オプション）
          final style = await rootBundle.loadString('assets/map_style.json');
          await _mapController!.setMapStyle(style);

          // ジムマーカー更新
          _updateMarkers(gyms);
        },
        initialCameraPosition: const CameraPosition(
          target: _defaultCenter,
          zoom: 12,
        ),
        markers: _markers,
        myLocationEnabled: true,  // 現在地表示
        myLocationButtonEnabled: true,  // 現在地ボタン
        zoomControlsEnabled: false,  // ズームコントロール非表示
        mapToolbarEnabled: false,  // マップツールバー非表示
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
```

### 2. カスタムマップスタイル（オプション）

```json
// assets/map_style.json
[
  {
    "featureType": "poi.business",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  }
]
```

### 3. アセット設定

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/gym_pin.png
    - assets/map_style.json
```

---

## 🚀 Part 4: 環境変数管理（推奨）

### APIキーを環境変数で管理

```dart
// lib/shared/config/environment_config.dart
class EnvironmentConfig {
  // 既存の設定...

  /// Google Maps APIキー（Android）
  static String get googleMapsAndroidApiKey {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'YOUR_DEV_ANDROID_API_KEY';
      case Environment.production:
        return 'YOUR_PROD_ANDROID_API_KEY';
    }
  }

  /// Google Maps APIキー（iOS）
  static String get googleMapsIosApiKey {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'YOUR_DEV_IOS_API_KEY';
      case Environment.production:
        return 'YOUR_PROD_IOS_API_KEY';
    }
  }
}
```

---

## ✅ Part 5: テストとトラブルシューティング

### 1. 動作確認チェックリスト

- [ ] Google Cloud ConsoleでAPIが有効化されている
- [ ] APIキーが正しく設定されている
- [ ] APIキーに適切な制限が設定されている
- [ ] AndroidManifest.xmlにAPIキーが記載されている
- [ ] AppDelegate.swiftにAPIキーが記載されている
- [ ] 位置情報の権限設定が完了している
- [ ] 地図が表示される
- [ ] マーカーが表示される
- [ ] 現在地が取得できる

### 2. よくあるエラーと対処法

#### エラー: 地図が表示されない（グレーの画面）
**原因**: APIキーが正しくないか、APIが有効化されていない
**対処**:
- Google Cloud ConsoleでAPIの有効化を確認
- APIキーが正しくコピーされているか確認
- APIキーの制限設定を確認

#### エラー: 位置情報が取得できない
**原因**: 権限設定が不適切
**対処**:
- AndroidManifest.xmlの権限設定を確認
- Info.plistの権限説明文を確認
- デバイスの位置情報設定を確認

#### エラー: マーカーが表示されない
**原因**: カスタムアイコンの読み込みエラー
**対処**:
- アセットファイルのパスを確認
- pubspec.yamlのassets設定を確認

### 3. デバッグ用ログ

```dart
// デバッグ情報の出力
debugPrint('Map Controller: $_mapController');
debugPrint('Markers count: ${_markers.length}');
debugPrint('Current location: $currentLocation');
```

---

## 📚 参考資料

- [Google Maps Flutter Plugin公式ドキュメント](https://pub.dev/packages/google_maps_flutter)
- [Geolocator Plugin公式ドキュメント](https://pub.dev/packages/geolocator)
- [Google Cloud Maps Platform](https://cloud.google.com/maps-platform)
- [Maps SDK for Android](https://developers.google.com/maps/documentation/android-sdk)
- [Maps SDK for iOS](https://developers.google.com/maps/documentation/ios-sdk)

---

## 🎯 実装優先順位

1. **Phase 1**: 基本実装（必須）
   - Google Cloud設定
   - APIキー取得と設定
   - 基本的な地図表示

2. **Phase 2**: 機能追加
   - ジムマーカー表示
   - 現在地取得
   - マーカータップ処理

3. **Phase 3**: UX改善（オプション）
   - カスタムマーカーアイコン
   - カスタムマップスタイル
   - アニメーション追加

---

## 注意事項

1. **セキュリティ**
   - APIキーは必ず制限をかける
   - 本番環境のAPIキーはコミットしない
   - 環境変数やSecret Managerで管理

2. **料金**
   - 無料枠を超えないよう使用量を監視
   - 不要なAPI呼び出しを避ける
   - キャッシュを活用

3. **パフォーマンス**
   - マーカーが多い場合はクラスタリングを検討
   - 不要な再描画を避ける
   - メモリリークに注意（dispose処理）

---

実装完了後は、`docs/implementation/gym_map_page_refactoring.md`のプレースホルダー部分を実際のGoogle Maps実装に置き換えてください。

---

## 📱 付録: Android版追加実装（将来対応）

iOS版が完成したら、以下の手順でAndroid版も追加できます。

### A1. Google Cloud Console 追加設定

#### A1.1 Maps SDK for Android の有効化
1. [Google Cloud Console](https://console.cloud.google.com) で `[YOUR_GCP_PROJECT_ID_DEV]` を選択
2. 「APIとサービス」→「ライブラリ」から「**Maps SDK for Android**」を検索
3. 「有効にする」をクリック

#### A1.2 Android用APIキーの作成
1. 「APIとサービス」→「認証情報」→「+ 認証情報を作成」→「APIキー」
2. 名前を「**Android Maps API Key - Dev**」に設定
3. アプリケーションの制限：「**Androidアプリ**」を選択
4. パッケージ名：`com.example.bouldering_app.dev`
5. SHA-1フィンガープリント：
   ```bash
   # デバッグ用SHA-1取得
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
6. APIの制限：「**Maps SDK for Android**」のみ選択

### A2. Android設定

#### A2.1 APIキー設定
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <application>
        <!-- 既存の設定... -->

        <!-- Google Maps APIキー追加 -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_ANDROID_DEV_API_KEY_HERE"/>
    </application>
</manifest>
```

#### A2.2 権限設定
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### A2.3 最小SDKバージョン確認
```gradle
// android/app/build.gradle
android {
    defaultConfig {
        minSdkVersion 21  // 21以上である必要があります
    }
}
```
