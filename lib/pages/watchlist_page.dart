import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'movie_detail.dart';

class WatchlistPage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const WatchlistPage({super.key, this.user});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  String get apiKey => AppConfig.tmdbApiKey;
  List<Map<String, dynamic>> _watchlist = [];
  Set<int> watchlistIds = {};
  bool isLoading = true;
  Map<int, bool> watchedStatus = {};

  final List<String> funnyQuotes = [
    "🍿 Popcorn ready yet?",
    "😎 This one’s gonna blow your mind!",
    "🧠 99% plot, 1% confusion",
    "💀 Don’t watch this at 3AM!",
    "🔥 Certified banger right here",
    "😭 Prepare tissues before watching",
    "👀 Bro watched it twice… still confused",
    "🎬 Cinema level: Bedroom Edition",
    "🐸 Deep meaning? Nope. Just vibes.",
    "💫 Rated E for Emotional Damage",
  ];

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = widget.user?['id']?.toString() ?? 'guest';
    final saved = prefs.getStringList('watchlist_$userId') ?? [];

    watchlistIds = saved.map((e) => int.parse(e)).toSet();
    final watchedJson = prefs.getString('watched_status_$userId') ?? '{}';
    watchedStatus = Map<int, bool>.from(json.decode(watchedJson));

    List<Map<String, dynamic>> movies = [];
    for (int movieId in watchlistIds) {
      try {
        final movieData = await fetchMovieDetail(movieId);
        movies.add(movieData);
      } catch (e) {
        print("⚠️ Error loading movie $movieId: $e");
      }
    }

    if (mounted) {
      setState(() {
        _watchlist = movies;
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> fetchMovieDetail(int movieId) async {
    final url = Uri.parse(
      "https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey&language=en-US&append_to_response=credits",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String director = "";
      List<String> stars = [];

      if (data['credits'] != null && data['credits']['crew'] != null) {
        final crew = data['credits']['crew'] as List;
        final directorData = crew.firstWhere(
          (person) => person['job'] == 'Director',
          orElse: () => {},
        );
        director = directorData['name'] ?? "";
      }

      if (data['credits'] != null && data['credits']['cast'] != null) {
        final cast = data['credits']['cast'] as List;
        stars = cast.take(3).map((actor) => actor['name'] as String).toList();
      }

      return {
        'id': data['id'],
        'title': data['title'],
        'poster_path': data['poster_path'],
        'release_date': data['release_date'],
        'vote_average': data['vote_average'],
        'overview': data['overview'],
        'runtime': data['runtime'],
        'director': director,
        'stars': stars.join(', '),
        'funny': funnyQuotes[Random().nextInt(funnyQuotes.length)],
      };
    } else {
      throw Exception("Failed to load movie details");
    }
  }

  Future<void> _removeFromWatchlist(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = widget.user?['id']?.toString() ?? 'guest';

    watchlistIds.remove(movieId);
    watchedStatus.remove(movieId);

    await prefs.setStringList(
      'watchlist_$userId',
      watchlistIds.map((e) => e.toString()).toList(),
    );

    await prefs.setString('watched_status_$userId', json.encode(watchedStatus));

    await _loadWatchlist();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("🗑️ Deleted! Movie yeeted out 💨"),
          backgroundColor: Colors.redAccent.shade200,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _markAsWatched(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = widget.user?['id']?.toString() ?? 'guest';

    setState(() {
      watchedStatus[movieId] = !(watchedStatus[movieId] ?? false);
    });

    await prefs.setString('watched_status_$userId', json.encode(watchedStatus));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          watchedStatus[movieId] == true
              ? "✅ Watched and certified cool 😎"
              : "👀 Unwatched again — maybe later?",
        ),
        backgroundColor: Colors.blueAccent.shade200,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "🎬 My Watchlist",
            style: TextStyle(
              color: Color(0xFFFFD600),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFFFD600)),
              onPressed: _loadWatchlist,
            ),
          ],
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD600)),
              )
            : RefreshIndicator(
                onRefresh: _loadWatchlist,
                color: const Color(0xFFFFD600),
                child: _watchlist.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        child: Column(
                          children: _watchlist.map((movie) {
                            final movieId = movie['id'] as int;
                            final watched = watchedStatus[movieId] ?? false;
                            final poster = movie['poster_path'];
                            final posterUrl = poster != null
                                ? "https://image.tmdb.org/t/p/w500$poster"
                                : "https://via.placeholder.com/100x150?text=No+Image";
                            final rating = (movie['vote_average'] ?? 0.0)
                                .toDouble();
                            final funny = movie['funny'];

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: watched
                                      ? Colors.greenAccent
                                      : Colors.white10,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  final fullMovie = await fetchMovieDetail(
                                    movieId,
                                  );
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MovieDetailPage(
                                          movie: fullMovie,
                                          user: widget.user,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          posterUrl,
                                          width: 85,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              movie['title'] ??
                                                  'Unknown Title 🤷‍♂️',
                                              style: const TextStyle(
                                                color: Color(0xFFFFD600),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${rating.toStringAsFixed(1)} / 10",
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  watched
                                                      ? "✅ Watched"
                                                      : "👀 Not watched",
                                                  style: TextStyle(
                                                    color: watched
                                                        ? Colors.greenAccent
                                                        : Colors.orangeAccent,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              funny,
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    watched
                                                        ? Icons.visibility
                                                        : Icons
                                                              .visibility_outlined,
                                                    color: Colors.blueAccent,
                                                    size: 22,
                                                  ),
                                                  onPressed: () =>
                                                      _markAsWatched(movieId),
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_forever,
                                                    color: Colors.redAccent,
                                                    size: 22,
                                                  ),
                                                  onPressed: () =>
                                                      _removeFromWatchlist(
                                                        movieId,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 180),
        Center(
          child: Column(
            children: [
              Icon(Icons.tv_off, size: 90, color: Colors.white30),
              SizedBox(height: 16),
              Text(
                "📭 No movies yet!",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              Text(
                "Add something before Netflix steals your time 😏",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
