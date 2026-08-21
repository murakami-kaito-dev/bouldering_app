/// 環境設定（本体の lib/shared/config/environment_config.dart のミニ版）
///
/// 本体では main_dev.dart / main_prod.dart が起動時に
/// EnvironmentConfig.setEnvironment() を呼んで環境を確定させる。
enum Env { dev, prod }

class EnvConfig {
  static Env _env = Env.dev;
  static Env get env => _env;

  static void setEnvironment(Env e) => _env = e;

  /// 接続先はエントリポイント（系統A）で決まる
  static String get apiBaseUrl => switch (_env) {
        Env.dev => 'https://api-dev.example.com/api',
        Env.prod => 'https://api-prod.example.com/api',
      };
}

/// --dart-define の読み取り（本体の lib/shared/config/app_env.dart のミニ版）
///
/// String.fromEnvironment は「コンパイル時」に確定する。
/// flutter run --dart-define=ENVIRONMENT=prod のように渡す。
class AppEnv {
  static const environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  /// 本体の AppEnv.validateConsistency() 相当:
  /// エントリポイント（系統A）と dart-define（系統B）が一致しているか。
  /// 本体ではこの2系統のズレが「本番API × 開発用GCS鍵」のような
  /// 環境混在事故につながることが調査で判明している。
  static bool isConsistentWith(Env entryPointEnv) =>
      environment == entryPointEnv.name;
}
