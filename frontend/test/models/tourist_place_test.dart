import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/tourist_place.dart';

void main() {
  group('TouristPlace fromJson', () {
    test('parses complete place data correctly', () {
      final json = {
        'id': 'place_1',
        'name': 'Ayasofya Camii',
        'address': 'Sultanahmet, Fatih',
        'rating': 4.8,
        'userRatingsTotal': 45000,
        'types': ['tourist_attraction', 'mosque', 'historical_place'],
        'photoUrl': '/place-photo?photo_reference=abc',
        'latitude': 41.0086,
        'longitude': 28.9802,
        'priceLevel': 0,
        'openNow': true,
      };

      final place = TouristPlace.fromJson(json);

      expect(place.id, 'place_1');
      expect(place.name, 'Ayasofya Camii');
      expect(place.address, 'Sultanahmet, Fatih');
      expect(place.rating, 4.8);
      expect(place.userRatingsTotal, 45000);
      expect(place.types, ['tourist_attraction', 'mosque', 'historical_place']);
      expect(place.photoUrl, '/place-photo?photo_reference=abc');
      expect(place.latitude, 41.0086);
      expect(place.longitude, 28.9802);
      expect(place.priceLevel, 0);
      expect(place.openNow, true);
    });

    test('handles missing fields with defaults', () {
      final place = TouristPlace.fromJson({});

      expect(place.id, '');
      expect(place.name, '');
      expect(place.rating, 0.0);
      expect(place.userRatingsTotal, 0);
      expect(place.types, []);
      expect(place.latitude, 0.0);
      expect(place.longitude, 0.0);
      expect(place.priceLevel, 0);
      expect(place.openNow, null);
    });

    test('parses rating as int', () {
      final place = TouristPlace.fromJson({'rating': 4});

      expect(place.rating, 4.0);
    });

    test('handles null openNow', () {
      final place = TouristPlace.fromJson({'openNow': null});

      expect(place.openNow, null);
    });
  });

  group('TouristPlace categoryLabel', () {
    test('returns Müze for museum type', () {
      final place = TouristPlace.fromJson({'types': ['museum']});
      expect(place.categoryLabel, 'Müze');
    });

    test('returns Cami for mosque type', () {
      final place = TouristPlace.fromJson({'types': ['mosque']});
      expect(place.categoryLabel, 'Cami');
    });

    test('returns Kilise for church type', () {
      final place = TouristPlace.fromJson({'types': ['church']});
      expect(place.categoryLabel, 'Kilise');
    });

    test('returns Park for park type', () {
      final place = TouristPlace.fromJson({'types': ['park']});
      expect(place.categoryLabel, 'Park');
    });

    test('returns Sanat Galerisi for art_gallery type', () {
      final place = TouristPlace.fromJson({'types': ['art_gallery']});
      expect(place.categoryLabel, 'Sanat Galerisi');
    });

    test('returns Tarihi Yer for historical_place type', () {
      final place = TouristPlace.fromJson({'types': ['historical_place']});
      expect(place.categoryLabel, 'Tarihi Yer');
    });

    test('returns Simge Yapı for landmark type', () {
      final place = TouristPlace.fromJson({'types': ['landmark']});
      expect(place.categoryLabel, 'Simge Yapı');
    });

    test('returns Doğal Güzellik for natural_feature type', () {
      final place = TouristPlace.fromJson({'types': ['natural_feature']});
      expect(place.categoryLabel, 'Doğal Güzellik');
    });

    test('returns Eğlence Parkı for amusement_park type', () {
      final place = TouristPlace.fromJson({'types': ['amusement_park']});
      expect(place.categoryLabel, 'Eğlence Parkı');
    });

    test('returns Hayvanat Bahçesi for zoo type', () {
      final place = TouristPlace.fromJson({'types': ['zoo']});
      expect(place.categoryLabel, 'Hayvanat Bahçesi');
    });

    test('returns Akvaryum for aquarium type', () {
      final place = TouristPlace.fromJson({'types': ['aquarium']});
      expect(place.categoryLabel, 'Akvaryum');
    });

    test('returns Alışveriş Merkezi for shopping_mall type', () {
      final place = TouristPlace.fromJson({'types': ['shopping_mall']});
      expect(place.categoryLabel, 'Alışveriş Merkezi');
    });

    test('returns Turistik Yer for unknown type', () {
      final place = TouristPlace.fromJson({'types': ['unknown_type']});
      expect(place.categoryLabel, 'Turistik Yer');
    });

    test('returns Turistik Yer for empty types', () {
      final place = TouristPlace.fromJson({'types': []});
      expect(place.categoryLabel, 'Turistik Yer');
    });

    test('prioritizes first matching type', () {
      final place = TouristPlace.fromJson({'types': ['museum', 'mosque', 'park']});
      expect(place.categoryLabel, 'Müze');
    });
  });

  group('TouristPlace priceLabel', () {
    test('returns Ücretsiz for priceLevel 0', () {
      final place = TouristPlace.fromJson({'priceLevel': 0});
      expect(place.priceLabel, 'Ücretsiz');
    });

    test('returns ₺ for priceLevel 1', () {
      final place = TouristPlace.fromJson({'priceLevel': 1});
      expect(place.priceLabel, '₺');
    });

    test('returns ₺₺ for priceLevel 2', () {
      final place = TouristPlace.fromJson({'priceLevel': 2});
      expect(place.priceLabel, '₺₺');
    });

    test('returns ₺₺₺ for priceLevel 3', () {
      final place = TouristPlace.fromJson({'priceLevel': 3});
      expect(place.priceLabel, '₺₺₺');
    });

    test('returns ₺₺₺₺ for priceLevel 4', () {
      final place = TouristPlace.fromJson({'priceLevel': 4});
      expect(place.priceLabel, '₺₺₺₺');
    });

    test('returns empty for priceLevel above 4', () {
      final place = TouristPlace.fromJson({'priceLevel': 5});
      expect(place.priceLabel, '');
    });
  });
}
