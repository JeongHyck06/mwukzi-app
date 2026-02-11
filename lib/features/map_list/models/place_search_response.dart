class PlaceSearchResponse {
  final double? centerLat;
  final double? centerLng;
  final int? radiusMeters;
  final List<String> keywordsUsed;
  final List<PlaceSearchItem> places;

  const PlaceSearchResponse({
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
    required this.keywordsUsed,
    required this.places,
  });

  factory PlaceSearchResponse.fromJson(Map<String, dynamic> json) {
    final rawKeywords =
        (json['keywords_used'] as List<dynamic>?) ??
        (json['keywordsUsed'] as List<dynamic>?) ??
        const [];
    final rawPlaces = (json['places'] as List<dynamic>?) ?? const [];

    return PlaceSearchResponse(
      centerLat: _toDouble(json['center_lat'] ?? json['centerLat']),
      centerLng: _toDouble(json['center_lng'] ?? json['centerLng']),
      radiusMeters: _toInt(json['radius_meters'] ?? json['radiusMeters']),
      keywordsUsed:
          rawKeywords
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(),
      places:
          rawPlaces
              .map(
                (item) =>
                    PlaceSearchItem.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    return int.tryParse(value.toString());
  }
}

class PlaceSearchItem {
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

  const PlaceSearchItem({
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
  });

  factory PlaceSearchItem.fromJson(Map<String, dynamic> json) {
    return PlaceSearchItem(
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
      distanceMeters: PlaceSearchResponse._toInt(
        json['distance_meters'] ?? json['distanceMeters'],
      ),
      latitude: PlaceSearchResponse._toDouble(json['latitude']),
      longitude: PlaceSearchResponse._toDouble(json['longitude']),
      placeUrl: (json['place_url'] ?? json['placeUrl'])?.toString() ?? '',
      sourceKeyword:
          (json['source_keyword'] ?? json['sourceKeyword'])?.toString() ?? '',
    );
  }
}
