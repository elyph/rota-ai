import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/flight_offer.dart';

void main() {
  group('FlightOffer fromJson', () {
    test('parses complete flight data correctly', () {
      final json = {
        'airline': 'Turkish Airlines',
        'flight_number': 'TK123',
        'departure_city': 'İstanbul',
        'arrival_city': 'Ankara',
        'departure_time': '08:00',
        'arrival_time': '09:00',
        'duration': '1s 0dk',
        'price': 750.0,
        'stops': 0,
        'currency': 'TRY',
        'departure_date': '2025-06-15',
      };

      final flight = FlightOffer.fromJson(json);

      expect(flight.airline, 'Turkish Airlines');
      expect(flight.flightNumber, 'TK123');
      expect(flight.departureAirport, 'İstanbul');
      expect(flight.arrivalAirport, 'Ankara');
      expect(flight.departureTime, '08:00');
      expect(flight.arrivalTime, '09:00');
      expect(flight.duration, '1s 0dk');
      expect(flight.priceTL, 750.0);
      expect(flight.stops, 0);
      expect(flight.currency, 'TRY');
      expect(flight.departureDate, '2025-06-15');
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final flight = FlightOffer.fromJson(json);

      expect(flight.airline, 'Bilinmeyen Havayolu');
      expect(flight.flightNumber, '');
      expect(flight.departureAirport, '');
      expect(flight.arrivalAirport, '');
      expect(flight.departureTime, '--:--');
      expect(flight.arrivalTime, '--:--');
      expect(flight.duration, '--');
      expect(flight.priceTL, 0.0);
      expect(flight.stops, 0);
      expect(flight.currency, 'TRY');
      expect(flight.departureDate, '');
    });

    test('parses price as int', () {
      final json = {'price': 500};

      final flight = FlightOffer.fromJson(json);

      expect(flight.priceTL, 500.0);
    });

    test('parses price as string', () {
      final json = {'price': '1200.50'};

      final flight = FlightOffer.fromJson(json);

      expect(flight.priceTL, 1200.5);
    });

    test('uses id field as flightNumber when flight_number is missing', () {
      final json = {'id': 'PC456'};

      final flight = FlightOffer.fromJson(json);

      expect(flight.flightNumber, 'PC456');
    });

    test('flight_number takes priority over id', () {
      final json = {
        'flight_number': 'TK789',
        'id': 'PC456',
      };

      final flight = FlightOffer.fromJson(json);

      expect(flight.flightNumber, 'TK789');
    });
  });

  group('FlightOffer immutability', () {
    test('all fields are final and const constructor works', () {
      const flight = FlightOffer(
        airline: 'Pegasus',
        flightNumber: 'PC100',
        departureAirport: 'İstanbul',
        arrivalAirport: 'İzmir',
        departureTime: '10:00',
        arrivalTime: '11:00',
        duration: '1s 0dk',
        priceTL: 500.0,
        stops: 0,
      );

      expect(flight.airline, 'Pegasus');
      expect(flight.priceTL, 500.0);
    });
  });
}
