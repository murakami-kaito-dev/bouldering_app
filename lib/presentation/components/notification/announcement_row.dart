import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/announcement.dart';
import '../../../shared/utils/image_url_validator.dart';
import '../../theme/app_text.dart';
import '../../theme/app_tokens.dart';

/// お知らせ 1 件（Issue #81）
///
/// 公式アイコン（運営）またはジムアイコン＋発信元＋タイトル＋本文＋画像＋リンク
class AnnouncementRow extends StatelessWidget {
  const AnnouncementRow({super.key, required this.announcement});

  final Announcement announcement;

  Future<void> _openLink(BuildContext context) async {
    final link = announcement.linkUrl;
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('リンクを開けませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = ImageUrlValidator.isValidImageUrl(announcement.imageUrl);
    final hasLink =
        announcement.linkUrl != null && announcement.linkUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.setsuri,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.wareme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: announcement.isOfficial
                    ? AppColors.kabeBlue
                    : AppColors.wareme,
                child: Icon(
                  announcement.isOfficial ? Icons.campaign : Icons.fitness_center,
                  size: 20,
                  color: announcement.isOfficial
                      ? AppColors.onKabeBlue
                      : AppColors.sunabokori,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.senderName,
                      style: AppText.label(size: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      announcement.publishedDateDisplay,
                      style: AppText.caption(size: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(announcement.title, style: AppText.heading(size: 15)),
          const SizedBox(height: 6),
          Text(announcement.body, style: AppText.body(size: 13)),
          if (hasImage) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: CachedNetworkImage(
                imageUrl: announcement.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(
                  height: 160,
                  color: AppColors.wareme,
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          if (hasLink) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openLink(context),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('詳しく見る'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
