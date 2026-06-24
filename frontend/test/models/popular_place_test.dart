import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/popular_place.dart';

void main() {
  group('PopularPlace fromJson', () {
    test('parses complete data correctly', () {
      final json = {
        'name': 'Kapadokya',
        'city': 'Nevşehir',
        'description': 'Balonlarla ünlü',
        'imageUrl': 'https://example.com/photo.jpg',
        'rating': 4.9,
        'latitude': 38.6437,
        'longitude': 34.8285,
        'category': 'Doğal Güzellik',
      };

      final place = PopularPlace.fromJson(json);

      expect(place.name, 'Kapadokya');
      expect(place.city, 'Nevşehir');
      expect(place.description, 'Balonlarla ünlü');
      expect(place.imageUrl, 'https://example.com/photo.jpg');
      expect(place.rating, 4.9);
      expect(place.latitude, 38.6437);
      expect(place.longitude, 34.8285);
      expect(place.category, 'Doğal Güzellik');
    });

    test('handles missing fields with defaults', () {
      final place = PopularPlace.fromJson({});

      expect(place.name, '');
      expect(place.city, '');
      expect(place.description, '');
      expect(place.imageUrl, '');
      expect(place.rating, 0.0);
      expect(place.latitude, 0.0);
      expect(place.longitude, 0.0);
      expect(place.category, '');
    });

    test('parses rating as int', () {
      final place = PopularPlace.fromJson({'rating': 4});
      expect(place.rating, 4.0);
    });
  });

  group('PopularPlace googleMapsUrl', () {
    test('generates correct Google Maps URL', () {
      const place = PopularPlace(
        name: 'Ayasofya Camii',
        city: 'İstanbul',
        description: '',
        imageUrl: '',
        rating: 4.8,
        latitude: 41.0086,
        longitude: 28.9802,
        category: 'Cami',
      );

      final url = place.googleMapsUrl;
      expect(url, contains('google.com/maps'));
      expect(url, contains('41.0086'));
      expect(url, contains('28.9802'));
      expect(url, contains('Ayasofya%20Camii'));
    });

    test('URL encodes special characters in name', () {
      const place = PopularPlace(
        name: 'İstanbul & Boğaz',
        city: 'İstanbul',
        description: '',
        imageUrl: '',
        rating: 4.0,
        latitude: 41.0,
        longitude: 29.0,
        category: '',
      );

      final url = place.googleMapsUrl;
      expect(url, isNot(contains(' ')));
      expect(url, contains('%26'));
    });
  });
}
