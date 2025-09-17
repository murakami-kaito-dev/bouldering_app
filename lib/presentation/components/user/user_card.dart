import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user.dart';
import '../../../shared/utils/navigation_helper.dart';

/// ユーザーカードコンポーネント
/// 
/// 役割:
/// - ユーザー情報の統一された表示
/// - フォロー・アンフォロー機能
/// - ユーザープロフィールページへの遷移
/// - 簡易プロフィール情報の表示
class UserCard extends ConsumerWidget {
  final User user;
  final VoidCallback? onTap;
  final bool showFollowButton;
  final bool isFollowing;
  final bool showFullInfo;

  const UserCard({
    super.key,
    required this.user,
    this.onTap,
    this.showFollowButton = true,
    this.isFollowing = false,
    this.showFullInfo = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap ?? () => NavigationHelper.toOtherUserProfile(context, user.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserHeader(context, ref),
              if (showFullInfo && user.hasProfile) ...[
                const SizedBox(height: 12),
                _buildUserIntroduction(context),
              ],
              if (showFullInfo) ...[
                const SizedBox(height: 12),
                _buildUserStats(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: (user.userIconUrl != null && user.userIconUrl!.isNotEmpty)
              ? NetworkImage(user.userIconUrl!)
              : null,
          child: (user.userIconUrl == null || user.userIconUrl!.isEmpty)
              ? const Icon(Icons.person, size: 30)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.userName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (user.favoriteGym != null && user.favoriteGym!.isNotEmpty)
                _buildFavoriteGymInfo(context),
              if (user.boulderingYearsExperience != null)
                _buildExperienceInfo(context),
            ],
          ),
        ),
        if (showFollowButton)
          _buildFollowButton(context, ref),
      ],
    );
  }

  Widget _buildFavoriteGymInfo(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            user.favoriteGym!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceInfo(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.timeline, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          'ボルダリング歴: ${user.boulderingYearsExperience}年',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 32,
      child: isFollowing
          ? OutlinedButton(
              onPressed: () => _toggleFollow(ref),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: const Text('フォロー中'),
            )
          : ElevatedButton(
              onPressed: () => _toggleFollow(ref),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('フォロー'),
            ),
    );
  }

  Widget _buildUserIntroduction(BuildContext context) {
    if (user.userIntroduce == null || user.userIntroduce!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        user.userIntroduce!,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildUserStats(BuildContext context) {
    return Row(
      children: [
        _buildStatChip(
          context: context,
          icon: Icons.person,
          label: '性別',
          value: user.genderDisplay,
          color: Colors.purple,
        ),
        if (user.birthday != null) ...[
          const SizedBox(width: 8),
          _buildStatChip(
            context: context,
            icon: Icons.cake,
            label: '年齢',
            value: '${_calculateAge(user.birthday!)}歳',
            color: Colors.green,
          ),
        ],
        if (user.boulStartDate != null) ...[
          const SizedBox(width: 8),
          _buildStatChip(
            context: context,
            icon: Icons.fitness_center,
            label: '開始',
            value: '${user.boulStartDate!.year}年',
            color: Colors.blue,
          ),
        ],
      ],
    );
  }

  Widget _buildStatChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month || 
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  void _toggleFollow(WidgetRef ref) async {
    try {
      // TODO: Implement follow/unfollow functionality
      // if (isFollowing) {
      //   await ref.read(favoriteProvider.notifier).unfollowUser(user.id);
      // } else {
      //   await ref.read(favoriteProvider.notifier).followUser(user.id);
      // }
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }
}