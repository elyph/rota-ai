import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/flight_offer.dart';
import 'package:frontend/models/hotel.dart';

/// Budget hesaplama mantığını izole test eder.
/// PlanWizardScreen'deki _toplamMaliyet ve _butceAsildi getter'larıyla aynı mantık.
double hesaplaMaliyet({
  FlightOffer? gidisUcus,
  FlightOffer? donusUcus,
  Hotel? otel,
  DateTime? gidisTarihi,
  DateTime? donusTarihi,
}) {
  double toplam = 0;
  if (gidisUcus != null) toplam += gidisUcus.priceTL;
  if (donusUcus != null) toplam += donusUcus.priceTL;
  if (otel != null && otel.pricePerNight != null) {
    final geceSayisi = donusTarihi != null && gidisTarihi != null
        ? donusTarihi.difference(gidisTarihi).inDays.clamp(1, 365)
        : 1;
    toplam += otel.pricePerNight! * geceSayisi;
  }
  return toplam;
}

bool butceAsildi(double maliyet, double? butce) {
  return butce != null && butce > 0 && maliyet > butce;
}

void main() {
  group('Maliyet hesaplama', () {
    test('sadece gidiş uçuşu seçilmişse uçuş fiyatı döner', () {
      final ucus = FlightOffer.fromJson({'price': 1500, 'departure_time': '08:00'});
      final maliyet = hesaplaMaliyet(gidisUcus: ucus);
      expect(maliyet, 1500.0);
    });

    test('gidiş + dönüş uçuşu toplamı doğru hesaplanır', () {
      final gidis = FlightOffer.fromJson({'price': 1200});
      final donus = FlightOffer.fromJson({'price': 900});
      final maliyet = hesaplaMaliyet(gidisUcus: gidis, donusUcus: donus);
      expect(maliyet, 2100.0);
    });

    test('otel + gece sayısı doğru çarpılır', () {
      final otel = Hotel.fromJson({'name': 'Test', 'pricePerNight': 800.0, 'rating': 4.0, 'reviewCount': 10, 'stars': 3, 'address': '', 'imageUrl': '', 'amenities': [], 'id': 'h1', 'latitude': 0, 'longitude': 0});
      final gidis = DateTime(2025, 7, 1);
      final donus = DateTime(2025, 7, 4); // 3 gece
      final maliyet = hesaplaMaliyet(otel: otel, gidisTarihi: gidis, donusTarihi: donus);
      expect(maliyet, 2400.0); // 800 * 3
    });

    test('tarih yokken otel fiyatı 1 gece sayılır', () {
      final otel = Hotel.fromJson({'name': 'Test', 'pricePerNight': 500.0, 'rating': 4.0, 'reviewCount': 5, 'stars': 3, 'address': '', 'imageUrl': '', 'amenities': [], 'id': 'h2', 'latitude': 0, 'longitude': 0});
      final maliyet = hesaplaMaliyet(otel: otel);
      expect(maliyet, 500.0);
    });

    test('tüm bileşenler birlikte doğru toplanır', () {
      final gidis = FlightOffer.fromJson({'price': 1000});
      final donus = FlightOffer.fromJson({'price': 800});
      final otel = Hotel.fromJson({'name': 'Test', 'pricePerNight': 600.0, 'rating': 4.0, 'reviewCount': 5, 'stars': 3, 'address': '', 'imageUrl': '', 'amenities': [], 'id': 'h3', 'latitude': 0, 'longitude': 0});
      final maliyet = hesaplaMaliyet(
        gidisUcus: gidis,
        donusUcus: donus,
        otel: otel,
        gidisTarihi: DateTime(2025, 8, 1),
        donusTarihi: DateTime(2025, 8, 3), // 2 gece
      );
      expect(maliyet, 3000.0); // 1000 + 800 + 600*2
    });

    test('seçim yoksa maliyet 0 döner', () {
      expect(hesaplaMaliyet(), 0.0);
    });

    test('pricePerNight null olan otel maliyet hesabına girmez', () {
      final otel = Hotel.fromJson({'name': 'Test', 'pricePerNight': null, 'rating': 3.0, 'reviewCount': 5, 'stars': 2, 'address': '', 'imageUrl': '', 'amenities': [], 'id': 'h4', 'latitude': 0, 'longitude': 0});
      final maliyet = hesaplaMaliyet(otel: otel);
      expect(maliyet, 0.0);
    });
  });

  group('Bütçe aşımı kontrolü', () {
    test('maliyet bütçeyi aşıyorsa true döner', () {
      expect(butceAsildi(10000, 8000), true);
    });

    test('maliyet bütçeyi aşmıyorsa false döner', () {
      expect(butceAsildi(7000, 8000), false);
    });

    test('maliyet bütçeye eşitse false döner (aşım yok)', () {
      expect(butceAsildi(8000, 8000), false);
    });

    test('bütçe null ise false döner', () {
      expect(butceAsildi(50000, null), false);
    });

    test('bütçe sıfır ise false döner', () {
      expect(butceAsildi(5000, 0), false);
    });

    test('bütçe negatif ise false döner', () {
      expect(butceAsildi(5000, -1000), false);
    });
  });

  group('Gece sayısı hesaplama', () {
    test('aynı gün giriş-çıkışta 1 gece olarak hesaplanır', () {
      final gidis = DateTime(2025, 7, 1);
      final donus = DateTime(2025, 7, 1);
      final geceSayisi = donus.difference(gidis).inDays.clamp(1, 365);
      expect(geceSayisi, 1);
    });

    test('1 gün aralık 1 gece olarak hesaplanır', () {
      final gidis = DateTime(2025, 7, 1);
      final donus = DateTime(2025, 7, 2);
      final geceSayisi = donus.difference(gidis).inDays.clamp(1, 365);
      expect(geceSayisi, 1);
    });

    test('7 gün aralık 7 gece olarak hesaplanır', () {
      final gidis = DateTime(2025, 7, 1);
      final donus = DateTime(2025, 7, 8);
      final geceSayisi = donus.difference(gidis).inDays.clamp(1, 365);
      expect(geceSayisi, 7);
    });

    test('365 günden uzun süreler 365 ile sınırlandırılır', () {
      final gidis = DateTime(2025, 1, 1);
      final donus = DateTime(2026, 6, 1); // > 365 gün
      final geceSayisi = donus.difference(gidis).inDays.clamp(1, 365);
      expect(geceSayisi, 365);
    });
  });
}
