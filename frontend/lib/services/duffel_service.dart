import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/flight_offer.dart';

class DuffelService {
  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${ApiConfig.duffelApiToken}',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Duffel-Version': 'v2',
  };

  Future<List<FlightOffer>> searchFlights({
    required String origin,
    required String destination,
    required DateTime departureDate,
    DateTime? returnDate,
  }) async {
    try {
      final requestBody = {
        'data': {
          'slices': [
            {
              'origin': origin,
              'destination': destination,
              'departure_date': _formatDate(departureDate),
            },
          ],
          'passengers': [
            {'type': 'adult'},
          ],
        },
      };

      final response = await _client.post(
        Uri.parse('${ApiConfig.duffelBaseUrl}/air/offer_requests'),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Duffel API hatası: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      final offers = jsonResponse['data']?['offers'] as List? ?? [];

      // Sadece Pegasus uçuşlarını filtrele (içinde "Pegasus" geçen havayolları)
      final pegasusFlights = offers
          .map((offer) => FlightOffer.fromJson(offer))
          .where((flight) =>
              flight.airline.toLowerCase().contains('pegasus'))
          .toList()
        ..sort((a, b) => a.priceUSD.compareTo(b.priceUSD));

      return pegasusFlights;
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
