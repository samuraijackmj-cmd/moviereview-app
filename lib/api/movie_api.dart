import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class MovieApi {
  static String get _apiKey => AppConfig.tmdbApiKey;
  static const String _baseUrl = AppConfig.tmdbBaseUrl;

  // 📌 ดึง popular movies
  static Future<List<dynamic>> fetchPopularMovies() async {
    final url = Uri.parse("$_baseUrl/movie/popular?api_key=$_apiKey&language=en-US&page=1");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'];
    } else {
      throw Exception("Failed to load popular movies");
    }
  }

  // 📌 ดึงรายละเอียดหนัง
  static Future<Map<String, dynamic>> fetchMovieDetail(int movieId) async {
    final url = Uri.parse("$_baseUrl/movie/$movieId?api_key=$_apiKey&language=en-US");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load movie details");
    }
  }
}
