import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'topics/01_infinite_scroll/infinite_scroll_page.dart';
import 'topics/02_clean_architecture/presentation/gym_list_page.dart';
import 'topics/03_riverpod_basics/riverpod_basics_page.dart';
import 'topics/03_riverpod_basics/riverpod_deep_dive_page.dart';
import 'topics/04_auth_flow/auth_flow_page.dart';
import 'topics/05_env_switching/env_switching_page.dart';
import 'topics/06_optimistic_update/optimistic_update_page.dart';
import 'topics/07_search_filter/search_filter_page.dart';
import 'topics/08_image_upload/image_upload_page.dart';
import 'topics/09_text_moderation/text_moderation_page.dart';
import 'topics/10_navigation/navigation_demo_page.dart';

void main() {
  runApp(const ProviderScope(child: LearningApp()));
}

/// 学習用ミニアプリのランチャー。
/// 各トピックは lib/topics/ 配下で独立しており、相互依存はない。
/// それぞれのフォルダの README.md に「本体のどこで使われているか」を記載している。
class LearningApp extends StatelessWidget {
  const LearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bouldering Learning',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const TopicMenuPage(),
    );
  }
}

class Topic {
  const Topic(this.number, this.title, this.subtitle, this.builder);
  final String number;
  final String title;
  final String subtitle; // 面接想定質問
  final WidgetBuilder builder;
}

final topics = <Topic>[
  Topic('01', '無限スクロール & Pull-to-Refresh', '「無限スクロールはどう実装しますか？」',
      (_) => const InfiniteScrollPage()),
  Topic('02', 'Clean Architecture 最小構成', '「層と依存の向きを説明してください」',
      (_) => const GymListPage()),
  Topic('03', 'Riverpod 状態管理入門', '「状態管理に何を使い、なぜですか？」',
      (_) => const RiverpodBasicsPage()),
  Topic('03+', 'Riverpod 深掘りデモ', 'autoDispose/familyの挙動を体験（本体PR #27の題材）',
      (_) => const RiverpodDeepDivePage()),
  Topic('04', '認証フローとトークン管理', '「トークン失効をどう検知しますか？」',
      (_) => const AuthFlowPage()),
  Topic('05', '環境切替（dev/prod）', '「開発と本番をどう分離しますか？」',
      (_) => const EnvSwitchingPage()),
  Topic('06', '楽観的UI更新とロールバック', '「いいねの即時反映はどう実装しますか？」',
      (_) => const OptimisticUpdatePage()),
  Topic('07', '検索とフィルタリング', '「インクリメンタル検索の性能問題は？」',
      (_) => const SearchFilterPage()),
  Topic('08', '画像アップロードのパイプライン', '「画像アップロードの設計は？」',
      (_) => const ImageUploadPage()),
  Topic('09', 'テキストモデレーション', '「不適切語フィルタをどう作りますか？」',
      (_) => const TextModerationPage()),
  Topic('10', 'ルーティングと値渡し', '「画面遷移でデータをどう渡しますか？」',
      (_) => const NavigationDemoPage()),
];

class TopicMenuPage extends StatelessWidget {
  const TopicMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学習用ミニアプリ')),
      body: ListView.separated(
        itemCount: topics.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final t = topics[i];
          return ListTile(
            leading: CircleAvatar(child: Text(t.number)),
            title: Text(t.title),
            subtitle: Text(t.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: t.builder),
            ),
          );
        },
      ),
    );
  }
}
