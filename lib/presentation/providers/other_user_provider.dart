import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import 'dependency_injection.dart';

/// 他ユーザー情報取得プロバイダー
/// 
/// 役割:
/// - 指定されたユーザーIDの他ユーザー情報を取得
/// - ログイン中のユーザー以外のユーザー情報を提供
/// 
/// クリーンアーキテクチャにおける位置づき:
/// - Presentation層のProvider
/// - Domain層のRepositoryを通してデータを取得
final otherUserProvider = 
    FutureProvider.autoDispose.family<User?, String>((ref, userId) async {
  try {
    final userRepository = ref.read(userRepositoryProvider);
    final user = await userRepository.getUserProfile(userId);  // 公開プロフィール取得
    return user;
  } catch (e) {
    // エラー時はnullを返す
    return null;
  }
});