import 'dart:convert';
import 'package:http/http.dart' as http;

class ItineraryService {
  static const String _baseUrl = 'http://localhost:8004';
  final http.Client _client = http.Client();

  /// Kullanıcının seçimlerine göre Gemini'den gün gün program oluşturur.
  Future<String> generateItinerary({
    required String departureCity,
    required String arrivalCity,
    required String departureDate,
    String? returnDate,
    String? hotelName,
    List<Map<String, dynamic>> selectedPlaces = const [],
    String? flightAirline,
    String? flightDepartureTime,
    String? returnFlightAirline,
    String? returnFlightDepartureTime,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/generate-itinerary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'departure_city': departureCity,
        'arrival_city': arrivalCity,
        'departure_date': departureDate,
        'return_date': returnDate,
        'hotel_name': hotelName,
        'selected_places': selectedPlaces,
        'flight_airline': flightAirline,
        'flight_departure_time': flightDepartureTime,
        'return_flight_airline': returnFlightAirline,
        'return_flight_departure_time': returnFlightDepartureTime,
      }),
    ).timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      throw Exception('Sunucu hatası: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    if (json['status'] != 'success') {
      throw Exception(json['message'] ?? 'Program oluşturulamadı');
    }

    return json['itinerary'] as String;
  }

  void dispose() {
    _client.close();
  }
}
