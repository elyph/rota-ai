import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tourist_place.dart';

class PlacesService {
  // Backend URL'si - platforma göre otomatik ayarlanır
  // Android emülatör: 10.0.2.2, Web/Windows/Mac/Linux: localhost
  static String get _baseUrl {
    // Web ve desktop için localhost, Android emülatör için 10.0.2.2
    // Gerçek cihazda kendi IP'ni yazmalısın
    return 'http://localhost:8000';
  }

  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Belirtilen şehirdeki yerleri getirir (filtreleme destekler)
  Future<List<TouristPlace>> getNearbyPlaces({
    required String city,
    int radius = 5000,
    int maxResults = 15,
    String filterType = 'all', // all, tourist, food, nature, historical, shopping, entertainment
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/nearby-places'),
        headers: _headers,
        body: jsonEncode({
          'city': city,
          'radius': radius,
          'max_results': maxResults,
          'filter_type': filterType,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] != 'success') {
        throw Exception(jsonResponse['message'] ?? 'Bilinmeyen hata');
      }

      final placesList = jsonResponse['places'] as List? ?? [];
      return placesList.map((p) => TouristPlace.fromJson(p)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Desteklenen şehirlerin listesini getirir
  Future<List<Map<String, String>>> getCities() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/cities'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      final citiesList = jsonResponse['cities'] as List? ?? [];
      return citiesList.map((c) => Map<String, String>.from(c)).toList();
    } catch (e) {
      // Backend çalışmıyorsa varsayılan şehir listesini döndür
      return [
        {'name': 'İstanbul', 'key': 'istanbul'},
        {'name': 'Ankara', 'key': 'ankara'},
        {'name': 'İzmir', 'key': 'izmir'},
        {'name': 'Antalya', 'key': 'antalya'},
        {'name': 'Muğla', 'key': 'muğla'},
        {'name': 'Trabzon', 'key': 'trabzon'},
        {'name': 'Nevşehir', 'key': 'nevşehir'},
        {'name': 'Bursa', 'key': 'bursa'},
        {'name': 'Gaziantep', 'key': 'gaziantep'},
      ];
    }
  }

  void dispose() {
    _client.close();
  }
}
