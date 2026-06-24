class Hotel {
  final String id;
  final String name;
  final String address;
  final double rating;
  final int reviewCount;
  final double? pricePerNight;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final List<String> amenities;
  final int stars;
  final double score;

  Hotel({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.pricePerNight,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.amenities,
    required this.stars,
    required this.score,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return Hotel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      rating: parseDouble(json['rating']),
      reviewCount: (json['reviewCount'] is int) ? json['reviewCount'] : (int.tryParse(json['reviewCount']?.toString() ?? '0') ?? 0),
      pricePerNight: json['pricePerNight'] != null ? parseDouble(json['pricePerNight']) : null,
      imageUrl: json['imageUrl'] ?? '',
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      stars: (json['stars'] is int) ? json['stars'] : (int.tryParse(json['stars']?.toString() ?? '0') ?? 0),
      score: parseDouble(json['score']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rating': rating,
      'reviewCount': reviewCount,
      'pricePerNight': pricePerNight,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'amenities': amenities,
      'stars': stars,
      'score': score,
    };
  }
}
