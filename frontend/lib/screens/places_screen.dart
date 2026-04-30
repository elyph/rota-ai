import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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

  // Şehir listesi
  final List<Map<String, String>> _sehirler = [
    {'name': 'İstanbul', 'key': 'istanbul'},
    {'name': 'Ankara', 'key': 'ankara'},
    {'name': 'İzmir', 'key': 'izmir'},
    {'name': 'Antalya', 'key': 'antalya'},
    {'name': 'Muğla', 'key': 'muğla'},
    {'name': 'Trabzon', 'key': 'trabzon'},
    {'name': 'Adana', 'key': 'adana'},
    {'name': 'Nevşehir', 'key': 'nevşehir'},
    {'name': 'Gaziantep', 'key': 'gaziantep'},
    {'name': 'Erzurum', 'key': 'erzurum'},
    {'name': 'Samsun', 'key': 'samsun'},
    {'name': 'Bursa', 'key': 'bursa'},
    {'name': 'Konya', 'key': 'konya'},
    {'name': 'Mardin', 'key': 'mardin'},
    {'name': 'Edirne', 'key': 'edirne'},
    {'name': 'Çanakkale', 'key': 'çanakkale'},
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
      final places = await _placesService.getNearbyPlaces(
        city: _secilenSehir!,
      );
      setState(() {
        _places = places;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  @override
  void dispose() {
    _placesService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baslik = _secilenSehirAdi ?? 'Gezilecek Yerler';
    return Scaffold(
      appBar: AppBar(
        title: Text(baslik),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Eğer şehir seçilmemişse şehir seçme ekranını göster
    if (_secilenSehir == null) {
      return _buildCitySelection();
    }

    if (_yukleniyor) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Turistik yerler aranıyor...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_hata != null) {
      return _buildErrorView();
    }

    if (_places == null || _places!.isEmpty) {
      return _buildEmptyView();
    }

    return _buildPlacesList();
  }

  Widget _buildCitySelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.explore,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gezilecek Yerler',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bir şehir seçin, o şehirdeki turistik\n yerleri keşfedin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Popüler Şehirler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_sehirler.length, (index) {
            final sehir = _sehirler[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() {
                      _secilenSehir = sehir['key'];
                      _secilenSehirAdi = sehir['name'];
                    });
                    _yerleriGetir();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            sehir['name']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlacesList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.explore, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      _secilenSehirAdi ?? 'Gezilecek Yerler',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_places!.length} turistik yer bulundu',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Yer kartları
          ...List.generate(_places!.length, (index) {
            return _buildPlaceCard(_places![index]);
          }),

          const SizedBox(height: 16),

          // Bilgi notu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bilgiler Google Places verilerine dayanmaktadır. '
                    'Güncel durum için mekanın kendi sayfasını ziyaret edin.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(TouristPlace place) {
    // Puan rengi
    final ratingColor = place.rating >= 4.5
        ? Colors.green
        : place.rating >= 4.0
            ? Colors.lightGreen
            : place.rating >= 3.5
                ? Colors.orange
                : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _yerDetayGoster(place),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst kısım: İsim ve puan
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sol taraftaki ikon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getPlaceIcon(place.types),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // İsim ve adres
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            place.address,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Puan
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ratingColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: ratingColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ratingColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Alt kısım: Kategori, fiyat, durum
                Row(
                  children: [
                    // Kategori etiketi
                    _buildTag(
                      icon: _getPlaceIcon(place.types),
                      label: place.categoryLabel,
                    ),
                    const SizedBox(width: 8),

                    // Fiyat etiketi
                    if (place.priceLabel.isNotEmpty)
                      _buildTag(
                        icon: Icons.attach_money,
                        label: place.priceLabel,
                      ),

                    const Spacer(),

                    // Açık/Kapalı durumu
                    if (place.openNow != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (place.openNow!
                                  ? Colors.green
                                  : Colors.red)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          place.openNow! ? 'Açık' : 'Kapalı',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: place.openNow!
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPlaceIcon(List<String> types) {
    if (types.contains('museum') || types.contains('art_gallery')) {
      return Icons.museum;
    }
    if (types.contains('mosque') ||
        types.contains('church') ||
        types.contains('synagogue') ||
        types.contains('hindu_temple')) {
      return Icons.temple_buddhist;
    }
    if (types.contains('park') || types.contains('natural_feature')) {
      return Icons.nature;
    }
    if (types.contains('historical_place') || types.contains('landmark')) {
      return Icons.account_balance;
    }
    if (types.contains('amusement_park') || types.contains('zoo') || types.contains('aquarium')) {
      return Icons.celebration;
    }
    if (types.contains('shopping_mall')) {
      return Icons.shopping_bag;
    }
    return Icons.place;
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            const Text(
              'Yerler yüklenirken hata oluştu!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sunucuya bağlanılamadı. Backend\'in çalıştığından emin olun.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _yerleriGetir,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_off, size: 64, color: Colors.white70),
          const SizedBox(height: 16),
          const Text(
            'Bu şehirde turistik yer bulunamadı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri Dön'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _yerDetayGoster(TouristPlace place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_getPlaceIcon(place.types),
                color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                place.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adres
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.address,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Puan
            Row(
              children: [
                const Icon(Icons.star, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '${place.rating.toStringAsFixed(1)} (${_formatPuan(place.userRatingsTotal)} değerlendirme)',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Kategori
            Row(
              children: [
                Icon(Icons.category,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  place.categoryLabel,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fiyat
            Row(
              children: [
                Icon(Icons.attach_money,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  place.priceLabel.isEmpty ? 'Ücretsiz' : place.priceLabel,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            if (place.openNow != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    place.openNow! ? Icons.check_circle : Icons.cancel,
                    size: 18,
                    color: place.openNow! ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    place.openNow! ? 'Şu an açık' : 'Şu an kapalı',
                    style: TextStyle(
                      color: place.openNow! ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  String _formatPuan(int sayi) {
    if (sayi >= 1000) {
      return '${(sayi / 1000).toStringAsFixed(1)}K';
    }
    return sayi.toString();
  }
}
