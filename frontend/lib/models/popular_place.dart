class PopularPlace {
  final String name;
  final String city;
  final String description;
  final String imageUrl;
  final double rating;
  final double latitude;
  final double longitude;
  final String category;

  const PopularPlace({
    required this.name,
    required this.city,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  factory PopularPlace.fromJson(Map<String, dynamic> json) {
    return PopularPlace(
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      category: json['category'] ?? '',
    );
  }

  /// Google Maps URL'ini oluşturur
  String get googleMapsUrl {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=${Uri.encodeComponent(name)}';
  }
}
