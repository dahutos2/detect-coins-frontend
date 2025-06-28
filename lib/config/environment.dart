enum AppMode { dev, std, prod }

class AppEnvironment {
  const AppEnvironment._();

  static const baseUrl = String.fromEnvironment('BASE_URL');
  static AppMode get mode =>
      _modeFromString(const String.fromEnvironment('APP_MODE'));

  static AppMode _modeFromString(String modeString) {
    return switch (modeString) {
      'dev' => AppMode.dev,
      'std' => AppMode.std,
      'prod' => AppMode.prod,
      _ => AppMode.dev,
    };
  }
}
