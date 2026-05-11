import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../models/popular_place.dart';
import '../services/popular_places_service.dart';
import 'plan_wizard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _haritadaAc(BuildContext context, PopularPlace place) async {
    final uri = Uri.parse(place.googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harita açılamadı: ${place.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final popularPlaces = PopularPlacesService.getPopularPlaces();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== ÜST BAŞLIK ==========
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.explore_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Rota AI',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Akıllı Seyahat Planlayıcınız',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ========== SEYAHAT PLANLA BÖLÜMÜ ==========
                _buildPlanSection(context),
                const SizedBox(height: 28),

                // ========== POPÜLER YERLER BAŞLIĞI ==========
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.trending_up_rounded, color: AppTheme.accentColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Popüler Yerler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ========== POPÜLER YERLER LİSTESİ ==========
                ...List.generate(popularPlaces.length, (index) {
                  final place = popularPlaces[index];
                  return _buildPlaceCard(context, place, index);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSection(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.elevatedGlassCard(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.travel_explore_rounded, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hemen Seyahatini Planla!',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            user != null
                ? 'Uçuş seç, yerler keşfet, planını oluştur.'
                : 'Planlamaya başlamak için giriş yapın.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: user != null ? AppTheme.primaryGradient : null,
                color: user != null ? null : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (user != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanWizardScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Planlamak için giriş yapın! Profil sekmesine gidin.'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                icon: Icon(user != null ? Icons.rocket_launch_rounded : Icons.login_rounded, size: 20),
                label: Text(
                  user != null ? 'Planlamaya Başla' : 'Giriş Yap / Kayıt Ol',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(BuildContext context, PopularPlace place, int index) {
    final ratingColor = place.rating >= 4.7
        ? const Color(0xFF10B981)
        : place.rating >= 4.5
            ? const Color(0xFF34D399)
            : const Color(0xFFFBBF24);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _haritadaAc(context, place),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassCard(opacity: 0.06, borderOpacity: 0.08, radius: 16),
            child: Row(
              children: [
                // Numara
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // İçerik
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                          const SizedBox(width: 3),
                          Text(place.city, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ratingColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 11, color: ratingColor),
                                const SizedBox(width: 2),
                                Text(place.rating.toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ratingColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
