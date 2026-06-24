import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _loading = false;
  late Future<List<Map<String, dynamic>>> _plansFuture;

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
    _reloadPlans();
  }

  void _reloadPlans() {
    setState(() {
      _plansFuture = TravelPlanService().getMyPlans();
    });
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
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
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
      child: Column(
        children: [
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF5374FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person_rounded, size: 36, color: Color(0xFF5374FF)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Giriş Yap',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hesabınıza giriş yaparak devam edin',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),

          // Form card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTextField(
                  controller: _loginEmailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _loginPasswordController,
                  label: 'Şifre',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _handleLogin(
                      _loginEmailController.text.trim(),
                      _loginPasswordController.text,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5374FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Giriş Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 14),
                // Google
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _handleGoogleLogin,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                    label: const Text('Google ile Giriş', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Hesabınız yok mu? ', style: TextStyle(color: Color(0xFF64748B))),
              GestureDetector(
                onTap: () => setState(() => _isLogin = false),
                child: const Text(
                  'Kayıt Ol',
                  style: TextStyle(color: Color(0xFF5374FF), fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 120),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person_add_rounded, size: 36, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Kayıt Ol',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yeni hesap oluşturun',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _regFirstNameController,
                        label: 'İsim',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _regLastNameController,
                        label: 'Soyisim',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _regEmailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _regPasswordController,
                  label: 'Şifre (min 6 karakter)',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _handleRegister(
                      _regFirstNameController.text.trim(),
                      _regLastNameController.text.trim(),
                      _regEmailController.text.trim(),
                      _regPasswordController.text,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Kayıt Ol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _handleGoogleLogin,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                    label: const Text('Google ile Kayıt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Zaten hesabınız var mı? ', style: TextStyle(color: Color(0xFF64748B))),
              GestureDetector(
                onTap: () => setState(() => _isLogin = true),
                child: const Text(
                  'Giriş Yap',
                  style: TextStyle(color: Color(0xFF5374FF), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === PROFİL EKRANI ===
  Widget _buildProfileView(User user) {
    final meta = user.userMetadata ?? {};
    final fullName = meta['full_name'] ?? meta['name'] ??
        '${meta['first_name'] ?? ''} ${meta['last_name'] ?? ''}'.trim();
    final email = user.email ?? '';
    final initials = fullName.isNotEmpty
        ? fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Profile header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5374FF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF5374FF)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  fullName.isNotEmpty ? fullName : 'Kullanıcı',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // My Plans
          _buildMyPlansSection(),
          const SizedBox(height: 20),

          // Settings section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingsItem(Icons.notifications_outlined, 'Bildirimler', onTap: () {}),
                _buildDivider(),
                _buildSettingsItem(Icons.language_rounded, 'Dil', trailing: 'Türkçe', onTap: () {}),
                _buildDivider(),
                _buildSettingsItem(Icons.help_outline_rounded, 'Yardım', onTap: () {}),
                _buildDivider(),
                _buildSettingsItem(Icons.info_outline_rounded, 'Hakkında', onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Çıkış Yap', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
                foregroundColor: const Color(0xFFEF4444),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, {String? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
            ),
            if (trailing != null)
              Text(trailing, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
    );
  }

  Widget _buildMyPlansSection() {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_rounded, size: 20, color: Color(0xFF5374FF)),
              const SizedBox(width: 8),
              const Text('Seyahat Planlarım', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanWizardScreen()));
                  if (result == true) _reloadPlans();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5374FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: Color(0xFF5374FF)),
                      SizedBox(width: 4),
                      Text('Yeni', style: TextStyle(color: Color(0xFF5374FF), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _plansFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFF5374FF), strokeWidth: 2),
                  ),
                );
              }
              final plans = snapshot.data ?? [];
              if (plans.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.flight_takeoff_rounded, size: 32, color: Color(0xFF94A3B8)),
                      SizedBox(height: 8),
                      Text('Henüz plan oluşturmadınız', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),
                );
              }
              return Column(
                children: plans.map((plan) => _buildPlanCard(plan)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final title = plan['title'] ?? '';
    final date = plan['departure_date'] ?? '';
    final flight = plan['flight_info'] as Map<String, dynamic>?;
    final places = plan['selected_places'] as List<dynamic>?;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan)));
        if (result == true) _reloadPlans();
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF5374FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flight_rounded, size: 20, color: Color(0xFF5374FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (date.isNotEmpty) date,
                      if (flight != null) '${flight['airline']}',
                      if (places != null && places.isNotEmpty) '${places.length} yer',
                    ].join(' • '),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
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
      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5374FF), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // === HANDLERS ===

  Future<void> _handleLogin(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email ve şifre gerekli!');
      return;
    }
    setState(() => _loading = true);
    try {
      await _authService.signIn(email: email, password: password);
      _showSnackBar('Giriş başarılı!');
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
    setState(() => _loading = true);
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
    } finally {
      if (mounted) setState(() => _loading = false);
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
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
