import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tourist_place.dart';
import '../services/places_service.dart';

class PlacesScreen extends StatefulWidget {
  final String? cityName;
  final String? cityKey;

  const PlacesScreen({
    super.key,
    this.cityName,
    this.cityKey,
  });

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final PlacesService _placesService = PlacesService();
  List<TouristPlace>? _places;
  bool _yukleniyor = false;
  String? _hata;
  String? _secilenSehir;
  String? _secilenSehirAdi;

  final List<Map<String, String>> _sehirler = [
    {'name': 'İstanbul', 'key': 'istanbul'},
    {'name': 'Ankara', 'key': 'ankara'},
    {'name': 'İzmir', 'key': 'izmir'},
    {'name': 'Antalya', 'key': 'antalya'},
    {'name': 'Muğla', 'key': 'muğla'},
    {'name': 'Trabzon', 'key': 'trabzon'},
    {'name': 'Nevşehir', 'key': 'nevşehir'},
    {'name': 'Bursa', 'key': 'bursa'},
    {'name': 'Gaziantep', 'key': 'gaziantep'},
    {'name': 'Mardin', 'key': 'mardin'},
    {'name': 'Edirne', 'key': 'edirne'},
    {'name': 'Çanakkale', 'key': 'çanakkale'},
    {'name': 'Konya', 'key': 'konya'},
    {'name': 'Denizli', 'key': 'denizli'},
    {'name': 'Adana', 'key': 'adana'},
    {'name': 'Samsun', 'key': 'samsun'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.cityKey != null && widget.cityName != null) {
      _secilenSehir = widget.cityKey;
      _secilenSehirAdi = widget.cityName;
      _yerleriGetir();
    }
  }

  Future<void> _yerleriGetir() async {
    if (_secilenSehir == null) return;

    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final places = await _placesService.getNearbyPlaces(city: _secilenSehir!);
      final filteredPlaces = places.where((p) => p.rating >= 3.0).toList()
        ..sort((a, b) {
          final scoreA = a.rating * _logScale(a.userRatingsTotal);
          final scoreB = b.rating * _logScale(b.userRatingsTotal);
          return scoreB.compareTo(scoreA);
        });
      setState(() {
        _places = filteredPlaces;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  double _logScale(int value) {
    if (value <= 0) return 0;
    return 1 + (value.toDouble()).clamp(1, 999999).toDouble() / 1000;
  }

  void _openMapForAll() {
    if (_places == null || _places!.isEmpty || _secilenSehirAdi == null) return;
    final query = Uri.encodeComponent('turistik yerler $_secilenSehirAdi');
    final url = 'https://www.google.com/maps/search/$query';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _openMapForPlace(TouristPlace place) {
    final url = 'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}&query_place_id=${Uri.encodeComponent(place.name)}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _placesService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Map FAB
      floatingActionButton: (_places != null && _places!.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: _openMapForAll,
              backgroundColor: const Color(0xFF5374FF),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              icon: const Icon(Icons.map_rounded, size: 20),
              label: const Text('Haritada Gör', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button (only when pushed)
                  if (Navigator.canPop(context)) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gezilecek Yerler',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Keşfet, gez, unutulmaz anılar biriktir.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  // Map icon button
                  if (_places != null && _places!.isNotEmpty)
                    GestureDetector(
                      onTap: _openMapForAll,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.map_outlined, size: 22, color: Color(0xFF0F172A)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // City selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _showCityPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5374FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF5374FF)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Konum Seçin', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text(
                              _secilenSehirAdi != null ? '$_secilenSehirAdi, Türkiye' : 'Şehir seçin',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: _secilenSehirAdi != null ? FontWeight.w700 : FontWeight.w400,
                                color: _secilenSehirAdi != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _secilenSehir != null ? _yerleriGetir : null,
                  icon: const Icon(Icons.search_rounded, size: 20),
                  label: const Text('Yerleri Keşfet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5374FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Results
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_yukleniyor) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF5374FF)));
    }

    if (_hata != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              const Text('Yerler yüklenirken hata oluştu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _yerleriGetir,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5374FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_places == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore_rounded, size: 56, color: Color(0xFF94A3B8)),
              SizedBox(height: 12),
              Text('Bir şehir seçerek keşfe başla', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    if (_places!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text('Turistik yer bulunamadı', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('Önerilen Yerler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(width: 8),
              Text('${_places!.length} sonuç', style: const TextStyle(fontSize: 13, color: Color(0xFF5374FF), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Place list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            itemCount: _places!.length,
            itemBuilder: (context, index) => _buildPlaceCard(_places![index]),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCard(TouristPlace place) {
    return GestureDetector(
      onTap: () => _openMapForPlace(place),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 110,
                height: 120,
                child: place.photoUrl.isNotEmpty
                    ? Image.network(
                        place.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.image_rounded, color: Color(0xFF94A3B8), size: 32),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.place_rounded, color: Color(0xFF94A3B8), size: 32),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      place.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Address
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            place.address.isNotEmpty ? place.address : _secilenSehirAdi ?? '',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Category label
                    Text(
                      place.categoryLabel,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Rating + time estimate
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFBBF24)),
                        const SizedBox(width: 3),
                        Text(
                          '${place.rating.toStringAsFixed(1)} (${_formatCount(place.userRatingsTotal)})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Text(
                          _estimateTime(place),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _estimateTime(TouristPlace place) {
    if (place.types.contains('museum') || place.types.contains('art_gallery')) return '1-2 saat';
    if (place.types.contains('park') || place.types.contains('natural_feature')) return '1-3 saat';
    if (place.types.contains('shopping_mall')) return '2-3 saat';
    if (place.types.contains('mosque') || place.types.contains('church')) return '30 dk';
    return '1-2 saat';
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Konum Seçin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Keşfetmek istediğiniz şehri seçin',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _sehirler.length,
                      itemBuilder: (context, index) {
                        final sehir = _sehirler[index];
                        final isSelected = _secilenSehir == sehir['key'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _secilenSehir = sehir['key'];
                              _secilenSehirAdi = sehir['name'];
                              _places = null;
                            });
                            Navigator.pop(context);
                            _yerleriGetir();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF5374FF).withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF5374FF).withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_city_rounded,
                                  size: 20,
                                  color: isSelected ? const Color(0xFF5374FF) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  sehir['name']!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF5374FF) : const Color(0xFF0F172A),
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF5374FF)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
