import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
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
  final PlaceSearchApi _placeSearchApi = PlaceSearchApi();

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
        isSelected: true,
      ),
      _RestaurantCardItem(
        id: 'fallback_2',
        name: '주변 식당',
        info: '지도 재구현 중 • 임시 목록',
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
}

class _RestaurantCardItem {
  final String id;
  final String name;
  final String info;
  final double? latitude;
  final double? longitude;
  final bool isSelected;

  const _RestaurantCardItem({
    required this.id,
    required this.name,
    required this.info,
    this.latitude,
    this.longitude,
    required this.isSelected,
  });

  _RestaurantCardItem copyWith({bool? isSelected}) {
    return _RestaurantCardItem(
      id: id,
      name: name,
      info: info,
      latitude: latitude,
      longitude: longitude,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
