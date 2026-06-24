import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/hotel_service.dart';
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
  group('HotelService.searchHotels', () {
    test('returns list of hotels on success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/search-hotels');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['city'], 'Antalya');
        expect(body['check_in'], '2025-06-01');
        expect(body['check_out'], '2025-06-05');
        expect(body['guests'], 1);

        return _utf8Response(
          jsonEncode({
            'status': 'success',
            'hotels': [
              {
                'id': 'hotel_1',
                'name': 'Rixos Premium',
                'address': 'Antalya Merkez',
                'rating': 4.7,
                'reviewCount': 250,
                'pricePerNight': 3500.0,
                'imageUrl': '',
                'latitude': 36.8874,
                'longitude': 30.7056,
                'amenities': ['WiFi', 'Havuz'],
                'stars': 5,
              },
              {
                'id': 'hotel_2',
                'name': 'Budget Hotel',
                'address': 'Konyaaltı',
                'rating': 3.5,
                'reviewCount': 80,
                'pricePerNight': 800.0,
                'imageUrl': '',
                'latitude': 36.86,
                'longitude': 30.64,
                'amenities': ['WiFi'],
                'stars': 3,
              },
            ],
          }),
          200,
        );
      });

      final service = HotelService(client: mockClient);
      final hotels = await service.searchHotels(
        city: 'Antalya',
        checkIn: DateTime(2025, 6, 1),
        checkOut: DateTime(2025, 6, 5),
      );

      expect(hotels.length, 2);
      expect(hotels[0].name, 'Rixos Premium');
      expect(hotels[0].pricePerNight, 3500.0);
      expect(hotels[1].name, 'Budget Hotel');
      service.dispose();
    });

    test('throws exception on non-200 status', () async {
      final mockClient = MockClient((_) async => http.Response('Internal Server Error', 500));
      final service = HotelService(client: mockClient);

      await expectLater(
        () => service.searchHotels(
          city: 'Antalya',
          checkIn: DateTime(2025, 6, 1),
          checkOut: DateTime(2025, 6, 5),
        ),
        throwsA(isA<Exception>()),
      );
      service.dispose();
    });

    test('throws exception when status is error', () async {
      final mockClient = MockClient((_) async => _utf8Response(
        jsonEncode({'status': 'error', 'message': 'SerpAPI key yapılandırılmamış.'}),
        200,
      ));
      final service = HotelService(client: mockClient);

      await expectLater(
        () => service.searchHotels(
          city: 'Antalya',
          checkIn: DateTime(2025, 6, 1),
          checkOut: DateTime(2025, 6, 5),
        ),
        throwsA(isA<Exception>()),
      );
      service.dispose();
    });

    test('returns empty list when hotels array is empty', () async {
      final mockClient = MockClient((_) async => _utf8Response(
        jsonEncode({'status': 'success', 'hotels': []}),
        200,
      ));
      final service = HotelService(client: mockClient);
      final hotels = await service.searchHotels(
        city: 'Antalya',
        checkIn: DateTime(2025, 6, 1),
        checkOut: DateTime(2025, 6, 5),
      );

      expect(hotels, isEmpty);
      service.dispose();
    });

    test('sends optional min_rating and max_price when provided', () async {
      Map<String, dynamic>? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _utf8Response(jsonEncode({'status': 'success', 'hotels': []}), 200);
      });

      final service = HotelService(client: mockClient);
      await service.searchHotels(
        city: 'İstanbul',
        checkIn: DateTime(2025, 8, 1),
        checkOut: DateTime(2025, 8, 3),
        minRating: 4.0,
        maxPrice: 2000.0,
      );

      expect(capturedBody?['min_rating'], 4.0);
      expect(capturedBody?['max_price'], 2000.0);
      service.dispose();
    });

    test('does not send min_rating and max_price when null', () async {
      Map<String, dynamic>? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _utf8Response(jsonEncode({'status': 'success', 'hotels': []}), 200);
      });

      final service = HotelService(client: mockClient);
      await service.searchHotels(
        city: 'IST',
        checkIn: DateTime(2025, 8, 1),
        checkOut: DateTime(2025, 8, 3),
      );

      expect(capturedBody?.containsKey('min_rating'), false);
      expect(capturedBody?.containsKey('max_price'), false);
      service.dispose();
    });

    test('formats dates as YYYY-MM-DD', () async {
      Map<String, dynamic>? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _utf8Response(jsonEncode({'status': 'success', 'hotels': []}), 200);
      });

      final service = HotelService(client: mockClient);
      await service.searchHotels(
        city: 'Antalya',
        checkIn: DateTime(2025, 1, 5),
        checkOut: DateTime(2025, 1, 10),
      );

      expect(capturedBody?['check_in'], '2025-01-05');
      expect(capturedBody?['check_out'], '2025-01-10');
      service.dispose();
    });

    test('parses hotel with null pricePerNight correctly', () async {
      final mockClient = MockClient((_) async => _utf8Response(
        jsonEncode({
          'status': 'success',
          'hotels': [
            {
              'id': 'h1',
              'name': 'Test',
              'address': '',
              'rating': 3.0,
              'reviewCount': 5,
              'pricePerNight': null,
              'imageUrl': '',
              'latitude': 0,
              'longitude': 0,
              'amenities': [],
              'stars': 2,
            }
          ],
        }),
        200,
      ));
      final service = HotelService(client: mockClient);
      final hotels = await service.searchHotels(
        city: 'Antalya',
        checkIn: DateTime(2025, 6, 1),
        checkOut: DateTime(2025, 6, 5),
      );

      expect(hotels[0].pricePerNight, isNull);
      service.dispose();
    });
  });
}
