import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/flight_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

http.Response _utf8Response(String body, int statusCode) {
  return http.Response.bytes(
    utf8.encode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  group('FlightService.searchFlights', () {
    test('returns sorted flights on success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/search-flights');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['departure_city'], 'İstanbul');
        expect(body['arrival_city'], 'Ankara');
        expect(body['passengers'], 1);
        expect(body['currency'], 'TRY');
        expect(body['return_date'], isNull);

        return _utf8Response(
          jsonEncode({
            'status': 'success',
            'flights': [
              {
                'airline': 'Pegasus',
                'flight_number': 'PC200',
                'departure_city': 'İstanbul',
                'arrival_city': 'Ankara',
                'departure_time': '14:00',
                'arrival_time': '15:00',
                'duration': '1s 0dk',
                'price': 500,
                'stops': 0,
                'currency': 'TRY',
                'departure_date': '2025-06-15',
              },
              {
                'airline': 'THY',
                'flight_number': 'TK100',
                'departure_city': 'İstanbul',
                'arrival_city': 'Ankara',
                'departure_time': '08:00',
                'arrival_time': '09:00',
                'duration': '1s 0dk',
                'price': 750,
                'stops': 0,
                'currency': 'TRY',
                'departure_date': '2025-06-15',
              },
            ],
          }),
          200,
        );
      });

      final service = FlightService(client: mockClient);
      final flights = await service.searchFlights(
        origin: 'İstanbul',
        destination: 'Ankara',
        departureDate: DateTime(2025, 6, 15),
      );

      expect(flights.length, 2);
      expect(flights[0].departureTime, '08:00');
      expect(flights[1].departureTime, '14:00');
      service.dispose();
    });

    test('throws exception on non-200 status code', () async {
      final mockClient = MockClient((_) async => http.Response('Server Error', 500));
      final service = FlightService(client: mockClient);

      await expectLater(
        () => service.searchFlights(
          origin: 'IST',
          destination: 'ESB',
          departureDate: DateTime(2025, 6, 15),
        ),
        throwsA(isA<Exception>()),
      );
      service.dispose();
    });

    test('throws exception when status is not success', () async {
      final mockClient = MockClient((_) async => _utf8Response(
        jsonEncode({'status': 'error', 'message': 'SerpAPI anahtarı yapılandırılmamış.'}),
        200,
      ));
      final service = FlightService(client: mockClient);

      await expectLater(
        () => service.searchFlights(
          origin: 'IST',
          destination: 'ESB',
          departureDate: DateTime(2025, 6, 15),
        ),
        throwsA(isA<Exception>()),
      );
      service.dispose();
    });

    test('returns empty list when flights array is empty', () async {
      final mockClient = MockClient((_) async => _utf8Response(
        jsonEncode({'status': 'success', 'flights': []}),
        200,
      ));
      final service = FlightService(client: mockClient);
      final flights = await service.searchFlights(
        origin: 'IST',
        destination: 'ESB',
        departureDate: DateTime(2025, 6, 15),
      );

      expect(flights, isEmpty);
      service.dispose();
    });

    test('includes return_date in request body for round trip', () async {
      String? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = request.body;
        return _utf8Response(jsonEncode({'status': 'success', 'flights': []}), 200);
      });

      final service = FlightService(client: mockClient);
      await service.searchFlights(
        origin: 'IST',
        destination: 'ESB',
        departureDate: DateTime(2025, 6, 15),
        returnDate: DateTime(2025, 6, 20),
      );

      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['return_date'], '2025-06-20');
      service.dispose();
    });

    test('formats date correctly as YYYY-MM-DD', () async {
      String? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = request.body;
        return _utf8Response(jsonEncode({'status': 'success', 'flights': []}), 200);
      });

      final service = FlightService(client: mockClient);
      await service.searchFlights(
        origin: 'IST',
        destination: 'ESB',
        departureDate: DateTime(2025, 1, 5),
      );

      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['departure_date'], '2025-01-05');
      service.dispose();
    });

    test('sends correct Content-Type header', () async {
      Map<String, String>? capturedHeaders;
      final mockClient = MockClient((request) async {
        capturedHeaders = request.headers;
        return _utf8Response(jsonEncode({'status': 'success', 'flights': []}), 200);
      });

      final service = FlightService(client: mockClient);
      await service.searchFlights(
        origin: 'IST',
        destination: 'ESB',
        departureDate: DateTime(2025, 6, 15),
      );

      expect(capturedHeaders?['Content-Type'], contains('application/json'));
      service.dispose();
    });
  });
}
