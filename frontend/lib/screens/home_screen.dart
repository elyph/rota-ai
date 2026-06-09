import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/popular_place.dart';
import '../services/popular_places_service.dart';
import 'plan_wizard_screen.dart';
import 'flights_screen.dart';
import 'hotels_screen.dart';
import 'places_screen.dart';
import 'popular_places_list_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const HomeScreen({super.key, this.onNavigateToProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PopularPlace> _popularPlaces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPopularPlaces();
  }

  Widget _buildUserAvatar(User? user) {
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'A';
    final photoUrl = user?.userMetadata?['avatar_url'] as String?;
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A';

    final colors = [
      const Color(0xFF5374FF),
      const Color(0xFFA855F7),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];
    final bgColor = colors[fullName.hashCode.abs() % colors.length];

    if (photoUrl == null || photoUrl.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: bgColor,
        child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
      );
    }

    return _UserAvatar(radius: 24, photoUrl: photoUrl, initial: initial, bgColor: bgColor);
  }

  Future<void> _loadPopularPlaces() async {
    final places = await PopularPlacesService.fetchPopularPlaces();
    if (mounted) {
      setState(() {
        _popularPlaces = places;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName =
        user?.userMetadata?['full_name']?.split(' ')[0] ?? 'Abdullah';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Greeting & Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Merhaba, $userName',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('👋', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Yeni bir macera seni bekliyor!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  _buildUserAvatar(user),
                ],
              ),
              const SizedBox(height: 24),

              // Hero Card with airplane illustration
              GestureDetector(
                onTap: () {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) {
                    widget.onNavigateToProfile?.call();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PlanWizardScreen()),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5374FF), Color(0xFF3892FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5374FF).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Background image - fills right side with fade
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                colors: [Colors.transparent, Colors.white],
                                stops: [0.0, 0.3],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: Image.asset(
                              'assets/images/hero_plane.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        // Text content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Hemen\nseyahatini planla',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.45,
                                child: Text(
                                  'Uçuş, otel ve gezilecek yerleri kolayca oluştur, hayalindeki seyahati gerçeğe dönüştür.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.9),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Planlamaya Başla',
                                      style: TextStyle(
                                        color: Color(0xFF5374FF),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 16, color: Color(0xFF5374FF)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Quick Access Section
              const Text(
                'Hızlı Erişim',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAccessCard(
                    Icons.flight,
                    'Uçuş Ara',
                    'En uygun uçuşları bul',
                    const Color(0xFF5374FF),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FlightsScreen()),
                      );
                    },
                  ),
                  _buildQuickAccessCard(
                    Icons.apartment_rounded,
                    'Otel Bul',
                    'Konaklama seçenekleri',
                    const Color(0xFFA855F7),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HotelsScreen()),
                      );
                    },
                  ),
                  _buildQuickAccessCard(
                    Icons.location_on_rounded,
                    'Keşfet',
                    'Gezilecek yerleri keşfet',
                    const Color(0xFF10B981),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PlacesScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Popular Places Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Türkiye\'de Popüler Yerler',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const PopularPlacesListScreen()),
                      );
                    },
                    child: const Row(
                      children: [
                        Text('Tümünü Gör',
                            style: TextStyle(
                                color: Color(0xFF5374FF),
                                fontWeight: FontWeight.w600)),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: Color(0xFF5374FF)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF5374FF),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: _popularPlaces.length,
                        itemBuilder: (context, index) {
                          final place = _popularPlaces[index];
                          return _buildHorizontalPlaceCard(
                              context, place, index);
                        },
                      ),
              ),
              const SizedBox(height: 32),

              // Save Plans Banner
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.luggage_rounded,
                          color: Color(0xFF5374FF), size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Planlarını Kaydet',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Color(0xFF0F172A))),
                          SizedBox(height: 4),
                          Text(
                              'En sevdiğin seyahat planlarını kaydet, daha sonra kolayca devam et.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF64748B), size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100), // Extra space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalPlaceCard(
      BuildContext context, PopularPlace place, int index) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  place.imageUrl.isNotEmpty
                      ? place.imageUrl
                      : 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=500',
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  place.city,
                  style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFBBF24), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      place.rating.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          fontSize: 12),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _UserAvatar extends StatefulWidget {
  final double radius;
  final String photoUrl;
  final String initial;
  final Color bgColor;

  const _UserAvatar({
    required this.radius,
    required this.photoUrl,
    required this.initial,
    required this.bgColor,
  });

  @override
  State<_UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<_UserAvatar> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.bgColor,
        child: Text(widget.initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: NetworkImage(widget.photoUrl),
      onBackgroundImageError: (_, __) {
        if (mounted) setState(() => _hasError = true);
      },
    );
  }
}
