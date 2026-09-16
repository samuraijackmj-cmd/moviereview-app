import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD600),
        title: const Text(
          "🎬 RateIt - Movie Reviews",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: "ออกจากระบบ",
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 👋 ทักทายผู้ใช้
          Text(
            "🍿 สวัสดี, ${user['username']}!",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "คุณสามารถรีวิว ค้นหา และให้คะแนนหนังที่คุณชื่นชอบได้ที่นี่ 🎥",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 25),

          // 🔥 หัวข้อหนังยอดนิยม
          const Text(
            "🔥 Popular Movies",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD600),
            ),
          ),
          const SizedBox(height: 16),

          // 🎞️ สไลด์หนัง
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _movieCard(
                  context,
                  "Black Panther",
                  "https://image.tmdb.org/t/p/w500/6ELJEzQJ3Y45HczvreC3dg0GV5R.jpg",
                ),
                _movieCard(
                  context,
                  "Avengers: Endgame",
                  "https://image.tmdb.org/t/p/w500/ulzhLuWrPK07P1YkdWQLZnQh1JL.jpg",
                ),
                _movieCard(
                  context,
                  "The Batman",
                  "https://image.tmdb.org/t/p/w500/74xTEgt7R36Fpooo50r9T25onhq.jpg",
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 📽️ ปุ่มเพิ่มเติม
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: ไปหน้า MoviePage
              },
              icon: const Icon(Icons.movie, color: Colors.black),
              label: const Text(
                "ดูหนังเพิ่มเติม",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD600),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎬 UI ของการ์ดหนัง
  Widget _movieCard(BuildContext context, String title, String imageUrl) {
    return GestureDetector(
      onTap: () {
        // TODO: ไปหน้า MovieDetail หรืออื่น ๆ
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ภาพโปสเตอร์
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                width: 160,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: Colors.grey[800],
                  child: const Icon(Icons.broken_image, color: Colors.white70, size: 40),
                ),
              ),
            ),
            // ชื่อหนัง
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
