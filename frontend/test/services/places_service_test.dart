import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/tourist_place.dart';

void main() {
  group('TouristPlace from service response', () {
    test('parses Google Places API response format', () {
      final json = {
        'id': 'ChIJ123',
        'name': 'Topkapı Sarayı',
        'address': 'Sultanahmet, Fatih',
        'rating': 4.7,
        'userRatingsTotal': 38000,
        'types': ['tourist_attraction', 'museum', 'historical_place'],
        'photoUrl': 'http://localhost:8004/place-photo?photo_reference=abc',
        'latitude': 41.0115,
        'longitude': 28.9833,
        'priceLevel': 2,
        'openNow': true,
      };

      final place = TouristPlace.fromJson(json);

      expect(place.name, 'Topkapı Sarayı');
      expect(place.rating, 4.7);
      expect(place.userRatingsTotal, 38000);
      expect(place.categoryLabel, 'Müze');
      expect(place.priceLabel, '₺₺');
    });

    test('parses mock data from backend', () {
      final json = {
        'id': '1',
        'name': 'Ayasofya Camii',
        'address': 'Sultanahmet, Fatih',
        'rating': 4.8,
        'userRatingsTotal': 45000,
        'types': ['tourist_attraction', 'mosque', 'historical_place'],
        'photoUrl': '',
        'latitude': 41.0086,
        'longitude': 28.9802,
        'priceLevel': 0,
        'openNow': true,
      };

      final place = TouristPlace.fromJson(json);

      expect(place.name, 'Ayasofya Camii');
      expect(place.categoryLabel, 'Cami');
      expect(place.priceLabel, 'Ücretsiz');
    });
  });

  group('TouristPlace category classification', () {
    test('priority order is correct for historical church', () {
      final place = TouristPlace.fromJson({
        'types': ['tourist_attraction', 'church', 'historical_place', 'museum'],
      });

      // museum comes first in categoryLabel check order
      expect(place.categoryLabel, 'Müze');
    });
  });
}
