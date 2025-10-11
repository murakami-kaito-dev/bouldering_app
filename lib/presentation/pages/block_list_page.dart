import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/block.dart';
import '../providers/block_provider.dart';
import '../../shared/utils/navigation_helper.dart';

/// ブロックリスト画面
///
/// 役割:
/// - ブロックしたユーザーの一覧を表示
/// - ブロック解除機能の提供
/// - 各ユーザーのプロフィール画面への遷移
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のPage
/// - Domain層のBlockUseCaseを呼び出し
/// - ユーザーからのアクションを受け取り適切なビジネスロジックを実行
class BlockListPage extends ConsumerStatefulWidget {
  const BlockListPage({super.key});

  @override
  ConsumerState<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends ConsumerState<BlockListPage> {
  // 各タイルのキーを管理
  final Map<String, GlobalKey<_BlockedUserTileState>> _tileKeys = {};

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  void _loadBlockedUsers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(blockProvider.notifier).getBlockedUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final blockState = ref.watch(blockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ブロックしたユーザー'),
        // backgroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(blockProvider.notifier).getBlockedUsers();
        },
        child: blockState.isLoading && blockState.blockedUsers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : blockState.error != null
                ? _buildErrorView(blockState.error!)
                : _buildBlockedUsersList(blockState.blockedUsers),
      ),
    );
  }

  Widget _buildBlockedUsersList(List<BlockedUser> blockedUsers) {
    if (blockedUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'ブロックしたユーザーはいません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: blockedUsers.length,
      itemBuilder: (context, index) {
        final blockedUser = blockedUsers[index];
        return _buildBlockedUserTile(blockedUser);
      },
    );
  }

  Widget _buildBlockedUserTile(BlockedUser blockedUser) {
    // ユーザーIDごとにGlobalKeyを作成・管理
    _tileKeys[blockedUser.userId] ??= GlobalKey<_BlockedUserTileState>();

    return _BlockedUserTile(
      key: _tileKeys[blockedUser.userId],
      blockedUser: blockedUser,
      onShowUnblockDialog: () => _showUnblockDialog(blockedUser),
      onShowBlockDialog: () => _showBlockDialog(blockedUser),
      onNavigateToProfile: () {
        NavigationHelper.toOtherUserProfileWithBlockCheck(
          context,
          blockedUser.userId,
          (userId) => ref.read(blockProvider.notifier).isBlocked(userId),
        );
      },
      getDisplayUserName: _getDisplayUserName,
      buildUserIcon: () => _buildUserIcon(blockedUser),
    );
  }

  /// ユーザーアイコンを構築
  Widget _buildUserIcon(BlockedUser blockedUser) {
    if (blockedUser.userIconUrl != null &&
        blockedUser.userIconUrl!.isNotEmpty) {
      return Image.network(
        blockedUser.userIconUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildFallbackIcon();
        },
      );
    }
    return _buildFallbackIcon();
  }

  /// フォールバックアイコン（画像がない場合）
  Widget _buildFallbackIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE0E0E0),
      ),
      child: const Icon(Icons.person, size: 28, color: Colors.grey),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(blockProvider.notifier).getBlockedUsers();
            },
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  void _showUnblockDialog(BlockedUser blockedUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ブロック解除の確認'),
        content: Text('${blockedUser.userName}のブロックを解除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _unblockUser(blockedUser);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('解除'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BlockedUser blockedUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ブロック追加の確認'),
        content: Text('${blockedUser.userName}をブロックユーザーに追加しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _reblockUser(blockedUser);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser(BlockedUser blockedUser) async {
    try {
      await ref.read(blockProvider.notifier).unblockUser(blockedUser.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_getDisplayUserName(blockedUser.userName)}のブロックを解除しました'),
            backgroundColor: Colors.green,
          ),
        );
        // 該当タイルのキャッシュのみクリア
        _tileKeys[blockedUser.userId]?.currentState?.clearCache();
      }
    } catch (error) {
      // デバッグ用ログ（実際のエラー内容を確認）
      print('Block removal error: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_getDisplayUserName(blockedUser.userName)}のブロック解除に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reblockUser(BlockedUser blockedUser) async {
    try {
      await ref.read(blockProvider.notifier).reblockUser(blockedUser.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_getDisplayUserName(blockedUser.userName)}をブロックに追加しました'),
            backgroundColor: Colors.blue,
          ),
        );
        // 該当タイルのキャッシュのみクリア
        _tileKeys[blockedUser.userId]?.currentState?.clearCache();
      }
    } catch (error) {
      print('Block addition error: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_getDisplayUserName(blockedUser.userName)}のブロック追加に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ユーザー名の表示用文字列を取得
  ///
  /// 7文字以上の場合は7文字+「...」で表示
  /// 7文字以下の場合はそのまま表示
  String _getDisplayUserName(String userName) {
    return (userName.length > 7) ? '${userName.substring(0, 7)}...' : userName;
  }
}

/// ブロックユーザータイル（パフォーマンス最適化版）
///
/// StatefulWidgetでFutureをキャッシュし、重複APIコールを防ぐ
class _BlockedUserTile extends ConsumerStatefulWidget {
  final BlockedUser blockedUser;
  final VoidCallback onShowUnblockDialog;
  final VoidCallback onShowBlockDialog;
  final VoidCallback onNavigateToProfile;
  final String Function(String) getDisplayUserName;
  final Widget Function() buildUserIcon;
  const _BlockedUserTile({
    super.key,
    required this.blockedUser,
    required this.onShowUnblockDialog,
    required this.onShowBlockDialog,
    required this.onNavigateToProfile,
    required this.getDisplayUserName,
    required this.buildUserIcon,
  });

  @override
  ConsumerState<_BlockedUserTile> createState() => _BlockedUserTileState();
}

class _BlockedUserTileState extends ConsumerState<_BlockedUserTile> {
  Future<bool>? _blockStatusFuture;

  Future<bool> _getBlockStatusFuture() {
    _blockStatusFuture ??=
        ref.read(blockProvider.notifier).isBlocked(widget.blockedUser.userId);
    return _blockStatusFuture!;
  }

  // 個別タイルのキャッシュクリア
  void clearCache() {
    setState(() {
      _blockStatusFuture = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onNavigateToProfile,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            // ユーザーアイコン
            Hero(
              tag: 'blocked_user_icon_${widget.blockedUser.userId}',
              child: ClipOval(
                child: widget.buildUserIcon(),
              ),
            ),
            const SizedBox(width: 12),

            // ユーザー名とブロック日時
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.getDisplayUserName(widget.blockedUser.userName),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // ブロック状態に応じた動的ボタン（キャッシュされたFuture使用）
            FutureBuilder<bool>(
              future: _getBlockStatusFuture(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 70,
                    height: 32,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(70, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'エラー',
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                }

                final isCurrentlyBlocked = snapshot.data ?? true;

                if (isCurrentlyBlocked) {
                  // ブロック中の場合：解除ボタン
                  return OutlinedButton(
                    onPressed: widget.onShowUnblockDialog,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: const Color(0xFF0056FF),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text(
                      'ブロックを解除',
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                } else {
                  // ブロック解除済みの場合：追加ボタン
                  return OutlinedButton(
                    onPressed: widget.onShowBlockDialog,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.grey,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text(
                      'ブロックする',
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
