import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/tweet.dart';
import '../../domain/usecases/comment_usecases.dart';
import '../../shared/utils/app_clock.dart';
import '../../shared/utils/image_url_validator.dart';
import '../../shared/utils/navigation_helper.dart';
import '../components/common/boul_log.dart';
import '../components/common/boul_log_skeleton.dart';
import '../providers/dependency_injection.dart';
import '../providers/tweet_comments_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import 'login_or_signup_page.dart';

/// スレッド画面（ボル活の詳細＋コメント・返信）
///
/// 役割:
/// - 上に投稿（BoulLog をそのまま）、その下にコメント一覧
/// - コメントは 2 段表示: ルート → 1 段インデントした返信（返信への返信は「@名前 さん」）
/// - 削除済みコメントは「このコメントは削除されました」のプレースホルダ。
///   ただし表示すべき子孫が無い削除済みコメントは表示しない（葉の削除は単に消える）
/// - 画面下部に固定の入力欄。返信は「@名前 さんに返信 ×」チップで示す
/// - 自分のコメント／自分の投稿へのコメントは「⋮」から削除（確認ダイアログ）
/// - 未ログインは入力欄を押すとログイン導線
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation 層の Page。tweetCommentsProvider（一覧）と GetTweetByIdUseCase（投稿）を使う
class TweetDetailPage extends ConsumerStatefulWidget {
  final int tweetId;

  /// 呼び出し元が投稿を持っていれば渡す（取得中もカードを出せる）。無ければ API で取得
  final Tweet? initialTweet;

  const TweetDetailPage({
    super.key,
    required this.tweetId,
    this.initialTweet,
  });

  @override
  ConsumerState<TweetDetailPage> createState() => _TweetDetailPageState();
}

class _TweetDetailPageState extends ConsumerState<TweetDetailPage> {
  Tweet? _tweet;
  bool _tweetLoadFailed = false;

  /// 画面内で増減させたコメント数（一覧 Notifier とは別に、このカードの表示用）
  int? _commentCount;

  Comment? _replyTo;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tweet = widget.initialTweet;
    _commentCount = widget.initialTweet?.commentCount;
    _controller.addListener(() => setState(() {}));
    _loadTweet();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTweet() async {
    try {
      final tweet =
          await ref.read(getTweetByIdUseCaseProvider).execute(widget.tweetId);
      if (!mounted) return;
      setState(() {
        if (tweet != null) {
          _tweet = tweet;
          _commentCount = tweet.commentCount;
        } else {
          _tweetLoadFailed = _tweet == null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _tweetLoadFailed = _tweet == null);
    }
  }

  // ---------------------------------------------------------------------------
  // 操作
  // ---------------------------------------------------------------------------

  bool get _isLoggedIn => ref.read(userProvider).valueOrNull != null;

  /// 未ログイン時のログイン導線（マイページ未ログイン画面と同じ文言・遷移）
  Future<void> _promptLogin() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding:
            const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        title: const Center(
          child: Text(
            'ログインが必要です',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        content: const Text(
          'コメントするにはログインが必要です．\n登録は無料！\n',
          style: TextStyle(fontSize: 14, color: AppColors.chalk),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル',
                style: TextStyle(color: AppColors.chalk)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LoginOrSignUpPage()),
              );
            },
            child: const Text('新規登録 / ログイン',
                style: TextStyle(color: AppColors.kabeBlue)),
          ),
        ],
      ),
    );
  }

  void _startReply(Comment target) {
    if (!_isLoggedIn) {
      _promptLogin();
      return;
    }
    setState(() => _replyTo = target);
    _focusNode.requestFocus();
  }

  void _cancelReply() => setState(() => _replyTo = null);

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > kCommentMaxLength) return;
    if (!_isLoggedIn) {
      _promptLogin();
      return;
    }

    final notifier = ref.read(tweetCommentsProvider(widget.tweetId).notifier);
    try {
      await notifier.addComment(
        content: text,
        parentCommentId: _replyTo?.id,
      );
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _replyTo = null;
        _commentCount = (_commentCount ?? 0) + 1;
      });
      final tweet = _tweet;
      if (tweet != null) syncTweetCommentCount(ref, tweet, 1);
      _focusNode.unfocus();
      // 追加したコメントが見えるように末尾へ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('コメントの送信に失敗しました')),
      );
    }
  }

  Future<void> _confirmDelete(Comment comment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding:
            const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        title: const Center(
          child: Text(
            'コメントを削除しますか？',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        content: const Text(
          '一度削除すると戻すことはできません．\n',
          style: TextStyle(fontSize: 14, color: AppColors.chalk),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル',
                style: TextStyle(color: AppColors.chalk)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('削除', style: TextStyle(color: AppColors.holdRed)),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    try {
      await ref
          .read(tweetCommentsProvider(widget.tweetId).notifier)
          .deleteComment(comment.id);
      if (!mounted) return;
      setState(() {
        if (_replyTo?.id == comment.id) _replyTo = null;
        _commentCount = ((_commentCount ?? 1) - 1).clamp(0, 1 << 30);
      });
      final tweet = _tweet;
      if (tweet != null) syncTweetCommentCount(ref, tweet, -1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('コメントを削除しました')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除に失敗しました')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 表示ツリーの組み立て（2 段＋削除済みの表示ルール）
  // ---------------------------------------------------------------------------

  /// フラットな一覧を「ルート → その返信たち」に畳む。
  /// 削除済みでも表示すべき子孫があるものは残す（プレースホルダになる）
  List<_ThreadGroup> _buildGroups(List<Comment> comments) {
    final childrenOf = <int, List<Comment>>{};
    for (final c in comments) {
      final parentId = c.parentCommentId;
      if (parentId != null) {
        (childrenOf[parentId] ??= []).add(c);
      }
    }

    final visibleCache = <int, bool>{};
    bool isVisible(Comment c) {
      final cached = visibleCache[c.id];
      if (cached != null) return cached;
      final result = !c.isDeleted ||
          (childrenOf[c.id] ?? const []).any(isVisible);
      visibleCache[c.id] = result;
      return result;
    }

    final groups = <_ThreadGroup>[];
    final groupByRoot = <int, _ThreadGroup>{};
    for (final c in comments) {
      if (c.isRoot) {
        if (!isVisible(c)) continue;
        final g = _ThreadGroup(root: c);
        groups.add(g);
        groupByRoot[c.id] = g;
      }
    }
    for (final c in comments) {
      if (c.isRoot) continue;
      final g = groupByRoot[c.rootCommentId];
      // ルートが一覧に無い（ブロック等で除外）返信は表示しない
      if (g == null || !isVisible(c)) continue;
      g.replies.add(c);
    }
    return groups;
  }

  // ---------------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final myUserId = ref.watch(userProvider).valueOrNull?.id;
    final commentsState = ref.watch(tweetCommentsProvider(widget.tweetId));
    final tweet = _tweet;
    final groups = _buildGroups(commentsState.comments);

    return Scaffold(
      backgroundColor: AppColors.iwa,
      appBar: AppBar(
        backgroundColor: AppColors.iwa,
        surfaceTintColor: AppColors.iwa,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.chalk),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('コメント', style: AppText.heading(size: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                children: [
                  // 投稿カード
                  if (tweet != null)
                    BoulLog(
                      userId: tweet.userId,
                      userName: tweet.userName,
                      userIconUrl: tweet.userIconUrl,
                      visitedDate: AppClock.formatDateOnly(tweet.visitedDate),
                      gymId: tweet.gymId,
                      gymName: tweet.gymName,
                      prefecture: tweet.prefecture,
                      content: tweet.content,
                      mediaUrls: tweet.mediaUrls,
                      tweetId: tweet.id,
                      contextPrefix: 'thread',
                      commentCount: _commentCount ?? tweet.commentCount,
                      openDetailOnTap: false, // 既にスレッド画面
                      onCommentTap: () {
                        if (_isLoggedIn) {
                          _focusNode.requestFocus();
                        } else {
                          _promptLogin();
                        }
                      },
                      // 投稿者をブロックしたらこの画面に居る意味がないので閉じる
                      onBlockSuccess: () => Navigator.of(context).maybePop(),
                    )
                  else if (_tweetLoadFailed)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text('このボル活は表示できません',
                            style: AppText.caption(size: 13)),
                      ),
                    )
                  else
                    const BoulLogSkeleton(),

                  // コメント見出し
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                    child: Row(
                      children: [
                        Text('コメント', style: AppText.heading(size: 14)),
                        const SizedBox(width: 6),
                        Text(
                          '${_commentCount ?? tweet?.commentCount ?? ''}',
                          style: AppText.number(
                              size: 14, color: AppColors.sunabokori),
                        ),
                      ],
                    ),
                  ),

                  // 一覧
                  if (commentsState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                    )
                  else if (commentsState.error != null &&
                      commentsState.comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(commentsState.error!,
                              style: AppText.caption(size: 13)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => ref
                                .read(tweetCommentsProvider(widget.tweetId)
                                    .notifier)
                                .refresh(),
                            child: const Text('再読み込み'),
                          ),
                        ],
                      ),
                    )
                  else if (groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Center(
                        child: Text('最初のコメントを書いてみよう',
                            style: AppText.caption(size: 13)),
                      ),
                    )
                  else
                    for (final g in groups) ...[
                      _buildCommentRow(g.root,
                          isReply: false, myUserId: myUserId, tweet: tweet),
                      for (final r in g.replies)
                        _buildCommentRow(r,
                            isReply: true, myUserId: myUserId, tweet: tweet),
                    ],

                  if (!commentsState.isLoading && commentsState.hasMore)
                    Center(
                      child: TextButton(
                        onPressed: commentsState.isLoadingMore
                            ? null
                            : () => ref
                                .read(tweetCommentsProvider(widget.tweetId)
                                    .notifier)
                                .loadMore(),
                        child: Text(
                            commentsState.isLoadingMore ? '読み込み中…' : 'さらに読み込む'),
                      ),
                    ),
                ],
              ),
            ),
            _buildInputBar(commentsState.isSending, isLoggedIn: myUserId != null),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentRow(
    Comment comment, {
    required bool isReply,
    required String? myUserId,
    required Tweet? tweet,
  }) {
    if (comment.isDeleted) {
      return _DeletedCommentTile(isReply: isReply);
    }
    final canDelete = myUserId != null &&
        (myUserId == comment.userId || (tweet != null && myUserId == tweet.userId));
    return _CommentTile(
      comment: comment,
      isReply: isReply,
      canDelete: canDelete,
      onReply: () => _startReply(comment),
      onDelete: () => _confirmDelete(comment),
    );
  }

  Widget _buildInputBar(bool isSending, {required bool isLoggedIn}) {
    final text = _controller.text.trim();
    final canSend =
        isLoggedIn && !isSending && text.isNotEmpty && text.length <= kCommentMaxLength;
    final replyTo = _replyTo;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navi,
        border: Border(top: BorderSide(color: AppColors.wareme)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (replyTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
                decoration: BoxDecoration(
                  color: AppColors.setsuri,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.wareme),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '@${replyTo.userName} さんに返信',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption(
                            size: 12,
                            color: AppColors.kabeBlue,
                            weight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: _cancelReply,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close,
                            size: 16, color: AppColors.sunabokori),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  // 未ログインは入力させず、タップでログイン導線へ
                  readOnly: !isLoggedIn,
                  onTap: isLoggedIn ? null : _promptLogin,
                  enabled: !isSending,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: kCommentMaxLength,
                  textInputAction: TextInputAction.newline,
                  style: AppText.body(size: 14),
                  decoration: InputDecoration(
                    hintText: 'コメント',
                    hintStyle: AppText.body(size: 14, color: AppColors.sunabokori),
                    isDense: true,
                    // 文字数カウンタは入力中だけ出す（空のときは静かに）
                    counterText: text.isEmpty ? '' : null,
                    counterStyle:
                        AppText.caption(size: 11, color: AppColors.sunabokori),
                    filled: true,
                    fillColor: AppColors.setsuri,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide: const BorderSide(color: AppColors.wareme),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide: const BorderSide(color: AppColors.wareme),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide: const BorderSide(color: AppColors.kabeBlue),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                // maxLength のカウンタ分だけ下に余白が出るので、ボタンを入力欄に揃える
                padding: EdgeInsets.only(bottom: text.isEmpty ? 0 : 22),
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        onPressed: canSend ? _send : null,
                        icon: const Icon(Icons.send_rounded),
                        color: AppColors.kabeBlue,
                        disabledColor: AppColors.wareme,
                        tooltip: '送信',
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ルート 1 件とその返信たち
class _ThreadGroup {
  final Comment root;
  final List<Comment> replies = [];
  _ThreadGroup({required this.root});
}

/// コメント 1 件の行
class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isReply;
  final bool canDelete;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.isReply,
    required this.canDelete,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasIcon = ImageUrlValidator.isValidImageUrl(comment.userIconUrl);
    final avatarRadius = isReply ? 14.0 : 18.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(isReply ? 56 : 20, 8, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () =>
                NavigationHelper.toOtherUserProfile(context, comment.userId),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: AppColors.wareme,
              backgroundImage: hasIcon
                  ? ResizeImage(
                      CachedNetworkImageProvider(comment.userIconUrl!),
                      width: 108,
                    )
                  : null,
              child: hasIcon
                  ? null
                  : Icon(Icons.person,
                      color: AppColors.sunabokori, size: avatarRadius),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () => NavigationHelper.toOtherUserProfile(
                            context, comment.userId),
                        child: Text(
                          comment.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                              size: 13, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(comment.timeAgoDisplay,
                        style: AppText.caption(size: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: AppText.body(size: 14),
                    children: [
                      // 返信への返信は相手の名前を頭に付ける（サウナイキタイ方式）
                      if (comment.isReplyToReply &&
                          (comment.replyToUserName ?? '').isNotEmpty)
                        TextSpan(
                          text: '@${comment.replyToUserName} さん ',
                          style: AppText.body(
                              size: 14,
                              color: AppColors.kabeBlue,
                              weight: FontWeight.w600),
                        ),
                      TextSpan(text: comment.content),
                    ],
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: onReply,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.reply_rounded,
                                size: 16, color: AppColors.sunabokori),
                            const SizedBox(width: 2),
                            Text('返信',
                                style: AppText.caption(
                                    size: 12, weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (canDelete)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: const Icon(Icons.more_vert,
                            color: AppColors.sunabokori),
                        onSelected: (value) {
                          if (value == 'delete') onDelete();
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('削除する',
                                style: TextStyle(color: AppColors.holdRed)),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 削除済みコメントのプレースホルダ（下に返信が残っているときだけ表示される）
class _DeletedCommentTile extends StatelessWidget {
  final bool isReply;

  const _DeletedCommentTile({required this.isReply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isReply ? 56 : 20, 10, 12, 6),
      child: Row(
        children: [
          const Icon(Icons.block_flipped, size: 16, color: AppColors.sunabokori),
          const SizedBox(width: 8),
          Text(
            'このコメントは削除されました',
            style: AppText.caption(size: 13),
          ),
        ],
      ),
    );
  }
}
