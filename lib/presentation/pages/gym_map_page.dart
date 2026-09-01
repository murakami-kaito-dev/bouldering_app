import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/entities/gym.dart';
import '../providers/gym_provider.dart';
import '../components/common/loading_widget.dart';
import '../components/gym/gym_photo_strip.dart';
import '../components/common/error_widget.dart';
import '../components/common/gym_category.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';
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
  const GymMapPage({
    super.key,
    this.selectionMode = false,
    this.confirmLabel = 'このジムを選ぶ',
  });

  /// 選択モード（true: ピンのカードに確定ボタンを出し、選んだジムを呼び出し元へ返す）
  final bool selectionMode;

  /// 選択モード時の確定ボタン文言
  final String confirmLabel;

  @override
  ConsumerState<GymMapPage> createState() => _GymMapPageState();
}

class _GymMapPageState extends ConsumerState<GymMapPage> {
  final ScrollController _scrollController = ScrollController();
  int _focusedGymIndex = -1;

  /// 画面遷移アニメーション完了後にtrue。
  /// Google Mapのネイティブビュー生成と430本のピン転送は重く、遷移中に走ると
  /// フレームが止まる（フリーズ感）ため、遷移が終わるまで地図を作らない
  bool _mapReady = false;
  bool _mapGateScheduled = false;

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
      // データ未取得時のみ読込（開くたびの全件再取得をやめ、キャッシュを活かす）
      ref.read(gymListProvider.notifier).loadIfNeeded();
    });
  }

  /// マップの初期化（カスタムマーカー設定）
  Future<void> _initializeMap() async {
    try {
      // カスタムマーカーアイコンの設定（アセットがない場合はデフォルト使用）
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/pin_48.png', // カスタムピン（読込失敗時はデフォルトマーカー）
      ).catchError((_) =>
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed));

      _customGymMarker = icon;
    } catch (e) {
      _customGymMarker =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mapGateScheduled) return;
    _mapGateScheduled = true;

    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (animation == null || animation.status == AnimationStatus.completed) {
      _mapReady = true;
    } else {
      void onStatus(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          animation.removeStatusListener(onStatus);
          if (mounted) setState(() => _mapReady = true);
        }
      }

      animation.addStatusListener(onStatus);
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
    final gyms = gymListState.valueOrNull ?? const <Gym>[];
    final sortedGyms = PrefectureOrderUtils.sortGymsByGeographicOrder(gyms);

    // データが後から届いたらマーカーだけ更新する。
    // 地図とカード枠は常に固定位置で表示し、読み込みでレイアウトが動かないようにする
    ref.listen<AsyncValue<List<Gym>>>(gymListProvider, (prev, next) {
      final g = next.valueOrNull;
      if (g != null && _mapController != null) {
        _updateMarkers(PrefectureOrderUtils.sortGymsByGeographicOrder(g));
      }
    });

    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final cardListHeight = _cardListHeight(safeBottom);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.chalk),
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
      body: Stack(
        // 重要: fitを指定しないとStackは「位置指定なしの子＝GoogleMap」の
        // サイズに縮む。地図プラットフォームビューの初期化中は高さが不定なため、
        // パネルごと上に詰まるレイアウト崩れが起きる。常に画面全体へ強制する
        fit: StackFit.expand,
        children: [
          // Google Map。遷移完了までは岩肌のプレースホルダ（生成の重さを
          // 遷移アニメーションと重ねない）。完了後にフェードで地図を表示
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _mapReady
                ? _buildGoogleMap(sortedGyms, cardListHeight)
                : const ColoredBox(
                    key: ValueKey('map-placeholder'),
                    color: AppColors.iwa,
                  ),
          ),

          // ジムカード横スクロール（下部・固定高でレイアウトを不動に）
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(
                gymListState, sortedGyms, cardListHeight, safeBottom),
          ),

          // 現在地ボタン（自前実装。パネル高に追従させ被りを防ぐ）
          Positioned(
            right: 16,
            bottom: cardListHeight + 16,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'gym_map_my_location',
              backgroundColor: AppColors.setsuri,
              foregroundColor: AppColors.chalk,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  /// カードパネルの高さ（選択モードは確定ボタンぶん加算・下部セーフエリア込み）
  double _cardListHeight(double safeBottom) {
    const headerAndHandle = 52.0;
    const cardArea = 250.0;
    final buttonExtra = widget.selectionMode ? 56.0 : 0.0;
    return headerAndHandle + cardArea + buttonExtra + safeBottom;
  }

  /// 下部パネル（データ状態に依らず同じ高さ＝位置が動かない。中身だけ切替）
  Widget _buildBottomPanel(
    AsyncValue<List<Gym>> state,
    List<Gym> gyms,
    double height,
    double safeBottom,
  ) {
    return Container(
      height: height,
      color: AppColors.setsuri,
      padding: EdgeInsets.only(bottom: safeBottom),
      child: gyms.isNotEmpty
          ? _buildGymCardList(gyms)
          : state.when(
              data: (_) => const Center(child: Text('ジムがありません')),
              loading: () => const Center(
                child: LoadingWidget(message: 'ジム情報を読み込み中...'),
              ),
              error: (error, stackTrace) => Center(
                child: AppErrorWidget(
                  message: 'ジム情報の取得に失敗しました',
                  onRetry: () =>
                      ref.read(gymListProvider.notifier).loadAllGyms(),
                ),
              ),
            ),
    );
  }

  /// 現在地へカメラを移動する（自前の現在地ボタンから呼ばれる）
  Future<void> _moveToCurrentLocation() async {
    final location = await _getCurrentLocation();
    if (location == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('現在地を取得できませんでした')),
        );
      }
      return;
    }
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 12.0),
    );
  }

  /// Google Mapを表示
  Widget _buildGoogleMap(List<Gym> gyms, double bottomPadding) {
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

        // 先にマーカーを設置する（現在地取得を待たない）。
        // オフライン時は現在地取得が長時間返らないことがあり、
        // 従来の「現在地→マーカー」の順ではピンが一切立たなくなっていた
        await _updateMarkers(gyms);

        // 現在地に移動（取得できなければ初期位置=東京駅のまま）
        final currentLocation = await _getCurrentLocation();
        if (currentLocation != null) {
          await _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(currentLocation, 12.0),
          );
        }
      },
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 11.0,
      ),
      markers: _markers,
      myLocationEnabled: true,
      // 標準の現在地ボタンは測位が完了しない状況（オフライン等）で反応しないことが
      // あるため、タイムアウト+フォールバック付きの自前ボタンに置き換える
      myLocationButtonEnabled: false,
      padding: EdgeInsets.only(bottom: bottomPadding), // ジムカード分の余白
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
        timeLimit: const Duration(seconds: 5), // オフライン時等に無限待ちしない
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      // 取得失敗・タイムアウト時は、最後に取得できた位置で代用する
      // （機内モード等でGPS測位が完了しなくても現在地系の機能を動かすため）
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return LatLng(last.latitude, last.longitude);
      } catch (_) {}
      return null;
    }
  }

  /// ジム情報を基にマーカーを更新
  Future<void> _updateMarkers(List<Gym> gyms) async {
    // アイコン未初期化でもピン設置を止めない（初期化を待ち、失敗時は既定マーカー）
    if (_customGymMarker == null) {
      await _initializeMap();
    }
    final icon = _customGymMarker ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

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
        icon: icon,
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

    if (!mounted) return;
    setState(() {
      _markers = markers;
    });
  }

  Widget _buildGymCardList(List<Gym> gyms) {
    return Column(
      children: [
          // ハンドルバー
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.wareme,
              borderRadius: BorderRadius.circular(AppRadius.tape),
            ),
          ),

          // ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  widget.selectionMode
                      ? 'ピンをタップしてジムを選ぶ'
                      : '近くのジム (${gyms.length}件)',
                  style: AppText.heading(size: 15),
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
                        ? AppColors.wareme
                        : AppColors.setsuri,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: _focusedGymIndex == index
                        ? Border.all(color: AppColors.kabeBlue, width: 2)
                        : Border.all(color: AppColors.wareme),
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
                            if (widget.selectionMode) {
                              Navigator.pop(context,
                                  {'gymId': gym.id, 'gymName': gym.name});
                            } else {
                              await NavigationHelper.toGymDetail(
                                  context, gym.id);
                            }
                          },
                          child: Container(
                            height: 44,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${gym.name} [${gym.prefecture}]',
                              style: AppText.body(
                                size: 12,
                                weight: FontWeight.w700,
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
                                  color: AppColors.holdRed,
                                ),
                              ),
                            if (gym.isLeadGym)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: GymCategory(
                                  category: 'リード',
                                  color: AppColors.holdGreen,
                                ),
                              ),
                            if (gym.isSpeedGym)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: GymCategory(
                                  category: 'スピード',
                                  color: AppColors.holdCyan,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // ジム写真（自前写真 or Google Places API）
                        GymPhotoStrip(gymId: gym.id, height: 100),
                        const SizedBox(height: 8),

                        // 料金と営業状態
                        Row(
                          children: [
                            const Icon(Icons.currency_yen,
                                size: 18, color: AppColors.sunabokori),
                            const SizedBox(width: 4),
                            Text(
                              '${gym.minimumFee}〜',
                              style: AppText.number(size: 14),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time,
                                size: 18, color: AppColors.sunabokori),
                            const SizedBox(width: 4),
                            Text(
                              isOpen ? 'OPEN' : 'CLOSE',
                              style: AppText.label(
                                size: 12,
                                color: isOpen
                                    ? AppColors.holdGreen
                                    : AppColors.holdRed,
                              ),
                            ),
                          ],
                        ),
                        if (widget.selectionMode) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context,
                                  {'gymId': gym.id, 'gymName': gym.name}),
                              child: Text(widget.confirmLabel,
                                  style: AppText.label(
                                      size: 14,
                                      color: AppColors.onKabeBlue)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
