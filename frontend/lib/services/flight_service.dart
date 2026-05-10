import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/flight_offer.dart';

class FlightService {
  final http.Client _client = http.Client();
  static const String _baseUrl = 'http://localhost:8001';

  Future<List<FlightOffer>> searchFlights({
    required String origin,
    required String destination,
    required DateTime departureDate,
    DateTime? returnDate,
  }) async {
    try {
      final requestBody = {
        'departure_city': origin,
        'arrival_city': destination,
        'departure_date': _formatDate(departureDate),
        'return_date': returnDate != null ? _formatDate(returnDate) : null,
        'passengers': 1,
        'currency': 'TRY',
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/search-flights'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('API hatası: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] != 'success') {
        throw Exception(jsonResponse['message'] ?? 'Bilinmeyen hata');
      }

      final flights = jsonResponse['flights'] as List? ?? [];

      return flights
          .map((flight) => FlightOffer.fromJson(flight))
          .toList()
        ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
    } catch (e) {
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _client.close();
  }
}
