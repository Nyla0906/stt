enum ApiEnvironment {
  saidalo, // http://192.168.21.168:8080
  muhammadjon, // https://9e82ccd5fd23.ngrok-free.app
}

class ApiConfig {
  static const Map<ApiEnvironment, String> _baseUrls = {
    ApiEnvironment.saidalo: 'http://192.168.21.168:8080',
    ApiEnvironment.muhammadjon: 'https://376be74a7b47.ngrok-free.app',
  };

  static const Map<ApiEnvironment, String> _endpoints = {
    ApiEnvironment.saidalo: '/api/voice/upload',
    ApiEnvironment.muhammadjon: '/api/voice/upload',
  };

  static String getBaseUrl(ApiEnvironment env) {
    return _baseUrls[env] ?? _baseUrls[ApiEnvironment.muhammadjon]!;
  }

  static String getEndpoint(ApiEnvironment env) {
    return _endpoints[env] ?? '/api/v1/transcribe';
  }

  static String getName(ApiEnvironment env) {
    switch (env) {
      case ApiEnvironment.saidalo:
        return 'Saidalo (Local)';
      case ApiEnvironment.muhammadjon:
        return 'Muhammadjon (ngrok)';
    }
  }
}
