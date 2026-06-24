import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/places_service.dart';
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
  group('PlacesService.getNearbyPlaces', () {
    test('returns list of places on success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/nearby-places');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['city'], 'istanbul');
        expect(body['radius'], 5000);
        expect(body['max_results'], 15);

        return _utf8Response(
          jsonEncode({
            'status': 'success',
            'places': [
              {
                'id': '1',
                'name': 'Ayasofya Camii',
                'address': 'Sultanahmet',
                'rating': 4.8,
                'userRatingsTotal': 45000,
                'types': ['mosque', 'tourist_attraction'],
                'photoUrl': '',
                'latitude': 41.0086,
                'longitude': 28.9802,
                'priceLevel': 0,
                'openNow': true,
              },
            ],
          }),
          200,
        );
      });

      final service = PlacesService(client: mockClient);
      final places = await service.getNearbyPlaces(city: 'istanbul');

      expect(places.length, 1);
      expect(places[0].name, 'Ayasofya Camii');
      expect(places[0].rating, 4.8);
      service.dispose();
    });

    test('prepends base URL to relative photo URLs', () async {
      final mockClient = MockClient((_) async => _utf8Response(
        jsonEncode({
          'status': 'success',
          'places': [
            {
              'id': 'p1',
              'name': 'Test Place',
              'address': 'Addr',
              'rating': 4.0,
              'userRatingsTotal': 100,
              'types': ['tourist_attraction'],
              'photoUrl': '/place-photo?photo_reference=abc123',
              'latitude': 41.0,
              'longitude': 29.0,
              'priceLevel': 0,
            },
          ],
        }),
        200,
      ));

      final service = PlacesService(client: mockClient);
      final places = await service.getNearbyPlaces(city: 'istanbul');

      expect(places[0].photoUrl, 'http://localhost:8004/place-photo?photo_reference=abc123');
      service.dispose();
    });

    test('does not modify absolute photo URLs', () async {
      final mockClient = MockClient((_) async => _utf8Response(
        jsonEncode({
          'status': 'success',
          'places': [
            {
              'id': 'p1',
              'name': 'Test',
              'address': '',
              'rating': 4.0,
              'userRatingsTotal': 10,
              'types': [],
              'photoUrl': 'https://external.cdn/photo.jpg',
              'latitude': 0.0,
              'longitude': 0.0,
              'priceLevel': 0,
            },
          ],
        }),
        200,
      ));

      final service = PlacesService(client: mockClient);
      final places = await service.getNearbyPlaces(city: 'istanbul');

      expect(places[0].photoUrl, 'https://external.cdn/photo.jpg');
      service.dispose();
    });

    test('throws exception on non-200 status', () async {
      final mockClient = MockClient((_) async => http.Response('Error', 500));
      final service = PlacesService(client: mockClient);

      await expectLater(
        () => service.getNearbyPlaces(city: 'istanbul'),
        throwsA(isA<Exception>()),
      );
      service.dispose();
    });

    test('throws exception when status is error', () async {
      final mockClient = MockClient((_) async => _utf8Response(
        jsonEncode({'status': 'error', 'message': "mars şehri bulunamadı.", 'places': []}),
        200,
      ));
      final service = PlacesService(client: mockClient);

      await expectLater(
        () => service.getNearbyPlaces(city: 'mars'),
        throwsA(isA<Exception>()),
      );
      service.dispose();
    });

    test('returns empty list when places array is empty', () async {
      final mockClient = MockClient((_) async => _utf8Response(
        jsonEncode({'status': 'success', 'places': []}),
        200,
      ));
      final service = PlacesService(client: mockClient);
      final places = await service.getNearbyPlaces(city: 'istanbul');

      expect(places, isEmpty);
      service.dispose();
    });
  });

  group('PlacesService.getCities', () {
    test('returns list of cities on success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/cities');
        return _utf8Response(
          jsonEncode({
            'status': 'success',
            'cities': [
              {'name': 'İstanbul', 'key': 'istanbul'},
              {'name': 'Ankara', 'key': 'ankara'},
            ],
          }),
          200,
        );
      });

      final service = PlacesService(client: mockClient);
      final cities = await service.getCities();

      expect(cities.length, 2);
      expect(cities[0]['name'], 'İstanbul');
      expect(cities[0]['key'], 'istanbul');
      service.dispose();
    });

    test('returns fallback cities when request throws', () async {
      final mockClient = MockClient((_) async => throw Exception('Network error'));
      final service = PlacesService(client: mockClient);
      final cities = await service.getCities();

      expect(cities.isNotEmpty, true);
      final names = cities.map((c) => c['name']).toList();
      expect(names, contains('İstanbul'));
      service.dispose();
    });

    test('returns fallback cities when response status is not 200', () async {
      final mockClient = MockClient((_) async => http.Response('Error', 503));
      final service = PlacesService(client: mockClient);
      final cities = await service.getCities();

      expect(cities.isNotEmpty, true);
      service.dispose();
    });
  });
}
