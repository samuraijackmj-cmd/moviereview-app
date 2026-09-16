import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  // ========================= 🔐 PASSWORD HASHING =========================

  /// แปลง password เป็น SHA-256 hash ก่อนบันทึกหรือเปรียบเทียบ
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  // ========================= ⚙️ INITIAL SETUP =========================

  /// ✅ สร้างฐานข้อมูลในโฟลเดอร์ปลอดภัย
  Future<Database> _initDB() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = join(dir.path, 'rateit.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// ✅ สร้างตารางทั้งหมด (ตอนติดตั้งครั้งแรก)
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        profile_image TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE watchlist (
        id INTEGER PRIMARY KEY,
        title TEXT,
        poster TEXT,
        release_date TEXT,
        vote REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movie_id INTEGER,
        movie_title TEXT,
        username TEXT,
        comment TEXT,
        rating REAL,
        created_at TEXT
      )
    ''');
  }

  /// ✅ อัปเกรดฐานข้อมูลเมื่อ version เปลี่ยน
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS watchlist (
          id INTEGER PRIMARY KEY,
          title TEXT,
          poster TEXT,
          release_date TEXT,
          vote REAL
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reviews (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          movie_id INTEGER,
          movie_title TEXT,
          username TEXT,
          comment TEXT,
          rating REAL,
          created_at TEXT
        )
      ''');
    }
  }

  // ========================= 👤 USERS =========================

  Future<int> registerUser(
    String username,
    String email,
    String password,
  ) async {
    final db = await database;
    return await db.insert('users', {
      'username': username.trim(),
      'email': email.trim(),
      'password': hashPassword(password), // 🔐 เก็บเป็น SHA-256 hash เสมอ
      'profile_image': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email.trim(), hashPassword(password)], // 🔐 เปรียบเทียบกับ hash
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<int> updateUser(
    int id,
    String username,
    String email, {
    String? profileImage,
  }) async {
    final db = await database;
    return await db.update(
      'users',
      {
        'username': username.trim(),
        'email': email.trim(),
        'profile_image': profileImage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ========================= 🎬 WATCHLIST =========================

  Future<int> addToWatchlist(Map<String, dynamic> movie) async {
    final db = await database;
    return await db.insert(
      'watchlist',
      movie,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> removeFromWatchlist(int id) async {
    final db = await database;
    return await db.delete('watchlist', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isInWatchlist(int id) async {
    final db = await database;
    final result = await db.query(
      'watchlist',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getWatchlist() async {
    final db = await database;
    return await db.query('watchlist', orderBy: 'id DESC');
  }

  // ========================= ⭐ REVIEWS =========================

  /// เพิ่มรีวิวใหม่
  Future<int> insertReview({
    required int movieId,
    required String movieTitle,
    required String username,
    required String comment,
    required double rating,
  }) async {
    final db = await database;
    return await db.insert('reviews', {
      'movie_id': movieId,
      'movie_title': movieTitle.trim(),
      'username': username.trim(),
      'comment': comment.trim(),
      'rating': rating,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// ดึงรีวิวทั้งหมด (เรียงใหม่สุดก่อน)
  Future<List<Map<String, dynamic>>> getAllReviews() async {
    final db = await database;
    return await db.query('reviews', orderBy: 'created_at DESC');
  }

  /// ดึงรีวิวเฉพาะหนัง
  Future<List<Map<String, dynamic>>> getReviewsByMovieId(int movieId) async {
    final db = await database;
    return await db.query(
      'reviews',
      where: 'movie_id = ?',
      whereArgs: [movieId],
      orderBy: 'created_at DESC',
    );
  }

  /// อัปเดตรีวิว
  Future<int> updateReview({
    required int id,
    required String comment,
    required double rating,
  }) async {
    final db = await database;
    return await db.update(
      'reviews',
      {'comment': comment.trim(), 'rating': rating},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ลบรีวิวเดียว
  Future<int> deleteReview(int reviewId) async {
    final db = await database;
    return await db.delete('reviews', where: 'id = ?', whereArgs: [reviewId]);
  }

  /// ลบรีวิวทั้งหมดของหนังเรื่องหนึ่ง
  Future<int> deleteReviewsByMovieId(int movieId) async {
    final db = await database;
    return await db.delete(
      'reviews',
      where: 'movie_id = ?',
      whereArgs: [movieId],
    );
  }

  /// นับจำนวนรีวิวของหนัง
  Future<int> getReviewCount(int movieId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reviews WHERE movie_id = ?',
      [movieId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// คำนวณคะแนนเฉลี่ยของหนัง
  Future<double> getAverageRating(int movieId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(rating) as avg_rating FROM reviews WHERE movie_id = ?',
      [movieId],
    );
    if (result.isNotEmpty && result.first['avg_rating'] != null) {
      return (result.first['avg_rating'] as num).toDouble();
    }
    return 0.0;
  }

  /// ดึงรีวิวของผู้ใช้เฉพาะคน
  Future<List<Map<String, dynamic>>> getUserReviews(String username) async {
    final db = await database;
    return await db.query(
      'reviews',
      where: 'username = ?',
      whereArgs: [username.trim()],
      orderBy: 'created_at DESC',
    );
  }
}
