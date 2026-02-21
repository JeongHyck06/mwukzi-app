class ApiConfig {
  static const String baseUrl = 'https://smiling-pearl-mwukzi-7e08f4fc.koyeb.app';

  static Uri buildUri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized');
  }
}
