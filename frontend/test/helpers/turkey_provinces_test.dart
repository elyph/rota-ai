import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/helpers/turkey_provinces.dart';

void main() {
  group('TurkeyProvince', () {
    test('all provinces have non-empty name and key', () {
      for (final province in turkeyProvinces) {
        expect(province.name.isNotEmpty, true, reason: '${province.key} has empty name');
        expect(province.key.isNotEmpty, true, reason: '${province.name} has empty key');
      }
    });

    test('contains all 81 provinces', () {
      expect(turkeyProvinces.length, 81);
    });

    test('all keys are lowercase and hyphenated', () {
      for (final province in turkeyProvinces) {
        expect(province.key, province.key.toLowerCase());
        expect(province.key, isNot(contains(' ')));
        final special = ['ç', 'ğ', 'ı', 'ö', 'ş', 'ü'];
        final hasTurkishChars = special.any((ch) => province.key.contains(ch));
        if (hasTurkishChars) {
          expect(province.key, contains(RegExp(r'[çğıöşü]')));
        }
      }
    });

    test('all keys are unique', () {
      final keys = turkeyProvinces.map((p) => p.key).toList();
      expect(keys.length, keys.toSet().length);
    });

    test('all names are unique', () {
      final names = turkeyProvinces.map((p) => p.name).toList();
      expect(names.length, names.toSet().length);
    });

    test('first province is Adana', () {
      expect(turkeyProvinces[0].name, 'Adana');
      expect(turkeyProvinces[0].key, 'adana');
    });

    test('last province is Zonguldak', () {
      expect(turkeyProvinces.last.name, 'Zonguldak');
      expect(turkeyProvinces.last.key, 'zonguldak');
    });

    test('major cities are present', () {
      final names = turkeyProvinces.map((p) => p.name).toSet();
      expect(names, contains('İstanbul'));
      expect(names, contains('Ankara'));
      expect(names, contains('İzmir'));
      expect(names, contains('Antalya'));
      expect(names, contains('Bursa'));
      expect(names, contains('Trabzon'));
      expect(names, contains('Gaziantep'));
      expect(names, contains('Diyarbakır'));
    });

    test('backend supported cities are in the list', () {
      final keys = turkeyProvinces.map((p) => p.key).toSet();
      final supportedCities = [
        'istanbul', 'ankara', 'izmir', 'antalya', 'mugla', 'trabzon',
        'adana', 'nevsehir', 'gaziantep', 'erzurum', 'samsun', 'bursa',
        'konya', 'mardin', 'edirne', 'canakkale', 'denizli',
      ];
      for (final city in supportedCities) {
        expect(keys, contains(city), reason: '$city should be in provinces list');
      }
    });

    test('TurkeyProvince const constructor works', () {
      const province = TurkeyProvince(name: 'Test', key: 'test');
      expect(province.name, 'Test');
      expect(province.key, 'test');
    });
  });
}
