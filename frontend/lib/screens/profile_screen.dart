import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/travel_plan_service.dart';
import 'plan_wizard_screen.dart';
import 'plan_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _authService;
  bool _isLogin = true;

  // Controller'lar
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _regFirstNameController = TextEditingController();
  final _regLastNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regFirstNameController.dispose();
    _regLastNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: StreamBuilder<AuthState>(
          stream: _authService.authStateChanges,
          builder: (context, snapshot) {
            final user = _authService.currentUser;
            if (user != null) {
              return _buildProfileView(user);
            }
            return _isLogin ? _buildLoginView() : _buildRegisterView();
          },
        ),
      ),
    );
  }

  // === GİRİŞ EKRANI ===
  Widget _buildLoginView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.login, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Giriş Yap',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Hesabınıza giriş yapın',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 32),

          // Email
          _buildTextField(
            controller: _loginEmailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Şifre
          _buildTextField(
            controller: _loginPasswordController,
            label: 'Şifre',
            icon: Icons.lock_outline,
            obscure: true,
          ),
          const SizedBox(height: 24),

          // Giriş butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _handleLogin(_loginEmailController.text.trim(), _loginPasswordController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Giriş Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),

          // Google ile giriş
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _handleGoogleLogin,
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Google ile Giriş', style: TextStyle(fontSize: 15)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Kayıt ol linki
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Hesabınız yok mu? ', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              GestureDetector(
                onTap: () => setState(() => _isLogin = false),
                child: const Text(
                  'Kayıt Ol',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === KAYIT EKRANI ===
  Widget _buildRegisterView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person_add, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Kayıt Ol',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni hesap oluşturun',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 32),

          // İsim
          _buildTextField(
            controller: _regFirstNameController,
            label: 'İsim',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),

          // Soyisim
          _buildTextField(
            controller: _regLastNameController,
            label: 'Soyisim',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),

          // Email
          _buildTextField(
            controller: _regEmailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Şifre
          _buildTextField(
            controller: _regPasswordController,
            label: 'Şifre',
            icon: Icons.lock_outline,
            obscure: true,
          ),
          const SizedBox(height: 24),

          // Kayıt butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _handleRegister(
                _regFirstNameController.text.trim(),
                _regLastNameController.text.trim(),
                _regEmailController.text.trim(),
                _regPasswordController.text,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Kayıt Ol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),

          // Google ile kayıt
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _handleGoogleLogin,
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Google ile Kayıt', style: TextStyle(fontSize: 15)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Giriş yap linki
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Zaten hesabınız var mı? ', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              GestureDetector(
                onTap: () => setState(() => _isLogin = true),
                child: const Text(
                  'Giriş Yap',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === PROFİL EKRANI (Giriş yapılmış) ===
  Widget _buildProfileView(User user) {
    // Google OAuth: 'full_name' veya 'name' gönderir
    // Email/şifre kayıt: 'first_name' + 'last_name' gönderir
    final meta = user.userMetadata ?? {};
    final fullName = meta['full_name'] ?? meta['name'] ??
        '${meta['first_name'] ?? ''} ${meta['last_name'] ?? ''}'.trim();
    final email = user.email ?? '';
    final initials = fullName.isNotEmpty
        ? fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
            ),
            child: Center(
              child: Text(initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 14),
          Text(fullName.isNotEmpty ? fullName : 'Kullanıcı',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(email, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 24),

          // Planlanan Seyahatlerim
          _buildMyPlansSection(),
          const SizedBox(height: 24),

          // Çıkış butonu
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Çıkış Yap', style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPlansSection() {
    final planService = TravelPlanService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.map_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Planlanan Seyahatlerim', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanWizardScreen()));
                if (result == true) setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Yeni', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: planService.getMyPlans(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ));
            }
            final plans = snapshot.data ?? [];
            if (plans.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(Icons.flight_takeoff, size: 32, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text('Henüz plan yok', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                  ],
                ),
              );
            }
            return Column(
              children: plans.map((plan) => _buildPlanCard(plan, planService)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, TravelPlanService planService) {
    final title = plan['title'] ?? '';
    final date = plan['departure_date'] ?? '';
    final flight = plan['flight_info'] as Map<String, dynamic>?;
    final places = plan['selected_places'] as List<dynamic>?;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan)));
        if (result == true) setState(() {});
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flight, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 8),
            Text('📅 $date', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            if (flight != null)
              Text('✈️ ${flight['airline']} - ${flight['departure_time']} (${flight['price']?.toStringAsFixed(0) ?? '?'} ₺)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            if (places != null && places.isNotEmpty)
              Text('📍 ${places.length} gezilecek yer seçildi',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  // === HANDLERS ===

  Future<void> _handleLogin(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email ve şifre gerekli!');
      return;
    }
    try {
      await _authService.signIn(email: email, password: password);
      _showSnackBar('Giriş başarılı!');
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Bir hata oluştu: $e');
    }
  }

  Future<void> _handleRegister(String firstName, String lastName, String email, String password) async {
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Tüm alanları doldurun!');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Şifre en az 6 karakter olmalı!');
      return;
    }
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      if (response.user != null && response.session != null) {
        _showSnackBar('Kayıt başarılı! Hoş geldiniz.');
      } else if (response.user != null && response.session == null) {
        _showSnackBar('Kayıt başarılı! Email adresinizi doğrulayın.');
        setState(() => _isLogin = true);
      } else {
        _showSnackBar('Kayıt yapılamadı. Tekrar deneyin.');
      }
    } on AuthException catch (e) {
      _showSnackBar('Hata: ${e.message}');
    } catch (e) {
      _showSnackBar('Bir hata oluştu: $e');
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _showSnackBar('Google giriş hatası: $e');
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    _showSnackBar('Çıkış yapıldı.');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return '-';
    }
  }
}
