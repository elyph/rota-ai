import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/helpers/date_helper.dart';

void main() {
  group('DateHelper.formatDate', () {
    test('formats January correctly', () {
      final date = DateTime(2025, 1, 15);
      expect(DateHelper.formatDate(date), '15 Ocak 2025');
    });

    test('formats February correctly', () {
      final date = DateTime(2025, 2, 1);
      expect(DateHelper.formatDate(date), '1 Şubat 2025');
    });

    test('formats March correctly', () {
      final date = DateTime(2025, 3, 10);
      expect(DateHelper.formatDate(date), '10 Mart 2025');
    });

    test('formats April correctly', () {
      final date = DateTime(2025, 4, 20);
      expect(DateHelper.formatDate(date), '20 Nisan 2025');
    });

    test('formats May correctly', () {
      final date = DateTime(2025, 5, 19);
      expect(DateHelper.formatDate(date), '19 Mayıs 2025');
    });

    test('formats June correctly', () {
      final date = DateTime(2025, 6, 15);
      expect(DateHelper.formatDate(date), '15 Haziran 2025');
    });

    test('formats July correctly', () {
      final date = DateTime(2025, 7, 1);
      expect(DateHelper.formatDate(date), '1 Temmuz 2025');
    });

    test('formats August correctly', () {
      final date = DateTime(2025, 8, 30);
      expect(DateHelper.formatDate(date), '30 Ağustos 2025');
    });

    test('formats September correctly', () {
      final date = DateTime(2025, 9, 5);
      expect(DateHelper.formatDate(date), '5 Eylül 2025');
    });

    test('formats October correctly', () {
      final date = DateTime(2025, 10, 29);
      expect(DateHelper.formatDate(date), '29 Ekim 2025');
    });

    test('formats November correctly', () {
      final date = DateTime(2025, 11, 10);
      expect(DateHelper.formatDate(date), '10 Kasım 2025');
    });

    test('formats December correctly', () {
      final date = DateTime(2025, 12, 31);
      expect(DateHelper.formatDate(date), '31 Aralık 2025');
    });

    test('returns Seçiniz for null date', () {
      expect(DateHelper.formatDate(null), 'Seçiniz');
    });

    test('handles leap year February correctly', () {
      final date = DateTime(2024, 2, 29);
      expect(DateHelper.formatDate(date), '29 Şubat 2024');
    });

    test('formats single digit day without leading zero', () {
      final date = DateTime(2025, 6, 5);
      expect(DateHelper.formatDate(date), '5 Haziran 2025');
    });
  });
}
