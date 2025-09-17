import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gym.dart';
import 'dependency_injection.dart';
import 'gym_provider.dart';

/// 他ユーザーのイキタイジム状態
class OtherUserFavoriteGymsState {
  final List<Gym> gyms;
  final bool isLoading;
  final String? error;

  const OtherUserFavoriteGymsState({
    required this.gyms,
    required this.isLoading,
    this.error,
  });

  OtherUserFavoriteGymsState copyWith({
    List<Gym>? gyms,
    bool? isLoading,
    String? error,
  }) {
    return OtherUserFavoriteGymsState(
      gyms: gyms ?? this.gyms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 他ユーザーのイキタイジムProvider
/// 
/// 役割:
/// - 指定されたユーザーのイキタイジム一覧を管理
/// - 公開情報として認証なしでアクセス
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のProvider
/// - Domain層のUseCaseを呼び出し
final otherUserFavoriteGymsProvider = FutureProvider.family<List<Gym>, String>(
  (ref, userId) async {
    final useCase = ref.read(getUserFavoriteGymsUseCaseProvider);
    final gymMap = ref.read(gymMapProvider);
    
    try {
      // APIからお気に入りジムデータを取得
      final favoriteGymsData = await useCase.execute(userId);
      
      // Map<String, dynamic>からGymエンティティに変換
      final gyms = <Gym>[];
      for (final gymData in favoriteGymsData) {
        final gymId = gymData['gym_id'] as int?;
        if (gymId != null && gymMap.containsKey(gymId)) {
          gyms.add(gymMap[gymId]!);
        }
      }
      
      return gyms;
    } catch (e) {
      // エラー時は再スローしてUI側でエラー表示
      rethrow;
    }
  },
);