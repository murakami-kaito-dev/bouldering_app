import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/user_provider.dart';
import '../../providers/dependency_injection.dart';
import '../../providers/block_provider.dart';
import '../../../shared/utils/image_url_validator.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../../pages/activity_post_page.dart';
import '../../pages/report_page.dart';
import 'image_viewer.dart';

class BoulLog extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String? userIconUrl;
  final String visitedDate;
  final int gymId;
  final String gymName;
  final String prefecture;
  final String content;
  final List<String>? mediaUrls; // 画像がある場合のみ使用される
  final int? tweetId;
  final VoidCallback? onBlockSuccess; // ブロック成功時のコールバック

  const BoulLog({
    super.key,
    required this.userId,
    required this.userName,
    required this.userIconUrl,
    required this.visitedDate,
    required this.gymId,
    required this.gymName,
    required this.prefecture,
    required this.content,
    this.mediaUrls, // null許容にすることで未添付もOK
    this.tweetId,
    this.onBlockSuccess, // ブロック成功時の処理を親から受け取る
  });

  @override
  ConsumerState<BoulLog> createState() => _BoulLogState();
}

class _BoulLogState extends ConsumerState<BoulLog> {
  late List<String> _imageUrls;

  @override
  void initState() {
    super.initState();
    _imageUrls = ImageUrlValidator.filterValidImageUrls(widget.mediaUrls ?? []);
  }

  @override
  void didUpdateWidget(covariant BoulLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 新しく画像が渡された場合のみ更新（古い空リストで上書きしない）
    if ((widget.mediaUrls != null && widget.mediaUrls!.isNotEmpty)) {
      _imageUrls = ImageUrlValidator.filterValidImageUrls(widget.mediaUrls!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider);
    final myUserId = userAsyncValue.when(
      data: (user) => user?.id,
      loading: () => null,
      error: (_, __) => null,
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ユーザーアイコン
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                backgroundImage: ImageUrlValidator.isValidImageUrl(widget.userIconUrl)
                    ? NetworkImage(widget.userIconUrl!)
                    : null,
                child: ImageUrlValidator.isValidImageUrl(widget.userIconUrl)
                    ? null
                    : const Icon(Icons.person, color: Colors.grey, size: 24),
              ),
              const SizedBox(width: 12),

              // ユーザー名・日付
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        NavigationHelper.toOtherUserProfile(context, widget.userId);
                      },
                      child: Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      widget.visitedDate,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // ログインしているユーザーの場合「⋮」を表示する
              // 自分のツイート：編集・削除・報告 機能
              // 他人のツイート：報告 機能
              if (myUserId != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'delete' && widget.tweetId != null) {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          titlePadding: const EdgeInsets.only(
                              top: 24, left: 24, right: 24, bottom: 0),
                          contentPadding:
                              const EdgeInsets.fromLTRB(24, 8, 24, 0),
                          title: const Center(
                            child: Text(
                              "削除しますか？",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          content: const Text(
                            "一度削除すると戻すことはできません．本当にこのボル活を削除しますか？\n",
                            style: TextStyle(fontSize: 14, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                          actionsAlignment: MainAxisAlignment.spaceBetween,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                "キャンセル",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                "削除",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      
                      if (shouldDelete == true && myUserId != null) {
                        try {
                          final deleteTweetUseCase = ref.read(deleteTweetUseCaseProvider);
                          final success = await deleteTweetUseCase.execute(widget.tweetId!, myUserId);
                          
                          if (!context.mounted) return;
                          
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('削除しました')),
                            );
                            // 削除成功時にページをリフレッシュ
                            // Note: 呼び出し元で対応が必要な場合があります
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('削除に失敗しました')),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('削除に失敗しました: $e')),
                          );
                        }
                      }
                    } else if (value == 'edit' && widget.tweetId != null) {
                      // 編集ページへ遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivityPostPage(
                            initialData: {
                              'tweetId': widget.tweetId,
                              'tweetContents': widget.content,
                              'gymId': widget.gymId.toString(),
                              'gymName': widget.gymName,
                              'visitedDate': widget.visitedDate,
                              'mediaUrls': widget.mediaUrls ?? [],
                            },
                          ),
                        ),
                      );
                    } else if (value == 'block') {
                      // ブロック確認ダイアログを表示
                      final shouldBlock = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          titlePadding: const EdgeInsets.only(
                              top: 24, left: 24, right: 24, bottom: 0),
                          contentPadding:
                              const EdgeInsets.fromLTRB(24, 8, 24, 0),
                          title: const Center(
                            child: Text(
                              "ユーザーをブロック",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          content: const Text(
                            "このユーザーについて\n本当にブロックしてよろしいですか？\n",
                            style: TextStyle(fontSize: 14, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                          actionsAlignment: MainAxisAlignment.spaceBetween,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                "キャンセル",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                "ブロックする",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      
                      if (shouldBlock == true) {
                        try {
                          await ref.read(blockProvider.notifier).blockUser(widget.userId);
                          
                          if (!context.mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ユーザーをブロックしました')),
                          );
                          
                          // ブロック成功時、親コンポーネントに通知
                          // これにより、ツイート一覧が更新される
                          widget.onBlockSuccess?.call();
                        } catch (e) {
                          if (!context.mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ブロックに失敗しました')),
                          );
                        }
                      }
                    } else if (value == 'report' && widget.tweetId != null) {
                      // 報告画面への遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportPage(
                            targetUserId: widget.userId,
                            targetTweetId: widget.tweetId!,
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) {
                    final isMyTweet = widget.userId == myUserId;
                    
                    return [
                      // 自分のツイートの場合は編集・削除を表示
                      if (isMyTweet) ...[
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('編集する'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            '削除する',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      // 報告・ブロックは他人のツイートの場合のみ表示
                      if (!isMyTweet) ...[
                        const PopupMenuItem(
                          value: 'block',
                          child: Text('ブロック'),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Text('報告する'),
                        ),
                      ],
                    ];
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.only(left: 56.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ジム名・場所
                GestureDetector(
                  onTap: () async {
                    // ジム詳細ページに遷移
                    NavigationHelper.toGymDetail(context, widget.gymId);
                  },
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.gymName,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' [${widget.prefecture}]',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // 活動内容
                widget.content.isEmpty
                    ? const SizedBox(height: 16) // 最小高さ確保
                    : Text(
                        widget.content,
                        style: const TextStyle(fontSize: 14),
                      ),
                const SizedBox(height: 8),

                // 画像がある場合だけ表示（横スクロール）
                if (_imageUrls.isNotEmpty)
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageUrls.length,
                      itemBuilder: (context, index) {
                        final imageUrl = _imageUrls[index];
                        return Padding(
                          padding: EdgeInsets.only(
                              right:
                                  index != _imageUrls.length - 1 ? 8.0 : 0.0),
                          child: GestureDetector(
                            onTap: () {
                              // 画像拡大表示を開く
                              ImageViewer.show(
                                context: context,
                                imageUrls: _imageUrls,
                                initialIndex: index,
                                heroTagPrefix: 'boul_log_${widget.userId}_${widget.tweetId}',
                              );
                            },
                            child: Hero(
                              tag: 'boul_log_${widget.userId}_${widget.tweetId}_$index',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 200,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 下線
          Container(
            width: MediaQuery.of(context).size.width - 16,
            height: 1,
            color: const Color(0xFFB1B1B1),
          ),
        ],
      ),
    );
  }

}