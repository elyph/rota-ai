class FlightOffer {
  final String airline;
  final String airlineIata;
  final String flightNumber;
  final String departureAirport;
  final String arrivalAirport;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double priceTL;
  final int stops;
  final String currency;
  final String departureDate;

  const FlightOffer({
    required this.airline,
    this.airlineIata = '',
    required this.flightNumber,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.priceTL,
    required this.stops,
    this.currency = 'TRY',
    this.departureDate = '',
  });

  factory FlightOffer.fromJson(Map<String, dynamic> json) {
    return FlightOffer(
      airline: json['airline'] ?? 'Bilinmeyen Havayolu',
      airlineIata: json['airline_iata'] ?? '',
      flightNumber: json['flight_number'] ?? json['id'] ?? '',
      departureAirport: json['departure_city'] ?? '',
      arrivalAirport: json['arrival_city'] ?? '',
      departureTime: json['departure_time'] ?? '--:--',
      arrivalTime: json['arrival_time'] ?? '--:--',
      duration: json['duration'] ?? '--',
      priceTL: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stops: json['stops'] ?? 0,
      currency: json['currency'] ?? 'TRY',
      departureDate: json['departure_date'] ?? '',
    );
  }
}
