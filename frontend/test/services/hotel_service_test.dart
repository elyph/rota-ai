import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/hotel.dart';

void main() {
  group('Hotel fromJson with service response format', () {
    test('parses hotel from backend API response correctly', () {
      final json = {
        'id': 'hotel_123',
        'name': 'Swissotel Büyük Efes',
        'address': 'İzmir Merkez',
        'rating': 4.5,
        'reviewCount': 320,
        'pricePerNight': 4800,
        'imageUrl': 'https://example.com/photo.jpg',
        'latitude': 38.42,
        'longitude': 27.14,
        'amenities': ['WiFi', 'Spa', 'Restoran'],
        'stars': 5,
      };

      final hotel = Hotel.fromJson(json);

      expect(hotel.name, 'Swissotel Büyük Efes');
      expect(hotel.rating, 4.5);
      expect(hotel.pricePerNight, 4800);
      expect(hotel.stars, 5);
    });

    test('parses hotel with minimum fields', () {
      final json = {
        'id': 'min_hotel',
        'name': 'Budget Hotel',
        'address': '',
        'rating': 3.0,
        'reviewCount': 5,
        'pricePerNight': null,
        'imageUrl': '',
        'latitude': 0,
        'longitude': 0,
        'amenities': [],
        'stars': 2,
      };

      final hotel = Hotel.fromJson(json);

      expect(hotel.name, 'Budget Hotel');
      expect(hotel.pricePerNight, null);
      expect(hotel.amenities, []);
    });

    test('toJson round-trip preserves data', () {
      final original = Hotel(
        id: 'h1',
        name: 'Test Otel',
        address: 'Adres',
        rating: 4.0,
        reviewCount: 100,
        pricePerNight: 2500.0,
        imageUrl: 'http://img.url',
        latitude: 41.0,
        longitude: 29.0,
        amenities: ['WiFi', 'Havuz'],
        stars: 4,
      );

      final json = original.toJson();
      final restored = Hotel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.rating, original.rating);
      expect(restored.pricePerNight, original.pricePerNight);
      expect(restored.amenities, original.amenities);
    });
  });
}
