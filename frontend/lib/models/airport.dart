class Airport {
  final String code;
  final String name;
  final String city;

  const Airport({
    required this.code,
    required this.name,
    required this.city,
  });

  @override
  String toString() => '$city ($code)';
}

class AirportData {
  static const List<Airport> airports = [
    Airport(code: 'IST', name: 'İstanbul Havalimanı', city: 'İstanbul'),
    Airport(code: 'SAW', name: 'Sabiha Gökçen Havalimanı', city: 'İstanbul'),
    Airport(code: 'ESB', name: 'Esenboğa Havalimanı', city: 'Ankara'),
    Airport(code: 'AYT', name: 'Antalya Havalimanı', city: 'Antalya'),
    Airport(code: 'ADB', name: 'Adnan Menderes Havalimanı', city: 'İzmir'),
    Airport(code: 'DLM', name: 'Dalaman Havalimanı', city: 'Muğla'),
    Airport(code: 'BJV', name: 'Milas-Bodrum Havalimanı', city: 'Muğla'),
    Airport(code: 'TZX', name: 'Trabzon Havalimanı', city: 'Trabzon'),
    Airport(code: 'ADA', name: 'Adana Havalimanı', city: 'Adana'),
    Airport(code: 'NAV', name: 'Kapadokya Havalimanı', city: 'Nevşehir'),
    Airport(code: 'GZT', name: 'Gaziantep Havalimanı', city: 'Gaziantep'),
    Airport(code: 'ERZ', name: 'Erzurum Havalimanı', city: 'Erzurum'),
    Airport(code: 'SZF', name: 'Samsun Çarşamba Havalimanı', city: 'Samsun'),
    Airport(code: 'ECN', name: 'Ercan Havalimanı', city: 'Lefkoşa'),
  ];
}
