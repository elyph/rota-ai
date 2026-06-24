import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hotel.dart';

class HotelService {
  static String get _baseUrl {
    return 'http://localhost:8004';
  }

  final http.Client _client;

  HotelService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<List<Hotel>> searchHotels({
    required String city,
    required DateTime checkIn,
    required DateTime checkOut,
    int guests = 1,
    double? minRating,
    double? maxPrice,
    int maxResults = 50,
  }) async {
    final body = {
      'city': city,
      'check_in': checkIn.toIso8601String().split('T')[0],
      'check_out': checkOut.toIso8601String().split('T')[0],
      'guests': guests,
    };
    if (minRating != null) body['min_rating'] = minRating;
    if (maxPrice != null) body['max_price'] = maxPrice;
    body['max_results'] = maxResults;

    final response = await _client.post(
      Uri.parse('$_baseUrl/search-hotels'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Sunucu hatası: ${response.statusCode}');
    }

    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse['status'] != 'success') {
      throw Exception(jsonResponse['message'] ?? 'Bilinmeyen hata');
    }

    final hotelsList = jsonResponse['hotels'] as List? ?? [];
    return hotelsList.map((h) => Hotel.fromJson(Map<String, dynamic>.from(h))).toList();
  }

  void dispose() {
    _client.close();
  }
}
