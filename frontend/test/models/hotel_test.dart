import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/hotel.dart';

void main() {
  group('Hotel fromJson', () {
    test('parses complete hotel data correctly', () {
      final json = {
        'id': 'hotel_1',
        'name': 'Rixos Premium',
        'address': 'Antalya Merkez',
        'rating': 4.7,
        'reviewCount': 250,
        'pricePerNight': 3500.0,
        'imageUrl': 'https://example.com/photo.jpg',
        'latitude': 36.8874,
        'longitude': 30.7056,
        'amenities': ['WiFi', 'Havuz', 'Spa'],
        'stars': 5,
      };

      final hotel = Hotel.fromJson(json);

      expect(hotel.id, 'hotel_1');
      expect(hotel.name, 'Rixos Premium');
      expect(hotel.address, 'Antalya Merkez');
      expect(hotel.rating, 4.7);
      expect(hotel.reviewCount, 250);
      expect(hotel.pricePerNight, 3500.0);
      expect(hotel.imageUrl, 'https://example.com/photo.jpg');
      expect(hotel.latitude, 36.8874);
      expect(hotel.longitude, 30.7056);
      expect(hotel.amenities, ['WiFi', 'Havuz', 'Spa']);
      expect(hotel.stars, 5);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final hotel = Hotel.fromJson(json);

      expect(hotel.id, '');
      expect(hotel.name, '');
      expect(hotel.address, '');
      expect(hotel.rating, 0.0);
      expect(hotel.reviewCount, 0);
      expect(hotel.pricePerNight, null);
      expect(hotel.imageUrl, '');
      expect(hotel.latitude, 0.0);
      expect(hotel.longitude, 0.0);
      expect(hotel.amenities, []);
      expect(hotel.stars, 0);
    });

    test('parses rating as int', () {
      final hotel = Hotel.fromJson({'rating': 4});

      expect(hotel.rating, 4.0);
    });

    test('parses reviewCount as string', () {
      final hotel = Hotel.fromJson({'reviewCount': '250'});

      expect(hotel.reviewCount, 250);
    });

    test('parses stars as int', () {
      final hotel = Hotel.fromJson({'stars': 4});

      expect(hotel.stars, 4);
    });

    test('parses amenities as list of various types', () {
      final json = {
        'amenities': ['WiFi', 'Havuz', 123],
      };

      final hotel = Hotel.fromJson(json);

      expect(hotel.amenities, ['WiFi', 'Havuz', '123']);
    });
  });

  group('Hotel toJson', () {
    test('serializes correctly round-trip', () {
      final original = Hotel(
        id: 'h1',
        name: 'Test Otel',
        address: 'Test Adres',
        rating: 4.5,
        reviewCount: 100,
        pricePerNight: 2000.0,
        imageUrl: 'http://photo.url',
        latitude: 41.0,
        longitude: 29.0,
        amenities: ['WiFi'],
        stars: 4,
      );

      final json = original.toJson();

      expect(json['id'], 'h1');
      expect(json['name'], 'Test Otel');
      expect(json['rating'], 4.5);
      expect(json['reviewCount'], 100);
      expect(json['pricePerNight'], 2000.0);
      expect(json['stars'], 4);

      final restored = Hotel.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.rating, original.rating);
    });

    test('handles null pricePerNight in toJson', () {
      final hotel = Hotel(
        id: 'h1',
        name: 'Test',
        address: '',
        rating: 4.0,
        reviewCount: 10,
        pricePerNight: null,
        imageUrl: '',
        latitude: 0,
        longitude: 0,
        amenities: [],
        stars: 3,
      );

      final json = hotel.toJson();
      expect(json['pricePerNight'], null);
    });
  });
}
