class FlightOffer {
  final String airline;
  final String flightNumber;
  final String departureAirport;
  final String arrivalAirport;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double priceUSD;
  final int stops;
  final String currency;

  // Sabit dolar kuru
  static const double dolarKuru = 45.0;

  double get priceTL => priceUSD * dolarKuru;

  const FlightOffer({
    required this.airline,
    required this.flightNumber,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.priceUSD,
    required this.stops,
    this.currency = 'USD',
  });

  factory FlightOffer.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] ?? {};
    final slices = json['slices'] as List? ?? [];
    final firstSlice = slices.isNotEmpty ? slices[0] : {};
    final segments = firstSlice['segments'] as List? ?? [];
    final firstSegment = segments.isNotEmpty ? segments[0] : {};
    final lastSegment = segments.isNotEmpty ? segments.last : {};

    final depTime = firstSegment['departing_at'] ?? '';
    final arrTime = lastSegment['arriving_at'] ?? '';
    final depCode = firstSegment['origin']?['iata_code'] ?? '';
    final arrCode = lastSegment['destination']?['iata_code'] ?? '';

    return FlightOffer(
      airline: owner['name'] ?? 'Bilinmeyen Havayolu',
      flightNumber: firstSegment['marketing_carrier_flight_number'] ?? '',
      departureAirport: depCode,
      arrivalAirport: arrCode,
      departureTime: _formatDuffelTime(depTime),
      arrivalTime: _formatDuffelTime(arrTime),
      duration: _formatDuration(firstSlice['duration'] ?? ''),
      priceUSD: (json['total_amount'] is String)
          ? double.tryParse(json['total_amount']) ?? 0.0
          : (json['total_amount'] ?? 0).toDouble(),
      stops: (segments.length - 1),
      currency: json['total_currency'] ?? 'USD',
    );
  }

  static String _formatDuffelTime(String isoTime) {
    if (isoTime.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  static String _formatDuration(String durationStr) {
    if (durationStr.isEmpty) return '--';
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?');
    final match = regex.firstMatch(durationStr);
    if (match == null) return durationStr;
    final hours = match.group(1) ?? '0';
    final minutes = match.group(2) ?? '0';
    return '${hours}s ${minutes}dk';
  }
}
