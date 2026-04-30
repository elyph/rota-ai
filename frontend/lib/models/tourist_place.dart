class TouristPlace {
  final String id;
  final String name;
  final String address;
  final double rating;
  final int userRatingsTotal;
  final List<String> types;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final int priceLevel;
  final bool? openNow;

  const TouristPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.userRatingsTotal,
    required this.types,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.priceLevel,
    this.openNow,
  });

  factory TouristPlace.fromJson(Map<String, dynamic> json) {
    return TouristPlace(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      userRatingsTotal: json['userRatingsTotal'] ?? 0,
      types: List<String>.from(json['types'] ?? []),
      photoUrl: json['photoUrl'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      priceLevel: json['priceLevel'] ?? 0,
      openNow: json['openNow'],
    );
  }

  /// Türkçe kategori adını döndürür
  String get categoryLabel {
    if (types.contains('museum')) return 'Müze';
    if (types.contains('mosque')) return 'Cami';
    if (types.contains('church')) return 'Kilise';
    if (types.contains('park')) return 'Park';
    if (types.contains('art_gallery')) return 'Sanat Galerisi';
    if (types.contains('historical_place')) return 'Tarihi Yer';
    if (types.contains('landmark')) return 'Simge Yapı';
    if (types.contains('natural_feature')) return 'Doğal Güzellik';
    if (types.contains('amusement_park')) return 'Eğlence Parkı';
    if (types.contains('zoo')) return 'Hayvanat Bahçesi';
    if (types.contains('aquarium')) return 'Akvaryum';
    if (types.contains('shopping_mall')) return 'Alışveriş Merkezi';
    return 'Turistik Yer';
  }

  /// Fiyat seviyesini gösteren ₺ sembolleri
  String get priceLabel {
    switch (priceLevel) {
      case 0:
        return 'Ücretsiz';
      case 1:
        return '₺';
      case 2:
        return '₺₺';
      case 3:
        return '₺₺₺';
      case 4:
        return '₺₺₺₺';
      default:
        return '';
    }
  }
}
