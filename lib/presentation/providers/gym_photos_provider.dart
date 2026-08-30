import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gym_photo.dart';
import 'dependency_injection.dart';

/// ジム写真Provider（family: ジムIDごと）
///
/// autoDispose は意図的に付けていない。
/// 一度取得した写真セットをアプリ生存期間中キャッシュし、
/// 同じジムの写真をカード・地図・詳細で何度表示してもAPI呼び出しは1回にする。
/// （バックエンド側にも7日キャッシュがあり、二段構えでPlaces APIの課金を抑える）
final gymPhotosProvider =
    FutureProvider.family<GymPhotoSet, int>((ref, gymId) {
  final useCase = ref.read(getGymPhotosUseCaseProvider);
  return useCase.execute(gymId);
});
