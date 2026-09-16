import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../database/db_helper.dart';

class MovieDetailPage extends StatefulWidget {
  final Map movie;
  final Map<String, dynamic>? user;

  const MovieDetailPage({super.key, required this.movie, this.user});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  Map<String, dynamic>? movieDetail;
  bool isLoading = true;
  List<Map<String, dynamic>> _localReviews = [];
  List<Map<String, dynamic>> _apiReviews = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await fetchMovieDetail();
    await _fetchApiReviews(widget.movie['id']);
    await _loadLocalReviews();
  }

  Future<void> fetchMovieDetail() async {
    final apiKey = AppConfig.tmdbApiKey;
    final movieId = widget.movie['id'];
    final url = Uri.parse(
      "https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey&language=th-TH",
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        movieDetail = json.decode(res.body);
      }
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _fetchApiReviews(int movieId) async {
    final apiKey = AppConfig.tmdbApiKey;
    final url = Uri.parse(
      "https://api.themoviedb.org/3/movie/$movieId/reviews?api_key=$apiKey&language=en-US",
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final results = (data['results'] ?? []) as List;
        _apiReviews = results.map((r) {
          final rawRating = r['author_details']?['rating'];
          final rating = (rawRating is num)
              ? (rawRating / 2.0)
                    .toDouble() // TMDB rating 10 → 5
              : 0.0;
          return {
            'author': r['author'] ?? 'Anonymous',
            'content': r['content'] ?? '(ไม่มีข้อความ)',
            'rating': rating,
          };
        }).toList();
      }
    } catch (_) {
      _apiReviews = [];
    }
  }

  Future<void> _loadLocalReviews() async {
    final reviews = await DBHelper().getReviewsByMovieId(
      widget.movie['id'] as int,
    );
    setState(() => _localReviews = reviews.reversed.toList());
  }

  // ====== Dialog เขียนรีวิว ======
  void _showReviewDialog() {
    final TextEditingController commentCtrl = TextEditingController();
    double rating = 3.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "เขียนรีวิวของคุณ",
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "แบ่งปันความคิดเห็นของคุณ...",
                      hintStyle: TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Color(0xFF242424),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ⭐ ใช้ 5 ดาวเท่านั้น ⭐
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = (index + 1).toDouble();
                      return IconButton(
                        onPressed: () =>
                            setStateDialog(() => rating = starValue),
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFD600),
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  Text(
                    "${rating.toStringAsFixed(1)} / 5",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "ยกเลิก",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD600),
                  ),
                  onPressed: () async {
                    final comment = commentCtrl.text.trim();
                    if (comment.isEmpty) return;
                    final username = widget.user?['username'] ?? 'Guest';
                    await DBHelper().insertReview(
                      movieId: widget.movie['id'],
                      movieTitle: widget.movie['title'] ?? 'Unknown',
                      username: username,
                      comment: comment,
                      rating: rating,
                    );
                    await _loadLocalReviews();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("เพิ่มรีวิวสำเร็จ!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text(
                    "บันทึก",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ====== Dialog แก้ไขรีวิว ======
  void _showEditDialog(Map<String, dynamic> review) {
    final TextEditingController commentCtrl = TextEditingController(
      text: review['comment'],
    );
    double rating = (review['rating'] ?? 3.0).toDouble();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "แก้ไขรีวิวของคุณ",
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF242424),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = (index + 1).toDouble();
                      return IconButton(
                        onPressed: () =>
                            setStateDialog(() => rating = starValue),
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFD600),
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  Text(
                    "${rating.toStringAsFixed(1)} / 5",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "ยกเลิก",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD600),
                  ),
                  onPressed: () async {
                    await DBHelper().updateReview(
                      id: review['id'],
                      comment: commentCtrl.text.trim(),
                      rating: rating,
                    );
                    await _loadLocalReviews();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("แก้ไขรีวิวเรียบร้อย"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text(
                    "บันทึก",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =============================== UI ===============================
  @override
  Widget build(BuildContext context) {
    final movie = movieDetail ?? widget.movie;
    final posterUrl = movie['poster_path'] != null
        ? "https://image.tmdb.org/t/p/w780${movie['poster_path']}"
        : "";
    final overview = movie['overview'] ?? "ไม่มีเรื่องย่อ";
    final runtime = movie['runtime'];
    final runtimeText = (runtime is int && runtime > 0)
        ? "${runtime ~/ 60} ชม. ${runtime % 60} นาที"
        : "ไม่ระบุเวลา";
    final rating = ((movie['vote_average'] ?? 0.0) / 2)
        .toDouble(); // แปลง 10 → 5

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD600)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFD600),
        icon: const Icon(Icons.edit, color: Colors.black),
        label: const Text(
          "เขียนรีวิว",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        onPressed: _showReviewDialog,
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFFD600),
        onRefresh: _fetchAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Poster + Back Button + Overlay Title
              Stack(
                children: [
                  if (posterUrl.isNotEmpty)
                    Image.network(
                      posterUrl,
                      width: double.infinity,
                      height: 320,
                      fit: BoxFit.cover,
                    ),
                  Container(
                    height: 320,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xFF0E0E0E)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie['title'] ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFD600),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${rating.toStringAsFixed(1)} / 5",
                              style: const TextStyle(
                                color: Color(0xFFFFD600),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              runtimeText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "เรื่องย่อ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  overview,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildSectionHeader(
                icon: Icons.people,
                title: "รีวิวจากผู้ใช้ในแอป",
                count: _localReviews.length,
              ),
              const SizedBox(height: 12),
              _localReviews.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.rate_review_outlined,
                      message: "ยังไม่มีรีวิวจากผู้ใช้ในแอป",
                    )
                  : _buildReviewList(_localReviews),
              const SizedBox(height: 30),
              _buildSectionHeader(
                icon: Icons.public,
                title: "รีวิวจากผู้ชมทั่วโลก",
                count: _apiReviews.length,
              ),
              const SizedBox(height: 12),
              _apiReviews.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.forum_outlined,
                      message: "ยังไม่มีรีวิวจาก TMDB",
                    )
                  : _buildReviewList(_apiReviews),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFD600)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD600),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "$count",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.white24, size: 40),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ใช้คะแนนเต็ม 5 และแสดงดาวตรง ๆ
  Widget _buildReviewList(List<Map<String, dynamic>> reviews) {
    final currentUser = widget.user?['username'];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, i) {
        final r = reviews[i];
        final isOwner = (r['username'] == currentUser);
        final author = r['username'] ?? r['author'] ?? 'Anonymous';
        final comment = r['comment'] ?? r['content'] ?? '';
        final rating = (r['rating'] ?? 0.0).toDouble();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.white54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      author,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD600),
                        size: 18,
                      ),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFFFFD600),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 1.5,
                            ),
                            child: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: const Color(0xFFFFD600),
                              size: 18,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      color: const Color(0xFF242424),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _showEditDialog(r);
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A1A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                "ยืนยันการลบรีวิว?",
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                "คุณต้องการลบรีวิวนี้หรือไม่?",
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text(
                                    "ยกเลิก",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    "ลบ",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await DBHelper().deleteReview(r['id']);
                            setState(() => _localReviews.removeAt(i));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("ลบรีวิวแล้ว"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.amber, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "แก้ไข",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text("ลบ", style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                comment,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }
}
