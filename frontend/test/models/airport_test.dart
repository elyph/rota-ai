import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/airport.dart';

void main() {
  group('Airport', () {
    test('toString returns formatted string', () {
      const airport = Airport(
        code: 'IST',
        name: 'İstanbul Havalimanı',
        city: 'İstanbul',
      );

      expect(airport.toString(), 'İstanbul (IST)');
    });

    test('AirportData contains 14 airports', () {
      expect(AirportData.airports.length, 14);
    });

    test('all airport codes are 3 uppercase letters', () {
      for (final airport in AirportData.airports) {
        expect(airport.code.length, 3);
        expect(airport.code, airport.code.toUpperCase());
      }
    });

    test('major airports are present', () {
      final codes = AirportData.airports.map((a) => a.code).toSet();
      expect(codes, contains('IST'));
      expect(codes, contains('SAW'));
      expect(codes, contains('ESB'));
      expect(codes, contains('AYT'));
      expect(codes, contains('ADB'));
      expect(codes, contains('TZX'));
    });

    test('all airport codes are unique', () {
      final codes = AirportData.airports.map((a) => a.code).toList();
      expect(codes.length, codes.toSet().length);
    });

    test('airports are ordered from largest city', () {
      expect(AirportData.airports[0].city, 'İstanbul');
      expect(AirportData.airports[1].city, 'İstanbul');
      expect(AirportData.airports[2].city, 'Ankara');
    });

    test('all airports have non-empty name and city', () {
      for (final airport in AirportData.airports) {
        expect(airport.name.isNotEmpty, true, reason: '${airport.code} has empty name');
        expect(airport.city.isNotEmpty, true, reason: '${airport.code} has empty city');
      }
    });
  });
}
