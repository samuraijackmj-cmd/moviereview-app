import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../database/db_helper.dart';

class ReviewPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  const ReviewPage({super.key, this.user});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  List<Map<String, dynamic>> _localReviews = [];
  List<Map<String, dynamic>> _apiReviews = [];
  bool isLoading = true;

  String get apiKey => AppConfig.tmdbApiKey;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  // ✅ โหลดข้อมูลทั้งสองฝั่ง (Local + TMDB)
  Future<void> _fetchAll() async {
    setState(() => isLoading = true);

    final db = DBHelper();
    final local = await db.getAllReviews();
    final api = await _fetchGlobalReviews();

    setState(() {
      _localReviews = local.reversed.toList();
      _apiReviews = api;
      isLoading = false;
    });
  }

  // ✅ โหลดอัตโนมัติเมื่อกลับมาหน้านี้ (หลังจากเพิ่มรีวิว)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchAll();
  }

  // ✅ โหลดรีวิวจาก TMDB API (สุ่มจากหนังดัง ๆ)
  Future<List<Map<String, dynamic>>> _fetchGlobalReviews() async {
    List<Map<String, dynamic>> allReviews = [];
    try {
      final trendingUrl = Uri.parse(
        "https://api.themoviedb.org/3/trending/movie/week?api_key=$apiKey",
      );
      final trendingRes = await http.get(trendingUrl);
      if (trendingRes.statusCode == 200) {
        final trendingData = json.decode(trendingRes.body);
        final movies = trendingData['results'] as List;

        // โหลดรีวิวจากหนังยอดนิยม 5 เรื่องแรก
        for (var m in movies.take(5)) {
          final id = m['id'];
          final title = m['title'] ?? "Unknown";
          final url = Uri.parse(
            "https://api.themoviedb.org/3/movie/$id/reviews?api_key=$apiKey&language=en-US",
          );
          final res = await http.get(url);
          if (res.statusCode == 200) {
            final data = json.decode(res.body);
            final reviews = (data['results'] ?? []) as List;
            for (var r in reviews.take(2)) {
              final rawRating = r['author_details']?['rating'];
              final rating = (rawRating is int)
                  ? rawRating.toDouble()
                  : (rawRating is double ? rawRating : 0.0);
              allReviews.add({
                'movie_title': title,
                'username': r['author'] ?? "Anonymous",
                'comment': r['content'] ?? '',
                'rating': rating,
                'source': 'TMDB',
              });
            }
          }
        }
      }
    } catch (_) {
      // ถ้าโหลด TMDB ไม่ได้ก็ไม่ต้อง error
    }
    return allReviews;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 3,
        title: const Row(
          children: [
            Icon(Icons.reviews, color: Color(0xFFFFD600)),
            SizedBox(width: 10),
            Text(
              "⭐ รีวิวทั้งหมด",
              style: TextStyle(
                color: Color(0xFFFFD600),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _fetchAll,
            icon: const Icon(Icons.refresh, color: Color(0xFFFFD600)),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD600)),
            )
          : RefreshIndicator(
              onRefresh: _fetchAll,
              color: const Color(0xFFFFD600),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      "💛 รีวิวจากผู้ใช้ RateIt",
                      _localReviews.length,
                    ),
                    const SizedBox(height: 10),
                    _localReviews.isEmpty
                        ? _buildEmptyState("ยังไม่มีรีวิวในเครื่องเลย 🎬")
                        : _buildReviewList(_localReviews, local: true),

                    const SizedBox(height: 28),

                    _buildSectionHeader(
                      "🌍 รีวิวจากผู้ชมทั่วโลก (TMDB)",
                      _apiReviews.length,
                    ),
                    const SizedBox(height: 10),
                    _apiReviews.isEmpty
                        ? _buildEmptyState("ยังไม่มีรีวิวจาก TMDB")
                        : _buildReviewList(_apiReviews, local: false),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD600),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$count รีวิว",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ แสดงรีวิวแต่ละรายการ
  Widget _buildReviewList(
    List<Map<String, dynamic>> reviews, {
    bool local = true,
  }) {
    return Column(
      children: reviews.map((r) {
        final title = r['movie_title'] ?? "ไม่ทราบชื่อเรื่อง";
        final username = r['username'] ?? "Anonymous";
        final rating = (r['rating'] ?? 0.0).toDouble();
        final comment = r['comment'] ?? "";
        final isTMDB = r['source'] == 'TMDB';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTMDB
                  ? Colors.blueAccent.withOpacity(0.6)
                  : const Color(0xFF00FF66),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔸 ชื่อหนัง
              Row(
                children: [
                  const Icon(Icons.movie, color: Color(0xFFFFD600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFFFD600),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isTMDB
                          ? Colors.blueAccent.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isTMDB ? Colors.blueAccent : Colors.greenAccent,
                      ),
                    ),
                    child: Text(
                      isTMDB ? "TMDB" : "LOCAL",
                      style: TextStyle(
                        color: isTMDB ? Colors.blueAccent : Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 🔸 ผู้รีวิว + คะแนน
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.white54),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFD600),
                    size: 18,
                  ),
                  Text(
                    "${rating.toStringAsFixed(1)}/10",
                    style: const TextStyle(
                      color: Color(0xFFFFD600),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 🔸 เนื้อหารีวิว
              Text(
                comment,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ✅ กรณีไม่มีรีวิว
  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.rate_review_outlined,
              color: Colors.white24,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
