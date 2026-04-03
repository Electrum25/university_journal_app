import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
    _showError('Заполните все поля');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final dio = await ApiClient.instance;
    final response = await dio.post('/api/auth/login', data: {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
    });

    if (response.statusCode == 200) {
  final data = response.data;
  final String userRole = data['role'] ?? 'Student';
  final String profileId = (data['businessId'] ?? '').toString();
  final String userId = (data['userId'] ?? '').toString(); // Берем userId
  
  String? finalGroupId;

  // Если зашел СТУДЕНТ, быстро узнаем его группу по userId
  if (userRole == 'Student') {
    try {
      final dio = await ApiClient.instance;
      // Используем тот путь, который у тебя работал вручную
      final profileRes = await dio.get('/api/Users/student-profile/$userId');
      finalGroupId = profileRes.data['groupId']?.toString();
      debugPrint("--- ГРУППА НАЙДЕНА АВТОМАТИЧЕСКИ: $finalGroupId ---");
    } catch (e) {
      debugPrint("Не удалось подтянуть группу при логине: $e");
    }
  }

  if (!mounted) return;

  // Теперь в HomeScreen улетает уже готовый groupId
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => HomeScreen(
        role: userRole,
        profileId: profileId, // Для Учителя остается businessId (безопасно)
        groupId: finalGroupId, // Для Студента теперь есть реальный ID группы
      ),
    ),
  );
}
  } catch (e) {
    _showError('Ошибка авторизации');
    debugPrint('Full Login Error: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_rounded, size: 100, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'University Journal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('ВОЙТИ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}