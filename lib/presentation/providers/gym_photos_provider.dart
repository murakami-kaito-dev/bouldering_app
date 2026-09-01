import 'dart:async';

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
    FutureProvider.family<GymPhotoSet, int>((ref, gymId) async {
  final useCase = ref.read(getGymPhotosUseCaseProvider);
  try {
    return await useCase.execute(gymId);
  } catch (e) {
    // 取得失敗（オフライン等）をそのまま放置すると、autoDispose無しのため
    // 「写真なし」がアプリ再起動まで固定されてしまう。
    // 一定時間後にキャッシュを破棄し、通信回復後にその画面を再表示（または
    // 表示中なら自動リビルド）した際に取得し直せるようにする
    final timer = Timer(const Duration(seconds: 30), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
    rethrow;
  }
});
