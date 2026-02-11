import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'models/place_detail_response.dart';
import 'models/place_search_response.dart';
import 'place_search_api.dart';
import '../room/models/menu_recommendation_response.dart';

class MapListScreen extends StatefulWidget {
  final String roomId;
  final MenuRecommendationResponse recommendation;

  const MapListScreen({
    super.key,
    required this.roomId,
    required this.recommendation,
  });

  @override
  State<MapListScreen> createState() => _MapListScreenState();
}

class _MapListScreenState extends State<MapListScreen> {
  KakaoMapController? _mapController;
  final List<_RestaurantCardItem> _items = [];
  final List<Poi> _pois = [];
  final PlaceSearchApi _placeSearchApi = PlaceSearchApi();
  PoiStyle? _poiStyle;

  LatLng? _origin;
  String? _errorText;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _items.where((item) => item.isSelected).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundTint,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 300, width: double.infinity, child: _buildMap()),
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: Column(
                  children: [
                    if (_errorText != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Text(
                          _errorText!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Expanded(child: _buildList()),
                  ],
                ),
              ),
            ),
            Container(
              height: 100,
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      selectedCount == 0
                          ? null
                          : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '룰렛 화면 연결 예정 ($selectedCount곳 선택됨)',
                                ),
                              ),
                            );
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMain,
                    disabledBackgroundColor: AppColors.border,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    '룰렛 돌리기 ($selectedCount곳 선택됨)',
                    style: AppTextStyles.buttonText.copyWith(
                      color:
                          selectedCount == 0
                              ? AppColors.textSecondary
                              : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_origin == null) {
      return Center(
        child:
            _loading
                ? const CircularProgressIndicator(color: AppColors.primaryMain)
                : Text(
                  '위치 정보를 불러오지 못했습니다',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
      );
    }

    return KakaoMap(
      option: KakaoMapOption(
        position: _origin!,
        zoomLevel: 15,
        mapType: MapType.normal,
      ),
      onMapReady: (controller) {
        _mapController = controller;
        _syncPois();
      },
      onMapError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _errorText = '카카오 지도를 불러오지 못했습니다. 앱 키와 플랫폼 설정을 확인해 주세요.';
        });
      },
    );
  }

  Widget _buildList() {
    if (_loading && _items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMain),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          '표시할 음식점이 없습니다',
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _toggleSelection(index),
          onLongPress: () => _openPlaceDetail(item),
          child: Container(
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    item.isSelected
                        ? AppColors.primaryMain.withValues(alpha: 0.3)
                        : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.info,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      Position? position;
      try {
        position = await _resolvePosition();
      } catch (_) {
        position = null;
      }

      final keywords = _extractKeywords();
      final response = await _placeSearchApi.searchPlaces(
        roomId: widget.roomId,
        latitude: position?.latitude,
        longitude: position?.longitude,
        keywords: keywords,
      );
      final items = _buildItemsFromResponse(response);
      final origin = _resolveOrigin(position, response, items);

      if (!mounted) {
        return;
      }
      setState(() {
        _origin = origin;
        _items
          ..clear()
          ..addAll(items);
        _errorText = items.isEmpty ? '주변에서 검색된 식당이 없습니다.' : null;
      });
      _syncPois();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _items
          ..clear()
          ..addAll(_fallbackItems());
        _errorText = '식당 검색에 실패해 임시 목록을 표시합니다.';
      });
      _syncPois();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<Position> _resolvePosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('위치 서비스 비활성화');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한 거부');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  List<String> _extractKeywords() {
    return widget.recommendation.menus
        .map((menu) => menu.name.trim())
        .where((name) => name.isNotEmpty)
        .take(5)
        .toList();
  }

  List<_RestaurantCardItem> _buildItemsFromResponse(
    PlaceSearchResponse response,
  ) {
    return response.places.asMap().entries.map((entry) {
      final index = entry.key;
      final place = entry.value;
      final distanceText =
          place.distanceMeters != null
              ? '${place.distanceMeters}m'
              : '거리 정보 없음';
      final keywordText =
          place.sourceKeyword.isNotEmpty ? place.sourceKeyword : '추천 메뉴';
      final address =
          place.roadAddress.isNotEmpty ? place.roadAddress : place.address;
      final infoText = '$distanceText • $keywordText • $address';

      return _RestaurantCardItem(
        id:
            place.providerPlaceId.isNotEmpty
                ? place.providerPlaceId
                : 'place_$index',
        name: place.name.isNotEmpty ? place.name : '이름 없는 식당',
        info: infoText,
        providerPlaceId: place.providerPlaceId,
        category: place.category,
        address: place.address,
        roadAddress: place.roadAddress,
        phone: place.phone,
        placeUrl: place.placeUrl,
        sourceKeyword: place.sourceKeyword,
        distanceMeters: place.distanceMeters,
        latitude: place.latitude,
        longitude: place.longitude,
        isSelected: index < 2,
      );
    }).toList();
  }

  LatLng? _resolveOrigin(
    Position? position,
    PlaceSearchResponse response,
    List<_RestaurantCardItem> items,
  ) {
    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    }
    if (response.centerLat != null && response.centerLng != null) {
      return LatLng(response.centerLat!, response.centerLng!);
    }
    for (final item in items) {
      if (item.latitude != null && item.longitude != null) {
        return LatLng(item.latitude!, item.longitude!);
      }
    }
    return null;
  }

  List<_RestaurantCardItem> _fallbackItems() {
    return const [
      _RestaurantCardItem(
        id: 'fallback_1',
        name: '가까운 음식점',
        info: '지도 재구현 중 • 임시 목록',
        providerPlaceId: '',
        category: '',
        address: '',
        roadAddress: '',
        phone: '',
        placeUrl: '',
        sourceKeyword: '',
        distanceMeters: null,
        isSelected: true,
      ),
      _RestaurantCardItem(
        id: 'fallback_2',
        name: '주변 식당',
        info: '지도 재구현 중 • 임시 목록',
        providerPlaceId: '',
        category: '',
        address: '',
        roadAddress: '',
        phone: '',
        placeUrl: '',
        sourceKeyword: '',
        distanceMeters: null,
        isSelected: false,
      ),
    ];
  }

  void _toggleSelection(int index) {
    setState(() {
      final current = _items[index];
      _items[index] = current.copyWith(isSelected: !current.isSelected);
    });

    final item = _items[index];
    if (item.latitude != null && item.longitude != null) {
      _mapController?.moveCamera(
        CameraUpdate.newCenterPosition(
          LatLng(item.latitude!, item.longitude!),
          zoomLevel: 16,
        ),
      );
    }
  }

  Future<PoiStyle> _getPoiStyle() async {
    if (_poiStyle != null) {
      return _poiStyle!;
    }
    final icon = await KImage.fromWidget(
      const Icon(Icons.location_on, color: AppColors.primaryMain, size: 34),
      const Size(34, 34),
      context: context,
    );
    _poiStyle = PoiStyle(icon: icon);
    return _poiStyle!;
  }

  Future<void> _syncPois() async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }

    for (final poi in _pois) {
      try {
        await controller.labelLayer.removePoi(poi);
      } catch (_) {
        // ignore marker cleanup failure on transient map states
      }
    }
    _pois.clear();

    final style = await _getPoiStyle();
    for (final item in _items) {
      final lat = item.latitude;
      final lng = item.longitude;
      if (lat == null || lng == null) {
        continue;
      }
      try {
        final poi = await controller.labelLayer.addPoi(
          LatLng(lat, lng),
          style: style,
          text: item.name,
          onClick: () {
            _openPlaceDetail(item);
          },
        );
        _pois.add(poi);
      } catch (_) {
        // ignore individual marker creation failure
      }
    }
  }

  @override
  void dispose() {
    _pois.clear();
    super.dispose();
  }

  String _normalizeImageUrl(String url) {
    final value = url.trim();
    if (value.isEmpty) {
      return '';
    }
    if (value.startsWith('//')) {
      return 'https:$value';
    }
    if (value.startsWith('http://')) {
      return 'https://${value.substring('http://'.length)}';
    }
    return value;
  }

  Future<void> _openPlaceDetail(_RestaurantCardItem item) async {
    if (item.latitude == null || item.longitude == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상세 조회를 위한 위치 정보가 없습니다.')));
      return;
    }
    if (item.name.trim().isEmpty) {
      return;
    }

    final detailFuture = _placeSearchApi.getPlaceDetail(
      roomId: widget.roomId,
      placeName: item.name,
      providerPlaceId: item.providerPlaceId,
      latitude: item.latitude,
      longitude: item.longitude,
    );
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<PlaceDetailResponse>(
          future: detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryMain,
                  ),
                ),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    '식당 상세 정보를 불러오지 못했습니다',
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }

            final detail = snapshot.data!;
            final address =
                detail.roadAddress.isNotEmpty
                    ? detail.roadAddress
                    : detail.address;
            final effectiveDistance =
                (detail.distanceMeters != null && detail.distanceMeters! > 0)
                    ? detail.distanceMeters
                    : ((item.distanceMeters != null && item.distanceMeters! > 0)
                        ? item.distanceMeters
                        : null);
            final distanceText =
                effectiveDistance == null
                    ? '거리 정보 없음'
                    : '${effectiveDistance}m';
            final keywordText =
                detail.sourceKeyword.isEmpty ? '-' : detail.sourceKeyword;
            final phoneText = detail.phone.isEmpty ? '-' : detail.phone;
            final categoryText =
                detail.category.isEmpty ? '-' : detail.category;
            final placeUrlText =
                detail.placeUrl.isEmpty ? '-' : detail.placeUrl;

            final imageCandidates = <String>[
              ...detail.imageUrls,
              if (detail.imageUrl.isNotEmpty) detail.imageUrl,
            ];
            final uniqueImageUrls =
                imageCandidates
                    .map(_normalizeImageUrl)
                    .toSet()
                    .where((url) => url.isNotEmpty)
                    .toList();

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (uniqueImageUrls.isNotEmpty) ...[
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: uniqueImageUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final imageUrl = uniqueImageUrls[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              width: 280,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  width: 280,
                                  height: 180,
                                  color: AppColors.backgroundTint,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '이미지를 불러오지 못했습니다',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    detail.name,
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(label: '거리', value: distanceText),
                  _DetailRow(label: '카테고리', value: categoryText),
                  _DetailRow(label: '추천 키워드', value: keywordText),
                  _DetailRow(
                    label: '주소',
                    value: address.isEmpty ? '-' : address,
                  ),
                  _DetailRow(label: '전화번호', value: phoneText),
                  _DetailRow(label: '상세 링크', value: placeUrlText),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RestaurantCardItem {
  final String id;
  final String name;
  final String info;
  final String providerPlaceId;
  final String category;
  final String address;
  final String roadAddress;
  final String phone;
  final String placeUrl;
  final String sourceKeyword;
  final int? distanceMeters;
  final double? latitude;
  final double? longitude;
  final bool isSelected;

  const _RestaurantCardItem({
    required this.id,
    required this.name,
    required this.info,
    required this.providerPlaceId,
    required this.category,
    required this.address,
    required this.roadAddress,
    required this.phone,
    required this.placeUrl,
    required this.sourceKeyword,
    required this.distanceMeters,
    this.latitude,
    this.longitude,
    required this.isSelected,
  });

  _RestaurantCardItem copyWith({bool? isSelected}) {
    return _RestaurantCardItem(
      id: id,
      name: name,
      info: info,
      providerPlaceId: providerPlaceId,
      category: category,
      address: address,
      roadAddress: roadAddress,
      phone: phone,
      placeUrl: placeUrl,
      sourceKeyword: sourceKeyword,
      distanceMeters: distanceMeters,
      latitude: latitude,
      longitude: longitude,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
