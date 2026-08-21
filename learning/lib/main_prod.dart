import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'main.dart';
import 'topics/05_env_switching/env_config.dart';

/// トピック05用の「本番」エントリポイント。
/// 本体の lib/main_prod.dart に対応する。
///
/// 実行: flutter run -t lib/main_prod.dart --dart-define=ENVIRONMENT=prod
void main() {
  EnvConfig.setEnvironment(Env.prod); // ①エントリポイントで環境を確定
  runApp(const ProviderScope(child: LearningApp()));
}
