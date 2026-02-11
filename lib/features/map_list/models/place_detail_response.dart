class PlaceDetailResponse {
  final String provider;
  final String providerPlaceId;
  final String name;
  final String category;
  final String address;
  final String roadAddress;
  final String phone;
  final int? distanceMeters;
  final double? latitude;
  final double? longitude;
  final String placeUrl;
  final String sourceKeyword;
  final String imageUrl;
  final List<String> imageUrls;

  const PlaceDetailResponse({
    required this.provider,
    required this.providerPlaceId,
    required this.name,
    required this.category,
    required this.address,
    required this.roadAddress,
    required this.phone,
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
    required this.placeUrl,
    required this.sourceKeyword,
    required this.imageUrl,
    required this.imageUrls,
  });

  factory PlaceDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawImageUrls =
        (json['image_urls'] as List<dynamic>?) ??
        (json['imageUrls'] as List<dynamic>?) ??
        const [];
    return PlaceDetailResponse(
      provider: (json['provider'] as String?) ?? '',
      providerPlaceId:
          (json['provider_place_id'] ?? json['providerPlaceId'])?.toString() ??
          '',
      name: (json['name'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      roadAddress:
          (json['road_address'] ?? json['roadAddress'])?.toString() ?? '',
      phone: (json['phone'] as String?) ?? '',
      distanceMeters: _toInt(json['distance_meters'] ?? json['distanceMeters']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      placeUrl: (json['place_url'] ?? json['placeUrl'])?.toString() ?? '',
      sourceKeyword:
          (json['source_keyword'] ?? json['sourceKeyword'])?.toString() ?? '',
      imageUrl: (json['image_url'] ?? json['imageUrl'])?.toString() ?? '',
      imageUrls:
          rawImageUrls
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.toString());
  }
}
