import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/common/switcher_tab.dart';
import '../components/common/gym_category.dart';
import '../providers/gym_provider.dart';
import '../providers/user_provider.dart';
import '../providers/dependency_injection.dart';
import '../components/tweet/gym_tweets_section.dart';
import '../components/gym/gym_photo_strip.dart';
import '../../domain/entities/gym.dart';
import 'activity_post_page.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';

// Mock実装（テスト時のみ使用）
// Mock環境用の簡単な表示コンポーネントをここにインポート

/// ジム詳細情報ページ
///
/// 役割:
/// - ジムの基本情報表示
/// - ジムの投稿（ボル活）一覧表示
/// - イキタイ機能
/// - ボル活投稿機能
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のUIコンポーネント
/// - Domain層のエンティティを表示
/// - UseCaseを通じてビジネスロジックを実行
class GymDetailPage extends ConsumerStatefulWidget {
  const GymDetailPage({
    super.key,
    required this.gymId,
  });
  final String gymId;

  @override
  GymDetailPageState createState() => GymDetailPageState();
}

class GymDetailPageState extends ConsumerState<GymDetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isFavoriteRegistered = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // ジム詳細情報を取得（全件キャッシュにあれば即表示し、個別APIで最新値に上書き）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gymId = int.parse(widget.gymId);
      final seed = ref.read(gymMapProvider)[gymId];
      ref.read(gymDetailProvider.notifier).loadGymDetail(gymId, seed: seed);
    });

    Future.microtask(() async {
      // 実際のイキタイ状態を取得
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        try {
          final favoriteGymIds = await ref
              .read(manageFavoriteGymUseCaseProvider)
              .getFavoriteGyms(currentUser.id);
          setState(() {
            _isFavoriteRegistered = favoriteGymIds.contains(int.parse(widget.gymId));
          });
        } catch (e) {
          // エラー時は未登録として扱う
          setState(() {
            _isFavoriteRegistered = false;
          });
        }
      } else {
        setState(() {
          _isFavoriteRegistered = false;
        });
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 100) {
      // TODO: 本番環境では以下を有効化してジムの投稿をさらに読み込み
      // ref.read(gymTweetsProvider(widget.gymId).notifier).loadMore();
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: 本番環境では以下のProviderからジム詳細を取得
    final gymDetailState = ref.watch(gymDetailProvider);

    final userAsyncValue = ref.watch(userProvider);
    final isLoggedIn = userAsyncValue.when(
      data: (user) => user != null,
      loading: () => false,
      error: (_, __) => false,
    );

    return gymDetailState.when(
      loading: () => _buildLoadingScaffold(),
      error: (error, stack) => _buildErrorScaffold(),
      data: (gymInfo) {
        if (gymInfo == null) {
          return _buildErrorScaffold();
        }

        return _buildGymDetailScaffold(gymInfo, isLoggedIn);
      },
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: AppColors.iwa,
      appBar: AppBar(
        backgroundColor: AppColors.iwa,
        surfaceTintColor: AppColors.iwa,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.chalk),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: CircularProgressIndicator(color: AppColors.kabeBlue),
      ),
    );
  }

  Widget _buildErrorScaffold() {
    return Scaffold(
      backgroundColor: AppColors.iwa,
      appBar: AppBar(
        backgroundColor: AppColors.iwa,
        surfaceTintColor: AppColors.iwa,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.chalk),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(child: Text("このジムデータはありません")),
    );
  }

  Widget _buildGymDetailScaffold(Gym gymInfo, bool isLoggedIn) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.iwa,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.iwa,
          surfaceTintColor: AppColors.iwa,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.chalk),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SwitcherTab(
                leftTabName: "施設情報",
                rightTabName: "ボル活",
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight),
              child: TabBarView(children: [
                _buildFacilityInfoTab(gymInfo),
                _buildBoulActivityTab(),
              ]),
            ),
            if (isLoggedIn) _buildBottomButtons(gymInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityInfoTab(Gym gymInfo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ジム名
          Text(
            gymInfo.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          // カテゴリータグ
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (gymInfo.isBoulderingGym)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: GymCategory(
                    category: 'ボルダリング',
                    color: AppColors.holdRed,
                  ),
                ),
              if (gymInfo.isLeadGym)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: GymCategory(
                    category: 'リード',
                    color: AppColors.holdGreen,
                  ),
                ),
              if (gymInfo.isSpeedGym)
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

          // イキタイ・ボル活カウント
          GymIkitaiBoullogCount(
            ikitaiCount: gymInfo.ikitaiCount.toString(),
            boullogCount: gymInfo.boulCount.toString(),
          ),
          const SizedBox(height: 12),

          // ギャラリー（自前写真 or Google Places API。出どころはバックエンドが判定）
          // 写真1.7枚分が見える幅にし、タップでツイート写真と同じ拡大ビューアを開く
          Builder(builder: (context) {
            // 画面幅 - 左右padding(16×2) を1.7枚分のストライドで割り、写真間の隙間8pxを引く
            final photoWidth =
                (MediaQuery.of(context).size.width - 32) / 1.7 - 8;
            return GymPhotoStrip(
              gymId: gymInfo.id,
              photoWidth: photoWidth,
              height: photoWidth * 0.75, // 既存カードと同じ4:3比率
              enableViewer: true,
              heroTagPrefix: 'gym_detail_photo_${gymInfo.id}',
            );
          }),
          const SizedBox(height: 16),

          // 基本情報
          const Text(
            '基本情報',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          _buildInfoRow('住所', gymInfo.fullAddress),
          _buildInfoRow('TEL', gymInfo.telNo),
          _buildInfoRow(
            'HP',
            gymInfo.hpLink,
            isLink: gymInfo.hpLink.isNotEmpty,
            onTap: gymInfo.hpLink.isNotEmpty
                ? () => _launchUrl(gymInfo.hpLink)
                : null,
          ),
          _buildInfoRow('定休日', 'なし'),
          _buildInfoRow('営業時間', _formatBusinessHours(gymInfo)),
          const SizedBox(height: 16),

          // 料金情報
          const Text(
            '料金',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text('${gymInfo.fee}\n\n■レンタル\n${gymInfo.equipmentRentalFee}'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBoulActivityTab() {
    // gymIdをStringからintに変換してプロバイダーに渡す
    final gymIdInt = int.tryParse(widget.gymId) ?? 0;

    // 専用コンポーネントを使用してシンプルに
    return GymTweetsSection(gymId: gymIdInt);
  }

  Widget _buildBottomButtons(Gym gymInfo) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        decoration: BoxDecoration(
          // 下端の読みやすさ確保（内容の上に浮くバーなのでスクリムを敷く）
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.iwa.withOpacity(0),
              AppColors.iwa.withOpacity(0.9),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
                child: OutlinedButton(
              onPressed: () async {
                // 実際のイキタイ登録/解除処理を実装
                final currentUser = ref.read(currentUserProvider);
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ログインが必要です')),
                  );
                  return;
                }

                try {
                  final manageFavoriteGymUseCase = ref.read(manageFavoriteGymUseCaseProvider);
                  bool success;
                  
                  if (_isFavoriteRegistered) {
                    success = await manageFavoriteGymUseCase.removeFavoriteGym(
                      currentUser.id, 
                      gymInfo.id
                    );
                    if (success) {
                      setState(() {
                        _isFavoriteRegistered = false;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('イキタイを解除しました')),
                        );
                      }
                    }
                  } else {
                    success = await manageFavoriteGymUseCase.addFavoriteGym(
                      currentUser.id, 
                      gymInfo.id
                    );
                    if (success) {
                      setState(() {
                        _isFavoriteRegistered = true;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('イキタイに登録しました')),
                        );
                      }
                    }
                  }
                  
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('処理に失敗しました')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('エラーが発生しました: $e')),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: _isFavoriteRegistered
                    ? AppColors.kabeBlue
                    : AppColors.setsuri,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: const StadiumBorder(),
                side: BorderSide(
                  color: _isFavoriteRegistered
                      ? AppColors.kabeBlue
                      : AppColors.wareme,
                ),
              ),
              child: Text(
                _isFavoriteRegistered ? 'イキタイ登録済み' : 'イキタイに追加',
                style: AppText.label(
                  size: 14,
                  color: _isFavoriteRegistered
                      ? AppColors.onKabeBlue
                      : AppColors.chalk,
                ),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton(
              onPressed: () {
                // ボル活投稿をモーダルシートで開く（ジムが事前選択された状態）
                showActivityPostSheet(
                  context,
                  preSelectedGymId: gymInfo.id,
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                backgroundColor: AppColors.kabeBlue,
              ),
              child: Text('ボル活を投稿',
                  style:
                      AppText.label(size: 14, color: AppColors.onKabeBlue)),
            )),
          ],
        ),
      ),
    );
  }

  /// ジムの営業時間を曜日ごとにフォーマットして表示用文字列を生成
  ///
  /// [gym] 営業時間情報を含むジムエンティティ
  ///
  /// 返り値:
  /// 各曜日の営業時間を改行区切りで連結した文字列
  ///
  /// 表示形式:
  /// - 営業日: 「曜日名 HH:MM〜HH:MM」
  /// - 休業日: 「曜日名 休業日」
  String _formatBusinessHours(Gym gym) {
    final hours = gym.hours;
    return '月曜日 ${_formatDayHours(hours.monOpen, hours.monClose)}\n'
        '火曜日 ${_formatDayHours(hours.tueOpen, hours.tueClose)}\n'
        '水曜日 ${_formatDayHours(hours.wedOpen, hours.wedClose)}\n'
        '木曜日 ${_formatDayHours(hours.thuOpen, hours.thuClose)}\n'
        '金曜日 ${_formatDayHours(hours.friOpen, hours.friClose)}\n'
        '土曜日 ${_formatDayHours(hours.satOpen, hours.satClose)}\n'
        '日曜日 ${_formatDayHours(hours.sunOpen, hours.sunClose)}';
  }

  /// 1日分の営業時間をフォーマット
  ///
  /// [openTime] 開店時間（HH:MM:SS形式またはnull）
  /// [closeTime] 閉店時間（HH:MM:SS形式またはnull）
  ///
  /// 返り値:
  /// - 営業日の場合: 「HH:MM〜HH:MM」形式
  /// - 休業日の場合: 「休業日」
  ///
  /// 処理内容:
  /// 1. 両方nullまたは'-'の場合は休業日と判定
  /// 2. データ不整合（片方だけnull）も休業日として扱う
  /// 3. 正常な時間データは秒を削除してHH:MM形式で表示
  String _formatDayHours(String? openTime, String? closeTime) {
    // 両方nullまたは'-'の場合は休業日
    if ((openTime == null || openTime == '-') &&
        (closeTime == null || closeTime == '-')) {
      return '休業日';
    }

    // 片方だけnullの場合も休業日とする（データ不整合対応）
    if (openTime == null ||
        closeTime == null ||
        openTime == '-' ||
        closeTime == '-') {
      return '休業日';
    }

    // 営業時間をHH:MM形式にフォーマット
    return '${_formatTime(openTime)}〜${_formatTime(closeTime)}';
  }

  /// 時刻文字列から秒を削除してHH:MM形式に変換
  ///
  /// [time] 時刻文字列（HH:MM:SS形式）
  ///
  /// 返り値:
  /// HH:MM形式の時刻文字列
  ///
  /// 例:
  /// - 入力: "15:00:00" → 出力: "15:00"
  /// - 入力: "23:30:00" → 出力: "23:30"
  String _formatTime(String time) {
    // HH:MM:SS形式からHH:MM形式に変換
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  Widget _buildInfoRow(String label, String value,
      {bool isLink = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: isLink ? onTap : null,
              child: Text(
                value,
                style: TextStyle(color: isLink ? AppColors.kabeBlue : AppColors.chalk),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

/// イキタイ・ボル活カウント表示ウィジェット
class GymIkitaiBoullogCount extends StatelessWidget {
  final String ikitaiCount;
  final String boullogCount;

  const GymIkitaiBoullogCount({
    super.key,
    required this.ikitaiCount,
    required this.boullogCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _statTile('イキタイ', ikitaiCount, AppColors.kabeBlue)),
        const SizedBox(width: 10),
        Expanded(
            child: _statTile('ボル活', boullogCount, AppColors.holdRed)),
      ],
    );
  }

  /// 統計タイル（数字が顔。イキタイ=壁ブルー / ボル活=ホールド赤）
  Widget _statTile(String label, String value, Color numberColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.setsuri,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.wareme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppText.number(size: 28, color: numberColor)),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption(size: 11)),
        ],
      ),
    );
  }
}
