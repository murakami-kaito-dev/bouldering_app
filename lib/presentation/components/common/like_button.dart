import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pages/login_or_signup_page.dart';
import '../../providers/dependency_injection.dart';
import '../../providers/tweet_like_sync.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';
import 'pressable.dart';

/// いいねボタン（ハート＋件数）
///
/// 役割:
/// - タップで即トグル（楽観的更新）→ API → 失敗なら元に戻して SnackBar
/// - 成功したらサーバー確定値で表示を確定し、同じ投稿を持つ全一覧へ反映する
/// - 未ログインならログイン導線（未ログイン時のマイページと同じ文言・遷移）
///
/// 表示:
/// - いいね済み = ホールド赤 `AppColors.holdRed`、未 = `AppColors.sunabokori`
/// - 押下感は既存の `Pressable`（縮んで弾む）に合わせる
class LikeButton extends ConsumerStatefulWidget {
  const LikeButton({
    super.key,
    required this.tweetId,
    required this.gymId,
    required this.authorUserId,
    required this.liked,
    required this.count,
  });

  final int tweetId;

  /// 投稿のジム（ジム別一覧への反映に使う）
  final int gymId;

  /// 投稿者（他ユーザー一覧への反映に使う）
  final String authorUserId;

  /// 一覧が持っている現在のいいね状態・件数
  final bool liked;
  final int count;

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton> {
  late bool _liked;
  late int _count;

  /// API 呼び出し中（連打防止・親からの古い値での上書き防止）
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.liked;
    _count = widget.count;
  }

  @override
  void didUpdateWidget(covariant LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 一覧側の値が変わったら追従する（別画面でのいいねが反映されたとき等）。
    // 通信中は楽観的更新を優先し、確定後に自分で揃える
    if (_busy) return;
    if (oldWidget.liked != widget.liked || oldWidget.count != widget.count) {
      _liked = widget.liked;
      _count = widget.count;
    }
  }

  Future<void> _onTap() async {
    final myUserId = ref.read(userProvider).valueOrNull?.id;
    if (myUserId == null) {
      _promptLogin();
      return;
    }
    if (_busy) return;

    final prevLiked = _liked;
    final prevCount = _count;
    final next = !prevLiked;

    // 1. 楽観的更新（即トグル）
    setState(() {
      _busy = true;
      _liked = next;
      _count = (prevCount + (next ? 1 : -1)).clamp(0, 1 << 30);
    });

    try {
      // 2. API
      final result = await ref
          .read(likeTweetUseCaseProvider)
          .execute(widget.tweetId, liked: next);
      if (!mounted) return;

      // 3. サーバー確定値で揃え、他の一覧にも反映
      setState(() {
        _liked = result.liked;
        _count = result.likedCount;
      });
      applyLikeToTweetLists(
        ref,
        tweetId: widget.tweetId,
        gymId: widget.gymId,
        authorUserId: widget.authorUserId,
        myUserId: myUserId,
        liked: result.liked,
        count: result.likedCount,
      );
    } catch (_) {
      if (!mounted) return;

      // 4. 失敗: 元に戻して知らせる
      setState(() {
        _liked = prevLiked;
        _count = prevCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next ? 'いいねに失敗しました' : 'いいねの取り消しに失敗しました'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      } else {
        _busy = false;
      }
    }
  }

  /// 未ログイン時: 未ログイン時のマイページ（UnloggedMyPage）と同じ文言・遷移で促す
  Future<void> _promptLogin() async {
    final goLogin = await showDialog<bool>(
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
          'イワノボリタイに登録すると，ボル活がさらに充実します！登録は無料！\n',
          style: TextStyle(fontSize: 14, color: AppColors.chalk),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppColors.chalk),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '新規登録 / ログイン',
              style: TextStyle(color: AppColors.kabeBlue),
            ),
          ),
        ],
      ),
    );

    if (goLogin == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginOrSignUpPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _liked ? AppColors.holdRed : AppColors.sunabokori;

    return Semantics(
      button: true,
      label: _liked ? 'いいねを取り消す' : 'いいね',
      value: '$_count',
      child: Pressable(
        pressedScale: 0.9,
        child: InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            // タップ領域を確保しつつ、カード左端の文字揃えを崩さないよう左は控えめに
            padding: const EdgeInsets.fromLTRB(2, 6, 10, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey<bool>(_liked),
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_count',
                  style: AppText.number(
                    size: 15,
                    color: color,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
