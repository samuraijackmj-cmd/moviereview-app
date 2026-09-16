import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'movie_detail.dart';

class MoviePage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const MoviePage({super.key, this.user});

  @override
  State<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends State<MoviePage> {
  String get apiKey => AppConfig.tmdbApiKey;

  List trendingMovies = [];
  List nowPlayingMovies = [];
  List comingSoonMovies = [];
  List popularMovies = [];
  List topRatedMovies = [];
  Map<String, List> genreMovies = {};
  Set<int> watchlistIds = {};

  final genres = {
    "Action": 28,
    "Comedy": 35,
    "Horror": 27,
    "Animation": 16,
    "Romance": 10749,
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWatchlist();
    fetchAllMovies();
  }

  Future<void> loadWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = widget.user?['id']?.toString() ?? 'guest';
    final saved = prefs.getStringList('watchlist_$userId') ?? [];
    setState(() {
      watchlistIds = saved.map((e) => int.parse(e)).toSet();
    });
  }

  Future<void> saveWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = widget.user?['id']?.toString() ?? 'guest';
    await prefs.setStringList(
      'watchlist_$userId',
      watchlistIds.map((e) => e.toString()).toList(),
    );
  }

  void toggleWatchlist(int movieId) {
    setState(() {
      if (watchlistIds.contains(movieId)) {
        watchlistIds.remove(movieId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ ลบออกจาก Watchlist แล้ว'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        watchlistIds.add(movieId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ เพิ่มเข้า Watchlist แล้ว'),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
    saveWatchlist();
  }

  Future<void> fetchAllMovies() async {
    await Future.wait([
      fetchTrending(),
      fetchNowPlaying(),
      fetchComingSoon(),
      fetchPopularAndTopRated(),
      fetchMoviesByGenre(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> fetchTrending() async {
    final url = Uri.parse(
      "https://api.themoviedb.org/3/trending/movie/week?api_key=$apiKey",
    );
    final res = await http.get(url);
    if (res.statusCode == 200)
      trendingMovies = json.decode(res.body)['results'];
  }

  Future<void> fetchNowPlaying() async {
    final url = Uri.parse(
      "https://api.themoviedb.org/3/movie/now_playing?api_key=$apiKey&language=en-US&page=1",
    );
    final res = await http.get(url);
    if (res.statusCode == 200)
      nowPlayingMovies = json.decode(res.body)['results'];
  }

  Future<void> fetchComingSoon() async {
    final url = Uri.parse(
      "https://api.themoviedb.org/3/movie/upcoming?api_key=$apiKey&language=en-US&page=1",
    );
    final res = await http.get(url);
    if (res.statusCode == 200)
      comingSoonMovies = json.decode(res.body)['results'];
  }

  Future<void> fetchPopularAndTopRated() async {
    List popular = [];
    List top = [];
    for (int page = 1; page <= 3; page++) {
      final popularUrl = Uri.parse(
        "https://api.themoviedb.org/3/movie/popular?api_key=$apiKey&language=en-US&page=$page",
      );
      final topUrl = Uri.parse(
        "https://api.themoviedb.org/3/movie/top_rated?api_key=$apiKey&language=en-US&page=$page",
      );
      final popularRes = await http.get(popularUrl);
      final topRes = await http.get(topUrl);
      if (popularRes.statusCode == 200)
        popular.addAll(json.decode(popularRes.body)['results']);
      if (topRes.statusCode == 200)
        top.addAll(json.decode(topRes.body)['results']);
    }
    popularMovies = popular;
    topRatedMovies = top;
  }

  Future<void> fetchMoviesByGenre() async {
    for (var entry in genres.entries) {
      List results = [];
      for (int page = 1; page <= 2; page++) {
        final url = Uri.parse(
          "https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&language=en-US&with_genres=${entry.value}&page=$page",
        );
        final res = await http.get(url);
        if (res.statusCode == 200)
          results.addAll(json.decode(res.body)['results']);
      }
      genreMovies[entry.key] = results;
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.user?['username'] ?? 'ผู้ใช้';

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD600)),
            )
          : RefreshIndicator(
              onRefresh: fetchAllMovies,
              color: const Color(0xFFFFD600),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "สวัสดี, $username 👋",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "มาดูหนังใหม่กันเถอะ",
                          style: TextStyle(fontSize: 15, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildSection("🔥 Trending This Week", trendingMovies),
                  buildSection("🎬 Now Playing", nowPlayingMovies),
                  buildSection("🚀 Coming Soon", comingSoonMovies),
                  buildSection("⭐ Popular Movies", popularMovies),
                  buildSection("🏆 Top Rated", topRatedMovies),
                  const SizedBox(height: 16),
                  for (var entry in genres.entries)
                    if ((genreMovies[entry.key] ?? []).isNotEmpty)
                      buildSection(
                        "${_getGenreIcon(entry.key)} ${entry.key}",
                        genreMovies[entry.key]!,
                      ),
                ],
              ),
            ),
    );
  }

  String _getGenreIcon(String genre) {
    switch (genre) {
      case "Action":
        return "💥";
      case "Comedy":
        return "😂";
      case "Horror":
        return "👻";
      case "Animation":
        return "🎨";
      case "Romance":
        return "❤️";
      default:
        return "🎬";
    }
  }

  Widget buildSection(String title, List movies) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieListPage(
                        title: title,
                        movies: movies,
                        user: widget.user,
                        watchlistIds: watchlistIds,
                        onToggleWatchlist: toggleWatchlist,
                      ),
                    ),
                  );
                },
                icon: const Text(
                  "ทั้งหมด",
                  style: TextStyle(color: Color(0xFFFFD600), fontSize: 14),
                ),
                label: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFFD600),
                  size: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              final imageUrl = movie['poster_path'] != null
                  ? "https://image.tmdb.org/t/p/w500${movie['poster_path']}"
                  : null;
              final movieId = movie['id'];
              final isInWatchlist = watchlistIds.contains(movieId);
              return GestureDetector(
                onTap: () async {
                  final detail = await fetchMovieDetail(movie['id']);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MovieDetailPage(movie: detail, user: widget.user),
                    ),
                  );
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                height: 240,
                                width: 160,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                              )
                            : _imagePlaceholder(),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => toggleWatchlist(movieId),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: isInWatchlist
                                  ? const Color(0xFFFFD600)
                                  : Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isInWatchlist
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isInWatchlist
                                  ? Colors.black
                                  : Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 240,
      width: 160,
      color: const Color(0xFF1A1A1A),
      child: const Icon(Icons.movie, size: 40, color: Colors.white24),
    );
  }

  Future<Map<String, dynamic>> fetchMovieDetail(int movieId) async {
    final url = Uri.parse(
      "https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey&language=en-US",
    );
    final res = await http.get(url);
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception("Failed to load movie detail");
  }
}

// ===============================
// ✅ MovieListPage (สวยพอดีจอ ไม่มี overflow)
// ===============================
class MovieListPage extends StatefulWidget {
  final String title;
  final List movies;
  final Map<String, dynamic>? user;
  final Set<int> watchlistIds;
  final Function(int) onToggleWatchlist;

  const MovieListPage({
    super.key,
    required this.title,
    required this.movies,
    this.user,
    required this.watchlistIds,
    required this.onToggleWatchlist,
  });

  @override
  State<MovieListPage> createState() => _MovieListPageState();
}

class _MovieListPageState extends State<MovieListPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossCount = screenWidth < 420 ? 2 : 3;
    if (screenWidth > 700) crossCount = 4;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFFFFD600),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.58,
        ),
        itemCount: widget.movies.length,
        itemBuilder: (context, index) {
          final movie = widget.movies[index];
          final movieId = movie['id'];
          final imageUrl = movie['poster_path'] != null
              ? "https://image.tmdb.org/t/p/w500${movie['poster_path']}"
              : null;
          final isInWatchlist = widget.watchlistIds.contains(movieId);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MovieDetailPage(movie: movie, user: widget.user),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1A1A1A),
                              child: const Icon(
                                Icons.movie,
                                color: Colors.white24,
                                size: 50,
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF1A1A1A),
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white24,
                              size: 50,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        widget.onToggleWatchlist(movieId);
                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isInWatchlist
                              ? const Color(0xFFFFD600)
                              : Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isInWatchlist
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: isInWatchlist ? Colors.black : Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
