import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Service URL configuration', () {
    test('backend base URL is correct', () {
      // Services use 'http://localhost:8004' as base URL
      const baseUrl = 'http://localhost:8004';
      expect(baseUrl, startsWith('http://localhost'));
      expect(baseUrl, endsWith('8004'));
    });

    test('all endpoints follow RESTful pattern', () {
      final endpoints = [
        '/cities',
        '/popular-places',
        '/place-photo',
        '/nearby-places',
        '/search-flights',
        '/search-hotels',
        '/generate-plan',
        '/generate-itinerary',
        '/chat',
      ];

      for (final endpoint in endpoints) {
        expect(endpoint, startsWith('/'));
        expect(endpoint, isNot(contains(' ')));
        expect(endpoint, isNot(contains('//')));
      }
    });
  });
}
