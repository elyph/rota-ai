import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/popular_place.dart';

class PopularPlacesService {
  static String get _baseUrl => 'http://localhost:8004';

  /// Backend'den Google Places API üzerinden en popüler yerleri çeker
  static Future<List<PopularPlace>> fetchPopularPlaces() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/popular-places'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return _getFallbackPlaces();
      }

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] != 'success') {
        return _getFallbackPlaces();
      }

      final placesList = jsonResponse['places'] as List? ?? [];
      return placesList.map((p) {
        var photoUrl = p['photoUrl'] ?? '';
        // Backend'den gelen relative photo URL'lerini tam URL'e çevir
        if (photoUrl is String && photoUrl.startsWith('/')) {
          photoUrl = '$_baseUrl$photoUrl';
        }
        return PopularPlace(
          name: p['name'] ?? '',
          city: p['city'] ?? p['address'] ?? '',
          description: '',
          imageUrl: photoUrl,
          rating: (p['rating'] ?? 0).toDouble(),
          latitude: (p['latitude'] ?? 0).toDouble(),
          longitude: (p['longitude'] ?? 0).toDouble(),
          category: (p['types'] is List && (p['types'] as List).isNotEmpty)
              ? (p['types'] as List).first.toString()
              : '',
        );
      }).toList();
    } catch (e) {
      return _getFallbackPlaces();
    }
  }

  /// API çalışmazsa fallback veriler
  static List<PopularPlace> _getFallbackPlaces() {
    return const [
      PopularPlace(
        name: 'Kapadokya',
        city: 'Nevşehir',
        description: 'Sıcak hava balonlarıyla ünlü büyülü coğrafya.',
        imageUrl:
            'https://images.unsplash.com/photo-1641128324972-af3212f0f6bd?w=600&q=80',
        rating: 4.9,
        latitude: 38.6437,
        longitude: 34.8285,
        category: 'Doğal Güzellik',
      ),
      PopularPlace(
        name: 'İstanbul',
        city: 'İstanbul',
        description: 'Boğaz manzarası ve eşsiz kültürel zenginlikler.',
        imageUrl:
            'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=600&q=80',
        rating: 4.8,
        latitude: 41.0086,
        longitude: 28.9802,
        category: 'Şehir',
      ),
      PopularPlace(
        name: 'Pamukkale',
        city: 'Denizli',
        description: 'Beyaz traverten terasları ve antik Hierapolis.',
        imageUrl:
            'https://images.unsplash.com/photo-1600460484673-edd27bf4e9f7?w=600&q=80',
        rating: 4.8,
        latitude: 37.9236,
        longitude: 29.1197,
        category: 'Doğal Güzellik',
      ),
      PopularPlace(
        name: 'Ölüdeniz',
        city: 'Muğla',
        description: 'Turkuaz denizi ve yamaç paraşütüyle ünlü cennet koy.',
        imageUrl:
            'https://images.unsplash.com/photo-1519451241324-20b4ea2c4220?w=600&q=80',
        rating: 4.7,
        latitude: 36.5497,
        longitude: 29.1153,
        category: 'Plaj',
      ),
      PopularPlace(
        name: 'Efes Antik Kenti',
        city: 'İzmir',
        description: 'Celsus Kütüphanesi ile ünlü antik şehir.',
        imageUrl:
            'https://images.unsplash.com/photo-1590076082562-3f6b6a8b5b80?w=600&q=80',
        rating: 4.8,
        latitude: 37.9397,
        longitude: 27.3408,
        category: 'Antik Kent',
      ),
      PopularPlace(
        name: 'Antalya',
        city: 'Antalya',
        description: 'Tarihi Kaleiçi ve muhteşem sahilleri.',
        imageUrl:
            'https://images.unsplash.com/photo-1593238739364-18cfde3bfe84?w=600&q=80',
        rating: 4.7,
        latitude: 36.8874,
        longitude: 30.7056,
        category: 'Şehir',
      ),
      PopularPlace(
        name: 'Trabzon',
        city: 'Trabzon',
        description: 'Sümela Manastırı ve yaylalarıyla ünlü şehir.',
        imageUrl:
            'https://images.unsplash.com/photo-1603483080228-04f2313d9f10?w=600&q=80',
        rating: 4.6,
        latitude: 40.8300,
        longitude: 39.6650,
        category: 'Doğa',
      ),
      PopularPlace(
        name: 'Nemrut Dağı',
        city: 'Adıyaman',
        description: 'Dev heykelleriyle ünlü eşsiz tepe.',
        imageUrl:
            'https://images.unsplash.com/photo-1589561454226-796a8c0e5754?w=600&q=80',
        rating: 4.6,
        latitude: 37.9809,
        longitude: 38.7408,
        category: 'Antik Kent',
      ),
    ];
  }
}
