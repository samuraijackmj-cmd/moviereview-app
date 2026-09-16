import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'movie_detail.dart'; // ✅ ให้ชื่อไฟล์ตรงกับของจริง

class SearchPage extends StatefulWidget {
  final Map<String, dynamic>? user; // ✅ รับข้อมูลผู้ใช้จากหน้า MainPage

  const SearchPage({super.key, this.user});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  // 🔍 ฟังก์ชันค้นหาภาพยนตร์จาก TMDB API
  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    final apiKey = AppConfig.tmdbApiKey;
    final url = Uri.parse(
      "https://api.themoviedb.org/3/search/movie?api_key=$apiKey&language=th-TH&query=$query",
    );

    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        _results = data['results'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.user?['username'] ?? 'ผู้ใช้'; // ✅ ทดสอบว่ารับมาถูกมั้ย

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("🔎 ค้นหาภาพยนตร์ ($username)"), // ✅ แสดง username ไว้ทดสอบ
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 ช่องค้นหา
            TextField(
              controller: _searchCtrl,
              onSubmitted: _searchMovies,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "พิมพ์ชื่อหนังที่ต้องการค้นหา...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📦 แสดงผลการค้นหา
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFD600)),
                ),
              )
            else if (_results.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    "🔍 ค้นหาภาพยนตร์ที่คุณต้องการด้านบน",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final movie = _results[index];
                    final poster = movie['poster_path'] != null
                        ? "https://image.tmdb.org/t/p/w500${movie['poster_path']}"
                        : "https://via.placeholder.com/100x150?text=No+Image";

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        // ✅ ส่ง user ไปหน้า MovieDetailPage
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailPage(
                                movie: movie,
                                user: widget.user, // ✅ ส่งต่อ user
                              ),
                            ),
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🖼️ โปสเตอร์
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                              child: Image.network(
                                poster,
                                width: 100,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),

                            // 📃 ข้อมูลหนัง
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movie['title'] ?? "ไม่มีชื่อ",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "📅 ${movie['release_date']?.toString().split('-')[0] ?? 'ไม่ทราบปี'}",
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      movie['overview']?.toString().isNotEmpty ==
                                              true
                                          ? movie['overview']
                                          : "ไม่มีเรื่องย่อ",
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 14),
                                    ),
                                  ],
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
          ],
        ),
      ),
    );
  }
}
