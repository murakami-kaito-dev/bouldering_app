import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/report_provider.dart';
import '../providers/user_provider.dart';

/// 報告フォーム画面
/// 
/// ツイートの不適切な内容を報告するためのフォーム画面
/// 参考画像: debug_photo/報告フォーム.jpg の通りに実装
class ReportPage extends ConsumerStatefulWidget {
  final String targetUserId;
  final int targetTweetId;

  const ReportPage({
    super.key,
    required this.targetUserId,
    required this.targetTweetId,
  });

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();

  @override
  void dispose() {
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final userAsyncValue = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '報告フォーム',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 報告内容セクション
            const Text(
              '報告内容',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // 説明文
            const Text(
              'ガイドライン違反などお気付きの点があればお知らせください。報告いただいた内容については、運営側で随時確認を行います。返信は致しませんのでご了承ください。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // テキスト入力フィールド
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocusNode,
                  maxLines: null,
                  maxLength: 1000,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: '報告内容を入力してください',
                    hintStyle: TextStyle(color: Colors.grey),
                    counterText: '', // 文字数カウンターを非表示
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 送信ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: reportState.isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF), // iOS風の青色
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: reportState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '送信',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // 利用規約・ガイドラインリンク
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    // 利用規約へのリンク（実装時にURLを設定）
                  },
                  child: const Text(
                    '利用規約はこちら',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // コミュニティガイドラインへのリンク（実装時にURLを設定）
                  },
                  child: const Text(
                    'コミュニティガイドラインはこちら',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 報告を送信する
  Future<void> _submitReport() async {
    final description = _descriptionController.text.trim();
    
    // 入力内容のバリデーション
    if (description.isEmpty) {
      _showErrorSnackBar('報告内容を入力してください');
      return;
    }

    final userAsyncValue = ref.read(userProvider);
    final myUserId = userAsyncValue.when(
      data: (user) => user?.id,
      loading: () => null,
      error: (_, __) => null,
    );

    if (myUserId == null) {
      _showErrorSnackBar('ログインが必要です');
      return;
    }

    try {
      final reportNotifier = ref.read(reportProvider.notifier);
      final success = await reportNotifier.submitReport(
        reporterUserId: myUserId,
        targetUserId: widget.targetUserId,
        targetTweetId: widget.targetTweetId,
        reportDescription: description,
      );

      if (!mounted) return;

      if (success) {
        // 成功時
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('報告を送信しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        // 失敗時
        _showErrorSnackBar('報告の送信に失敗しました');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('エラーが発生しました: ${e.toString()}');
    }
  }

  /// エラーメッセージを表示する
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}