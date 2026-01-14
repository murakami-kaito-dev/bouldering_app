# ジム地図ページ リファクタリング実装ドキュメント

## 概要

ジム地図ページ（`gym_map_page.dart`）を過去プロジェクトの`search_gym_on_map_page.dart`を参考に、MVVM・クリーンアーキテクチャの原則に従って再実装。

## アーキテクチャ設計

### クリーンアーキテクチャ + MVVM準拠

```
Presentation層 (gym_map_page.dart)
    ↓
Provider層 (gym_provider.dart)
    ↓
Domain層 (gym_entity.dart)
    ↓
Infrastructure層 (gym_repository_impl.dart)
    ↓
External (Google Maps API, Backend API)
```

### 単一責任原則
- **GymMapPage**: 地図とジムリストの表示のみ
- **WannaGoGymCard**: ジムカード表示（共通コンポーネント）
- **GymProvider**: データ取得と状態管理

## リファクタリング内容

### 1. レイアウト構造の改善

#### Before（縦分割レイアウト）
```
Column
├── 地図エリア（高さ2/3）
└── リストエリア（高さ1/3）
    └── 縦スクロールリスト
        └── 独自のカードコンポーネント
```

#### After（Stack構造）
```
Stack
├── 地図プレースホルダー（全画面）
└── Positioned（下部）
    └── Container（高さ280px）
        ├── ハンドルバー
        ├── ヘッダー（件数・すべて見る）
        └── 横スクロールリスト
            └── WannaGoGymCard × n
```

### 2. 実装コード

#### AppBarの透過設定
```dart
Scaffold(
  extendBodyBehindAppBar: true,
  appBar: AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      '地図でジムを探す',
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.my_location, color: Colors.black),
        onPressed: _goToCurrentLocation,
      ),
    ],
  ),
)
```

#### 横スクロールリストの実装
```dart
Container(
  height: 280,
  decoration: const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 10,
        offset: Offset(0, -2),
      ),
    ],
  ),
  child: Column(
    children: [
      // ハンドルバー
      Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      
      // ヘッダー
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '近くのジム ${gyms.length}件',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/gym-search'),
              child: const Text('すべて見る'),
            ),
          ],
        ),
      ),
      
      // 横スクロールリスト
      Expanded(
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: gyms.length,
          itemBuilder: (context, index) {
            final gym = gyms[index];
            return Container(
              width: MediaQuery.of(context).size.width * 0.8,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: WannaGoGymCard(gym: gym),
            );
          },
        ),
      ),
    ],
  ),
)
```

### 3. 地図連携準備

#### スクロール連携メソッド
```dart
void _scrollToCard(int index) {
  // 地図のピンタップ時にカードを自動スクロール
  final width = MediaQuery.of(context).size.width * 0.8 + 16;
  _scrollController.animateTo(
    width * index,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
}
```

#### 現在地機能（プレースホルダー）
```dart
void _goToCurrentLocation() {
  // 現在地取得機能の実装予定
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('現在地機能は実装予定です'),
      duration: Duration(seconds: 2),
    ),
  );
}
```

### 4. 地図プレースホルダー実装

```dart
Widget _buildMapPlaceholder() {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: Colors.grey[200],
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.map,
          size: 80,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          '地図を読み込み中...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Google Maps API統合予定',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    ),
  );
}
```

## 冗長な部分の削除

### 削除した機能
1. **営業時間の詳細計算ロジック** → Gymエンティティに移動
2. **カスタムマーカー処理** → 将来実装として削除  
3. **重複するカードウィジェット** → WannaGoGymCardに統一

### 簡潔化の成果
- **140行の複雑なカード実装** → WannaGoGymCardの1行呼び出し
- **営業時間の複雑な判定** → `gym.isCurrentlyOpen`プロパティ使用
- **重複するスタイル定義** → 統一されたテーマ使用

## 将来のGoogle Maps API統合

### 1. 地図ウィジェット置き換え
```dart
// _buildMapPlaceholder()を以下に置き換え
GoogleMap(
  onMapCreated: (GoogleMapController controller) {
    mapController = controller;
    _updateMarkers(gyms);
  },
  initialCameraPosition: const CameraPosition(
    target: LatLng(35.6762, 139.6503), // 東京駅
    zoom: 12,
  ),
  markers: _markers,
  myLocationEnabled: true,
  myLocationButtonEnabled: false, // カスタムボタンを使用
  padding: const EdgeInsets.only(bottom: 280), // カードエリア分の余白
)
```

### 2. マーカー実装
```dart
Set<Marker> _markers = {};

void _updateMarkers(List<Gym> gyms) {
  _markers = gyms.asMap().entries.map((entry) {
    final index = entry.key;
    final gym = entry.value;
    
    return Marker(
      markerId: MarkerId(gym.id.toString()),
      position: LatLng(gym.latitude, gym.longitude),
      onTap: () => _scrollToCard(index), // カードにスクロール
      infoWindow: InfoWindow(
        title: gym.name,
        snippet: gym.isCurrentlyOpen ? '営業中' : '営業時間外',
      ),
    );
  }).toSet();
  
  setState(() {});
}
```

### 3. 現在地機能実装
```dart
Future<void> _goToCurrentLocation() async {
  try {
    final position = await Geolocator.getCurrentPosition();
    final cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 15,
    );
    
    await mapController?.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('現在地の取得に失敗しました: $e')),
    );
  }
}
```

## パフォーマンス最適化

### メモリ管理
```dart
late ScrollController _scrollController;

@override
void initState() {
  super.initState();
  _scrollController = ScrollController();
}

@override
void dispose() {
  _scrollController.dispose();
  super.dispose();
}
```

### 効率的なレンダリング
- **ListView.builder**: 必要な分だけウィジェット生成
- **MediaQuery計算の最小化**: 幅計算を1回のみ実行
- **autoDispose**: 不要になったプロバイダーの自動破棄

## 依存関係

### 共通コンポーネント
- **WannaGoGymCard**: `/lib/presentation/components/gym/wanna_go_gym_card.dart`
- **GymProvider**: `/lib/presentation/providers/gym_provider.dart`
- **NavigationHelper**: `/lib/shared/utils/navigation_helper.dart`

### 将来の依存関係（Google Maps統合時）
```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  geolocator: ^9.0.2
  permission_handler: ^11.0.1
```

## テスト方法

### 現在の機能テスト
1. ホームページから「地図でジムを探す」をタップ
2. 地図プレースホルダーが表示されることを確認
3. 下部のジムカードが横スクロール可能であることを確認
4. カードタップでジム詳細ページに遷移することを確認
5. 現在地ボタンで「実装予定」メッセージが表示されることを確認

### 将来の機能テスト（Google Maps統合後）
1. 地図が正常に表示されることを確認
2. ジムのマーカーがすべて表示されることを確認
3. マーカータップでカードにスクロールすることを確認
4. 現在地ボタンで現在地に移動することを確認
5. 地図とカードリストの連携動作確認

## 学習ポイント

### 1. レイアウト設計
- **Stack vs Column**: オーバーレイ表示の効果的な使用
- **透過AppBar**: 地図表示での自然な見た目
- **横スクロール**: カード表示での操作性向上

### 2. プロジェクト参照の活用
- 過去プロジェクトからの設計パターン流用
- 実績のあるUI/UXの採用
- 既存コンポーネントの再利用

### 3. 段階的実装
- プレースホルダーでの先行実装
- 将来拡張を考慮した設計
- 外部依存の分離

---
*最終更新: 2025-09-17*  
*実装完了度: 80% (Google Maps API統合待ち)*