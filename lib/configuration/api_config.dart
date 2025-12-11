enum ApiEnvironment {
  saidalo, // http://192.168.21.168:8080
  muhammadjon, // https://9e82ccd5fd23.ngrok-free.app
  local, // http://192.168.20.154:8000
}

class ApiConfig {
  static const Map<ApiEnvironment, String> _baseUrls = {
    ApiEnvironment.saidalo: 'http://192.168.21.168:8080',
    ApiEnvironment.muhammadjon: 'https://9e82ccd5fd23.ngrok-free.app',
    ApiEnvironment.local: 'http://192.168.20.154:8000',
  };

  static String getBaseUrl(ApiEnvironment env) {
    return _baseUrls[env] ?? _baseUrls[ApiEnvironment.muhammadjon]!;
  }

  static String getName(ApiEnvironment env) {
    switch (env) {
      case ApiEnvironment.saidalo:
        return 'Saidalo (Local)';
      case ApiEnvironment.muhammadjon:
        return 'Muhammadjon (ngrok)';
      case ApiEnvironment.local:
        return 'Local Dev';
    }
  }
}
