import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/entities/gym.dart';
import '../providers/gym_provider.dart';
import '../components/common/loading_widget.dart';
import '../components/common/error_widget.dart';
import '../components/common/gym_category.dart';
import '../../shared/utils/gym_hours_utils.dart';
import '../../shared/utils/navigation_helper.dart';
import '../../shared/utils/prefecture_order_utils.dart';

/// ジム地図ページ
///
/// 役割:
/// - 地図上でのジム位置表示（将来実装）
/// - 現在地周辺のジム検索
/// - ジムカードの横スクロール表示
/// - マップピンからジム詳細への遷移（将来実装）
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のPage
/// - ViewModel（Provider）からデータを取得
/// - 単一責任：地図とジムリストの表示に特化
class GymMapPage extends ConsumerStatefulWidget {
  const GymMapPage({super.key});

  @override
  ConsumerState<GymMapPage> createState() => _GymMapPageState();
}

class _GymMapPageState extends ConsumerState<GymMapPage> {
  final ScrollController _scrollController = ScrollController();
  int _focusedGymIndex = -1;

  // Google Maps関連
  Set<Marker> _markers = {};
  final LatLng _center = const LatLng(35.681236, 139.767125); // 東京駅
  GoogleMapController? _mapController;
  BitmapDescriptor? _customGymMarker;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gymListProvider.notifier).loadAllGyms();
    });
  }

  /// マップの初期化（カスタムマーカー設定）
  Future<void> _initializeMap() async {
    try {
      // カスタムマーカーアイコンの設定（アセットがない場合はデフォルト使用）
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/gym_pin.png', // アセットパス（存在しない場合はデフォルトマーカー）
      ).catchError((_) =>
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed));

      _customGymMarker = icon;
    } catch (e) {
      _customGymMarker =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gymListState = ref.watch(gymListProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // TODO：現在位置取得機能の実装は不要の可能性あり，API実装後必要か否か確認
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.my_location, color: Colors.black),
        //     onPressed: _handleCurrentLocation,
        //   ),
        // ],
      ),
      body: gymListState.when(
        data: (gyms) => _buildMapView(gyms),
        loading: () => const Center(
          child: LoadingWidget(message: 'ジム情報を読み込み中...'),
        ),
        error: (error, stackTrace) => Center(
          child: AppErrorWidget(
            message: 'ジム情報の取得に失敗しました',
            onRetry: () => ref.read(gymListProvider.notifier).loadAllGyms(),
          ),
        ),
      ),
    );
  }

  Widget _buildMapView(List<Gym> gyms) {
    // 地理的順序（北から南）でジムをソート
    final sortedGyms = PrefectureOrderUtils.sortGymsByGeographicOrder(gyms);

    return Stack(
      children: [
        // Google Map（ソート済みリストを使用してマーカーとカードの整合性を保つ）
        _buildGoogleMap(sortedGyms),

        // ジムカード横スクロール（下部）- ソート済みリストを使用
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildGymCardList(sortedGyms),
        ),
      ],
    );
  }

  /// Google Mapを表示
  Widget _buildGoogleMap(List<Gym> gyms) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) async {
        _mapController = controller;

        // マップスタイルを適用（オプション）
        try {
          final style = await rootBundle.loadString('assets/map_style.json');
          _mapController?.setMapStyle(style);
        } catch (e) {
          // マップスタイルファイルがない場合は無視
        }

        // 現在地に移動
        final currentLocation = await _getCurrentLocation();
        if (currentLocation != null) {
          await _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(currentLocation, 12.0),
          );
        } else {
          await _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_center, 11.0),
          );
        }

        // マーカー更新
        await _updateMarkers(gyms);
      },
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 11.0,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      padding: const EdgeInsets.only(bottom: 280), // ジムカード分の余白
    );
  }

  /// 現在位置を取得
  Future<LatLng?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return null;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      // 位置情報取得エラー
      return null;
    }
  }

  /// ジム情報を基にマーカーを更新
  Future<void> _updateMarkers(List<Gym> gyms) async {
    if (_customGymMarker == null) return;

    final markers = gyms.asMap().entries.where((entry) {
      final gym = entry.value;
      return gym.latitude != null &&
          gym.longitude != null &&
          gym.latitude != 0.0 &&
          gym.longitude != 0.0;
    }).map((entry) {
      final gym = entry.value;
      final index = entry.key;

      return Marker(
        markerId: MarkerId(gym.id.toString()),
        position: LatLng(gym.latitude!, gym.longitude!),
        icon: _customGymMarker!,
        onTap: () async {
          // マーカータップ時の処理
          setState(() {
            _focusedGymIndex = index;
          });
          _scrollToCard(index);

          // カメラを該当ジムに移動
          await Future.delayed(const Duration(milliseconds: 150));
          await _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(gym.latitude!, gym.longitude!),
            ),
          );
        },
        infoWindow: InfoWindow(
          title: gym.name,
          snippet: '${gym.prefecture} ${gym.city}',
        ),
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });
  }

  Widget _buildGymCardList(List<Gym> gyms) {
    return Container(
      height: 280,
      color: Colors.white,
      child: Column(
        children: [
          // ハンドルバー
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '近くのジム (${gyms.length}件)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // TODO: 全件表示機能の実装は不要の可能性あり
                // TextButton(
                //   onPressed: () {
                //     // TODO: 全件表示ページへの遷移
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(content: Text('全件表示機能は実装予定です')),
                //     );
                //   },
                //   child: const Text('すべて見る'),
                // ),
              ],
            ),
          ),

          // ジムカード横スクロール
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: gyms.length,
              itemBuilder: (context, index) {
                final gym = gyms[index];
                final isOpen = GymHoursUtils.isCurrentlyOpen(gym.hours);

                return Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _focusedGymIndex == index
                        ? Colors.blue[50]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: _focusedGymIndex == index
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ジム名と都道府県
                        GestureDetector(
                          onTap: () async {
                            // ジム詳細ページへ遷移
                            await NavigationHelper.toGymDetail(context, gym.id);
                          },
                          child: Container(
                            height: 44,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${gym.name} [${gym.prefecture}]',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ジムカテゴリ
                        Row(
                          children: [
                            if (gym.isBoulderingGym)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: GymCategory(
                                  category: 'ボルダリング',
                                  colorCode: 0xFFFF0F00,
                                ),
                              ),
                            if (gym.isLeadGym)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: GymCategory(
                                  category: 'リード',
                                  colorCode: 0xFF00A24C,
                                ),
                              ),
                            if (gym.isSpeedGym)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: GymCategory(
                                  category: 'スピード',
                                  colorCode: 0xFF0057FF,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // プレースホルダー画像
                        Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('写真なし',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 料金と営業状態
                        Row(
                          children: [
                            const Icon(Icons.currency_yen, size: 18),
                            Text(
                              '${gym.minimumFee}〜',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 18),
                            Text(
                              isOpen ? 'OPEN' : 'CLOSE',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOpen ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // TODO：現在位置取得機能の実装は不要の可能性あり，API実装後必要か否か確認
  // void _handleCurrentLocation() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('位置情報取得機能は実装予定です')),
  //   );
  // }

  /// 特定のカードまでスクロール（将来の地図ピン連携用）
  void _scrollToCard(int index) {
    if (!_scrollController.hasClients) return;

    final width = MediaQuery.of(context).size.width * 0.8 + 16;
    _scrollController.animateTo(
      width * index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    setState(() {
      _focusedGymIndex = index;
    });
  }
}
