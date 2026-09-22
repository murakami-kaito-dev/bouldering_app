import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../shared/utils/image_url_validator.dart';
import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';

/// 通知 1 行（Issue #81）
///
/// 役割:
/// - アクターのアイコン（集約時は最大 6 個を重ねて横並び）
/// - 「A さんと他 N 名があなたのボル活をいいねしました」の一文＋経過時間
/// - 投稿の引用（ジム名＋本文冒頭。コメント・返信ならコメント本文）
/// - 未読は背景を壁ブルーでうっすら染め、左に点を置く
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation 層の表示部品（状態は持たない。タップは親へ委譲）
class NotificationRow extends StatelessWidget {
  const NotificationRow({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  /// アイコンの直径と、重ねるときの横ずらし量
  static const double _avatarSize = 36;
  static const double _avatarOverlap = 22;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread
          ? AppColors.kabeBlue.withOpacity(0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.wareme)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 未読の点（既読は同じ幅の余白で位置を揃える）
              SizedBox(
                width: 12,
                child: isUnread
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.kabeBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildAvatars(),
                        const SizedBox(width: 10),
                        _buildTypeIcon(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.sentence,
                      style: AppText.body(size: 14, height: 1.45),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.timeAgoDisplay,
                      style: AppText.caption(size: 11),
                    ),
                    if (notification.tweetId != null) ...[
                      const SizedBox(height: 8),
                      _buildQuote(),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'この投稿は削除されました',
                        style: AppText.caption(size: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// アクターのアイコン。2 人以上は少しずつ重ねて横に並べる（先頭が一番手前）
  Widget _buildAvatars() {
    final actors = notification.actors;
    if (actors.isEmpty) {
      return _avatar(null);
    }
    final count = actors.length;
    final width = _avatarSize + _avatarOverlap * (count - 1);
    return SizedBox(
      width: width,
      height: _avatarSize,
      child: Stack(
        children: [
          // 後ろから描いて先頭を最前面にする
          for (var i = count - 1; i >= 0; i--)
            Positioned(
              left: _avatarOverlap * i,
              child: _avatar(actors[i].userIconUrl),
            ),
        ],
      ),
    );
  }

  Widget _avatar(String? iconUrl) {
    final hasImage = ImageUrlValidator.isValidImageUrl(iconUrl);
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 重なりの境目が分かるように背景色で縁取る
        border: Border.all(color: AppColors.iwa, width: 2),
      ),
      child: CircleAvatar(
        backgroundColor: AppColors.wareme,
        backgroundImage: hasImage
            ? ResizeImage(
                CachedNetworkImageProvider(iconUrl!),
                width: 108, // 表示36px × 最大DPR3
              )
            : null,
        child: hasImage
            ? null
            : const Icon(Icons.person, color: AppColors.sunabokori, size: 18),
      ),
    );
  }

  /// 種別アイコン（いいね＝ホールド赤のハート、コメント・返信＝壁ブルーの吹き出し）
  Widget _buildTypeIcon() {
    switch (notification.type) {
      case AppNotificationType.like:
        return const Icon(Icons.favorite, size: 18, color: AppColors.holdRed);
      case AppNotificationType.comment:
        return const Icon(Icons.chat_bubble_outline,
            size: 18, color: AppColors.kabeBlue);
      case AppNotificationType.reply:
        return const Icon(Icons.reply, size: 18, color: AppColors.kabeBlue);
    }
  }

  /// 投稿の引用（ジム名＋本文冒頭）。コメント・返信はコメント本文を引用する
  Widget _buildQuote() {
    final quoted = notification.quotedText;
    final gymName = notification.gymName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.setsuri,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.wareme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gymName != null && gymName.trim().isNotEmpty)
            Text(
              gymName.trim(),
              style: AppText.caption(size: 11, color: AppColors.kabeBlue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (quoted.isNotEmpty) ...[
            if (gymName != null && gymName.trim().isNotEmpty)
              const SizedBox(height: 2),
            Text(
              quoted,
              style: AppText.body(size: 13, color: AppColors.sunabokori, height: 1.45),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
