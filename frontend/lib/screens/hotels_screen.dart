import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HotelsScreen extends StatefulWidget {
  const HotelsScreen({super.key});

  @override
  State<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends State<HotelsScreen> {
  final List<Map<String, dynamic>> _popularHotels = [
    {
      'name': 'Swissôtel The Bosphorus',
      'city': 'İstanbul',
      'rating': 4.8,
      'price': '₺8.500+',
      'desc': 'Boğaz manzaralı lüks otel',
    },
    {
      'name': 'Rixos Premium',
      'city': 'Antalya',
      'rating': 4.7,
      'price': '₺6.200+',
      'desc': 'Her şey dahil tatil köyü',
    },
    {
      'name': 'Hilton Bomonti',
      'city': 'İstanbul',
      'rating': 4.6,
      'price': '₺5.900+',
      'desc': 'Şehir merkezinde konfor',
    },
    {
      'name': 'Maxx Royal',
      'city': 'Antalya',
      'rating': 4.9,
      'price': '₺15.000+',
      'desc': 'Ultra lüks tatil deneyimi',
    },
    {
      'name': 'D-Hotel Maris',
      'city': 'Muğla',
      'rating': 4.7,
      'price': '₺7.800+',
      'desc': 'Marmaris\'te butik lüks',
    },
    {
      'name': 'Mula Hotel',
      'city': 'Muğla',
      'rating': 4.5,
      'price': '₺4.500+',
      'desc': 'Sakin ve huzurlu bir kaçış',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oteller'),
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
          child: SingleChildScrollView(
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
                          const Icon(Icons.hotel, color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          const Text(
                            'Popüler Oteller',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Türkiye\'nin en popüler otelleri',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Otel kartları
                ...List.generate(_popularHotels.length, (index) {
                  final hotel = _popularHotels[index];
                  return _buildHotelCard(hotel, index);
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
                      Icon(Icons.info_outline, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fiyatlar sezona göre değişiklik gösterebilir. Güncel fiyatlar için otel sayfasını ziyaret edin.',
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
          ),
        ),
      ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel, int index) {
    final ratingColor = (hotel['rating'] as double) >= 4.7
        ? Colors.green
        : (hotel['rating'] as double) >= 4.5
            ? Colors.lightGreen
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${hotel['name']} - ${hotel['city']}'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Sol ikon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.hotel, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),

                // Orta kısım
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            hotel['city'],
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            hotel['rating'].toString(),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ratingColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hotel['desc'],
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Fiyat
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    hotel['price'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
