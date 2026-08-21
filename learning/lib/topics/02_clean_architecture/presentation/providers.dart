import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/get_gyms_usecase.dart';
import '../domain/gym.dart';
import '../infrastructure/gym_datasource.dart';
import '../infrastructure/gym_repository_impl.dart';

/// プレゼンテーション層: DI（依存性注入）の配線
///
/// 本体の対応箇所: lib/presentation/providers/dependency_injection.dart
///   （本体は40超のProviderで datasource → repository → usecase を配線している）
///
/// 要点:
/// - 配線はここに集約する。UseCase の中で `GymRepositoryImpl()` を
///   new しない（それをすると抽象に依存した意味がなくなる）
/// - テスト時は override で Fake に差し替えられるのが Riverpod DI の利点

final gymDataSourceProvider = Provider((ref) => GymDataSource());

final gymRepositoryProvider =
    Provider((ref) => GymRepositoryImpl(ref.read(gymDataSourceProvider)));

final getGymsUseCaseProvider =
    Provider((ref) => GetGymsUseCase(ref.read(gymRepositoryProvider)));

/// 画面が watch する Provider。FutureProvider が
/// ローディング/成功/失敗を AsyncValue として表現してくれる
final gymListProvider = FutureProvider<List<Gym>>(
    (ref) => ref.read(getGymsUseCaseProvider).execute());
