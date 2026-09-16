import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  /// ✅ สมัครสมาชิก
  Future<void> _register() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage("⚠️ กรุณากรอกข้อมูลให้ครบทุกช่อง");
      return;
    }

    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      _showMessage("📧 กรุณากรอกอีเมลให้ถูกต้อง");
      return;
    }

    if (password.length < 6) {
      _showMessage("🔑 รหัสผ่านควรมีอย่างน้อย 6 ตัวอักษร");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("❌ รหัสผ่านไม่ตรงกัน");
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ เช็กว่า email นี้ถูกใช้แล้วหรือยัง
      final db = await DBHelper().database;
      final checkEmail = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (checkEmail.isNotEmpty) {
        setState(() => isLoading = false);
        _showMessage("⚠️ อีเมลนี้ถูกใช้ไปแล้ว กรุณาใช้ Login", success: false);
        return;
      }

      // ✅ สมัครสมาชิกใหม่
      final id = await DBHelper().registerUser(username, email, password);
      setState(() => isLoading = false);

      if (!mounted) return;

      if (id > 0) {
        _showMessage("✅ สมัครสมาชิกสำเร็จ! ไปล็อกอินกันเลย", success: true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        _showMessage("❌ สมัครไม่สำเร็จ กรุณาลองใหม่อีกครั้ง");
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      _showMessage("⚠️ มีข้อผิดพลาด: $e", success: false);
    }
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {bool isPassword = false, VoidCallback? onToggle}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: const Color(0xFFFFD600)),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                (label.contains("Password") || label.contains("Confirm"))
                    ? (_obscurePassword || _obscureConfirm
                        ? Icons.visibility
                        : Icons.visibility_off)
                    : Icons.visibility_off,
                color: Colors.white70,
              ),
              onPressed: onToggle,
            )
          : null,
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFFD600), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 โลโก้ / หัวข้อ
              Center(
                child: Column(
                  children: const [
                    Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 72),
                    SizedBox(height: 8),
                    Text(
                      "Create Account ✨",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD600),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Sign up to start reviewing your favorite movies!",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 👤 Username
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Username", Icons.person),
              ),
              const SizedBox(height: 16),

              // 📩 Email
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Email", Icons.email),
              ),
              const SizedBox(height: 16),

              // 🔑 Password
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  "Password",
                  Icons.lock,
                  isPassword: true,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),

              // 🔑 Confirm Password
              TextField(
                controller: confirmPasswordController,
                obscureText: _obscureConfirm,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  "Confirm Password",
                  Icons.lock_outline,
                  isPassword: true,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 28),

              // ✅ Register Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD600),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "Register",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // 🔄 กลับไปหน้า Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Color(0xFFFFD600),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
