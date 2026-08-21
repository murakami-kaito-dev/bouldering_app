import 'package:flutter/material.dart';

/// ============================================================
/// トピック09: テキストモデレーション（NGワードフィルタ）
///
/// 本体の対応箇所:
///   lib/infrastructure/services/local_text_moderation_service.dart
///   lib/infrastructure/data/ng_words_data.dart（NGワード辞書）
///   lib/domain/usecases/validate_post_content_usecase.dart
///   適用箇所: 投稿本文・ユーザー名・自己紹介・好きなジム
///
/// 背景: App Store Guideline 1.2（UGCアプリは不適切コンテンツ対策必須）。
/// 本体はこれを「端末内判定」で実装して審査を通している。
///
/// 要点:
///   1. 正規化してから比較する（大文字小文字・全角半角）。
///      本体は両辺 toLowerCase() する。※本体の辞書には 'FUCK','Fuck' の
///      大文字バリアントが重複登録されており無意味（リファクタ候補）
///   2. 検出結果は「どの語に引っかかったか」まで返すとUXが良い
///   3. 端末内判定 vs サーバ判定のトレードオフを説明できるように
/// ============================================================

/// デモ用のNGワード辞書（本体の ng_words_data.dart のミニ版）
const ngWords = ['ばか', 'あほ', 'badword', '死ね'];

class ModerationResult {
  const ModerationResult(this.detectedWords);
  final List<String> detectedWords;
  bool get isClean => detectedWords.isEmpty;
}

/// 本体の LocalTextModerationService.checkText() のミニ版
ModerationResult moderate(String text) {
  // 要点1: 入力側だけ正規化すれば、辞書は小文字で持てばよい
  final normalized = text.toLowerCase();
  final detected =
      ngWords.where((w) => normalized.contains(w.toLowerCase())).toList();
  return ModerationResult(detected);
}

/// 検出語をマスクした表示例（本体には無い拡張。UXの選択肢として）
String mask(String text) {
  var result = text;
  for (final w in ngWords) {
    result = result.replaceAll(
        RegExp(RegExp.escape(w), caseSensitive: false), '＊' * w.length);
  }
  return result;
}

class TextModerationPage extends StatefulWidget {
  const TextModerationPage({super.key});

  @override
  State<TextModerationPage> createState() => _TextModerationPageState();
}

class _TextModerationPageState extends State<TextModerationPage> {
  String _input = '';

  @override
  Widget build(BuildContext context) {
    final result = moderate(_input);

    return Scaffold(
      appBar: AppBar(title: const Text('09 テキストモデレーション')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('デモ用NGワード辞書: ${ngWords.join('、')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '投稿本文を入力（NGワードを含めてみる。大文字BADWORDも試す）',
              border: OutlineInputBorder(),
            ),
            onChanged: (t) => setState(() => _input = t),
          ),
          const SizedBox(height: 16),
          Card(
            color: result.isClean
                ? Colors.green.shade50
                : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.isClean ? '✅ 投稿できます' : '⚠️ 不適切な表現が含まれています',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (!result.isClean) ...[
                    const SizedBox(height: 8),
                    Text('検出語: ${result.detectedWords.join('、')}'),
                    const SizedBox(height: 8),
                    Text('マスク表示例: ${mask(_input)}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('設計メモ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            '・本体は「投稿ボタン押下時」にこの判定を通し、NGなら投稿APIを呼ばない\n'
            '・判定は端末内（辞書もアプリに同梱）。通信不要で高速だが、\n'
            '  辞書更新にはアプリのアップデートが必要\n'
            '・サーバ判定にすると辞書を即時更新でき、改造クライアントも防げるが、\n'
            '  遅延が乗る。本格運用は両方（端末=即時UX、サーバ=最終防衛線）\n'
            '・App Store Guideline 1.2 のUGC要件（通報・ブロック・フィルタ）の\n'
            '  一角。本体では通報とブロックも併せて実装している',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
