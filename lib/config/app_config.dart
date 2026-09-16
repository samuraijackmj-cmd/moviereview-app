/// 🔐 AppConfig — ดึงค่า API Key จาก --dart-define (ไม่ hardcode ใน source)
///
/// วิธีใช้งาน:
///   flutter run --dart-define=TMDB_API_KEY=your_actual_key_here
///   flutter build apk --dart-define=TMDB_API_KEY=your_actual_key_here
///
/// ถ้าไม่ส่ง --dart-define จะได้ค่า empty string และ app จะโยน error ใน debug
class AppConfig {
  AppConfig._();

  /// TMDB API Key — กำหนดผ่าน --dart-define=TMDB_API_KEY=xxx เท่านั้น
  static const String tmdbApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: '',
  );

  /// TMDB Base URL
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';

  /// TMDB Image Base URL
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  /// ตรวจสอบว่า API Key ถูกตั้งค่ามาแล้วหรือยัง
  static bool get isApiKeyConfigured => tmdbApiKey.isNotEmpty;
}
