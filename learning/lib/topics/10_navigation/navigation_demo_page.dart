import 'package:flutter/material.dart';

/// ============================================================
/// トピック10: ルーティングと画面間の値渡し
///
/// 本体の対応箇所:
///   lib/shared/constants/app_routes.dart（ルート名とパラメータキーの定数）
///   lib/presentation/pages/app.dart:58-90（MaterialApp.routes への登録）
///   lib/shared/utils/navigation_helper.dart（pushNamedのラッパ）
///   lib/presentation/pages/gym_selection_page.dart（結果を返す画面の実例）
///
/// 本体のパターン3つをこの1画面から体験できる:
///   A) pushNamed + arguments(Map) … 本体の主流。ジム詳細への遷移など
///   B) Navigator.pop(result) で値を返す … ジム選択画面（selectionMode）
///   C) 型安全ラッパ … Mapのキー間違いをコンパイル時に防ぐ改善形
/// ============================================================

class NavigationDemoPage extends StatefulWidget {
  const NavigationDemoPage({super.key});

  @override
  State<NavigationDemoPage> createState() => _NavigationDemoPageState();
}

class _NavigationDemoPageState extends State<NavigationDemoPage> {
  String _selectedGym = '（未選択）';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('10 ルーティングと値渡し')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('A) 引数を渡して遷移する（本体の主流パターン）',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            '本体は pushNamed + Map の arguments。受け取り側は\n'
            'ModalRoute.of(context).settings.arguments をキャストして取り出す。\n'
            'キーはタイプミス防止のため RouteParams 定数に集約している。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                // MaterialApp.routes を使わないミニアプリなので
                // settings.arguments を明示的に渡して同じ構造を再現している
                settings: const RouteSettings(arguments: {
                  'gymId': 42, // 本体: RouteParams.gymId
                  'gymName': 'ロックランド新宿',
                }),
                builder: (_) => const GymDetailDemoPage(),
              ),
            ),
            child: const Text('ジム詳細へ（gymId=42を渡す）'),
          ),
          const Divider(height: 32),
          const Text('B) 遷移先から値を「返してもらう」',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            '本体のジム選択画面（gym_selection_page.dart）と同じ。\n'
            'push の Future を await し、遷移先が Navigator.pop(result) した\n'
            '値を受け取る。ユーザーが戻るボタンで帰ると null になる点に注意。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () async {
              // 型引数<String>で「何が返るか」を宣言する
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const GymPickerDemoPage()),
              );
              setState(() =>
                  _selectedGym = result ?? '（キャンセルされた: nullが返った）');
            },
            child: const Text('ジムを選択する'),
          ),
          const SizedBox(height: 8),
          Text('選択結果: $_selectedGym'),
          const Divider(height: 32),
          const Text('C) 型安全ラッパ（改善形）',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Mapの弱点は「キーのタイプミス」「型キャスト忘れ」が実行時まで\n'
            'わからないこと。遷移関数を1つ用意して引数を型で受ければ\n'
            'コンパイル時に守れる（本体の NavigationHelper.toGymDetail が\n'
            'この発想。go_router の型付きルートはさらにこの発展形）。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                GymDetailDemoPage.push(context, gymId: 7, gymName: 'なんばウォール'),
            child: const Text('型安全ラッパで遷移（gymId=7）'),
          ),
        ],
      ),
    );
  }
}

/// ---- 遷移先(A/C共用): 引数を受け取る画面 ----
class GymDetailDemoPage extends StatelessWidget {
  const GymDetailDemoPage({super.key});

  /// C) 型安全ラッパ: 呼び出し側はMapのキーを知らなくてよい
  static Future<void> push(BuildContext context,
      {required int gymId, required String gymName}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        settings:
            RouteSettings(arguments: {'gymId': gymId, 'gymName': gymName}),
        builder: (_) => const GymDetailDemoPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 本体と同じ受け取り方（app.dart のルート定義内で行っている処理に相当）
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final gymId = args?['gymId'] as int?;
    final gymName = args?['gymName'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('ジム詳細（デモ）')),
      body: Center(
        child: Text(
          gymId == null
              ? '引数が渡されていない\n（Mapキーのミスは実行時にしか気づけない）'
              : '受け取った引数:\ngymId = $gymId\ngymName = $gymName',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// ---- 遷移先(B): 値を返す画面（本体の gym_selection_page 相当）----
class GymPickerDemoPage extends StatelessWidget {
  const GymPickerDemoPage({super.key});

  static const _gyms = ['ロックランド新宿', '大阪ロックジム', '博多ボルダリングベース'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ジムを選択（デモ）')),
      body: ListView(
        children: [
          for (final gym in _gyms)
            ListTile(
              title: Text(gym),
              // 選んだ値を pop で「返す」。呼び出し元の await が受け取る
              onTap: () => Navigator.pop(context, gym),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '← 戻るボタンで帰ると呼び出し元には null が返る。\n'
              '呼び出し元は必ず null を処理すること。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
