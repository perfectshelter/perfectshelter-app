import 'package:ebroker/data/repositories/map.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:flutter/material.dart';

class PropertyMapScreen extends StatefulWidget {
  const PropertyMapScreen({super.key});

  static Route<dynamic> route(RouteSettings settings) {
    // Map? arguments = settings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) {
        return const PropertyMapScreen();
      },
    );
  }

  @override
  State<PropertyMapScreen> createState() => _PropertyMapScreenState();
}

class _PropertyMapScreenState extends State<PropertyMapScreen> {
  late String _darkMapStyle;
  final TextEditingController _searchController = TextEditingController();
  String previouseSearchQuery = '';
  LatLng? citylatLong;
  Timer? _timer;
  Set<Marker> marker = {};
  Map<dynamic, dynamic> map = {};
  GoogleMapController? _googleMapController;
  Completer<GoogleMapController> completer = Completer();
  bool isMapCreated = false;
  final FocusNode _searchFocus = FocusNode();
  List<GooglePlaceModel>? cities;
  int selectedMarker = 999999999999999;
  int? propertyId;
  ValueNotifier<bool> isLoadingProperty = ValueNotifier<bool>(false);
  PropertyModel? activePropertyModal;
  List<PropertyModel>? activePropertiesList;
  ValueNotifier<bool> loadintCitiesInProgress = ValueNotifier<bool>(false);
  bool showSellRentLables = false;
  bool showGoogleMap = true;
  late BitmapDescriptor customIconSell;
  late BitmapDescriptor customIconRent;
  late BitmapDescriptor customIconSelected;
  String? assetName;
  double iconWidth = 24;
  double iconHeight = 32;
  Future<void> _loadMapStyles() async {
    _darkMapStyle =
        await rootBundle.loadString('assets/map_styles/dark_map.json');
  }

  Future<void> searchDelayTimer() async {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
    _timer = Timer(
      const Duration(milliseconds: 500),
      () async {
        if (_searchController.text.isNotEmpty) {
          if (previouseSearchQuery != _searchController.text) {
            try {
              loadintCitiesInProgress.value = true;
              cities = await GooglePlaceRepository().serchCities(
                _searchController.text,
              );
              loadintCitiesInProgress.value = false;
            } on Exception catch (_) {
              loadintCitiesInProgress.value = false;
            }

            setState(() {});
            previouseSearchQuery = _searchController.text;
          }
        } else {
          cities = null;
        }
      },
    );
    setState(() {});
  }

  @override
  void initState() {
    _loadMapStyles();
    _loadCustomRentIcon();
    _loadCustomSelectedIcon();
    _loadCustomSellIcon();
    loadAll();
    _searchController.addListener(searchDelayTimer);
    super.initState();
  }

  LatLng cameraPosition = LatLng(
    double.parse(AppSettings.latitude),
    double.parse(AppSettings.longitude),
  );

  Future<void> loadAll() async {
    try {
      isLoadingProperty.value = true;
      final pointList = await GMap.getNearByProperty(
        '',
        '',
        '',
        '',
      );
      activePropertiesList = pointList;

      //Animate camera to location
      await loopMarker(pointList);
      isLoadingProperty.value = false;
    } on Exception catch (e) {
      isLoadingProperty.value = false;
      await HelperUtils.showSnackBarMessage(context, '$e'.translate(context));
    } finally {
      isLoadingProperty.value = false;
    }
  }

  Future<void> onTapCity(int index) async {
    try {
      unawaited(Widgets.showLoader(context));
      final pointList = await GMap.getNearByProperty(
        cities?.elementAt(index).city ?? '',
        cities?.elementAt(index).latitude ?? '',
        cities?.elementAt(index).longitude ?? '',
        cities?.elementAt(index).placeId ?? '',
      );

      if (pointList.isEmpty) {
        marker = {};
        setState(() {});
      }

      final latLng = await getCityLatLongByIndex(index);

      if (latLng != null) {
        try {
          final controller = await completer.future.timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              throw TimeoutException('Map controller not available');
            },
          );
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: latLng, zoom: 7),
            ),
          );
        } on Exception catch (e) {
          await HelperUtils.showSnackBarMessage(
            context,
            '$e'.translate(context),
          );
        }
      } else {}

      await loopMarker(pointList);
      _searchFocus.unfocus();
      HelperUtils.unfocus();
      Future.delayed(
        Duration.zero,
        () {
          Widgets.hideLoder(context);
        },
      );
      cities = null;
      setState(() {});
    } on Exception catch (e) {
      Widgets.hideLoder(context);
      await HelperUtils.showSnackBarMessage(context, e.toString());
    }
  }

  Future<void> _loadCustomRentIcon() async {
    customIconRent = await BitmapDescriptor.asset(
      width: iconWidth,
      height: iconHeight,
      const ImageConfiguration(size: Size(50, 100)),
      'assets/location_rent.png',
    );
    setState(() {});
  }

  Future<void> _loadCustomSelectedIcon() async {
    customIconSelected = await BitmapDescriptor.asset(
      width: iconWidth,
      height: iconHeight,
      const ImageConfiguration(size: Size(50, 100)),
      'assets/location_selected.png',
    );
    setState(() {});
  }

  Future<void> _loadCustomSellIcon() async {
    customIconSell = await BitmapDescriptor.asset(
      width: iconWidth,
      height: iconHeight,
      const ImageConfiguration(size: Size(50, 100)),
      'assets/location_sell.png',
    );
    setState(() {});
  }

  Future<void> loopMarker(List<PropertyModel> pointList) async {
    marker.clear(); // Clear existing markers
    for (var i = 0; i < pointList.length; i++) {
      final element = pointList[i];

      if (selectedMarker == i) {
        assetName = 'assets/location_pin_red.png';
      } else if (element.propertyType == '0') {
        assetName = 'assets/location_pin_green.png';
      } else {
        assetName = 'assets/location_pin_orange.png';
      }

      // Create a custom icon for each marker with its property name

      // Safely parse latitude and longitude with error handling
      double? lat;
      double? lng;

      try {
        lat = element.latitude!.isNotEmpty
            ? double.parse(element.latitude!)
            : null;
        lng = element.longitude!.isNotEmpty
            ? double.parse(element.longitude!)
            : null;
      } on Exception catch (_) {
        // Skip this marker if parsing fails
        continue;
      }

      // Only add marker if both lat and lng are valid
      if (lat != null && lng != null) {
        marker.add(
          Marker(
            icon: selectedMarker == i
                ? customIconSelected
                : element.propertyType.toString().toLowerCase() == 'sell'
                    ? customIconSell
                    : customIconRent,
            markerId: MarkerId('$i'),
            onTap: () async {
              try {
                selectedMarker = i;
                propertyId = element.id;

                activePropertyModal = element;
                await loopMarker(pointList);
                setState(() {});
              } on Exception catch (e) {
                await HelperUtils.showSnackBarMessage(
                  context,
                  '$e'.translate(context),
                );
              }
            },
            position: LatLng(lat, lng),
          ),
        );
      }
    }
    setState(() {});
  }

  Future<LatLng?>? getCityLatLongByIndex(dynamic index) async {
    // var rawCityLatLong = await GooglePlaceRepository()
    //     .getPlaceDetailsFromPlaceId(cities?.elementAt(index).placeId ?? "");

    final latLng =
        await getCityLatLong(cities?.elementAt(index as int).placeId ?? '');
    return latLng;
  }

  Future<LatLng> getCityLatLong(String placeId) async {
    final rawCityLatLong =
        await GooglePlaceRepository().getPlaceDetailsFromPlaceId(
      placeId,
    );

    final citylatLong = LatLng(
      rawCityLatLong['lat'] as double,
      rawCityLatLong['lng'] as double,
    );
    return citylatLong;
  }

  @override
  Future<void> dispose() async {
    _googleMapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget buildSearchIcon({required VoidCallback onTap, required bool isClose}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: CustomImage(
          imageUrl: isClose ? AppIcons.closeCircle : AppIcons.search,
          color: context.color.tertiaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _googleMapController?.dispose();
        (await completer.future).dispose();
        showGoogleMap = false;
        setState(() {});
        Future.delayed(Duration.zero, () {
          Navigator.of(context).pop();
        });
      },
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: CustomAppBar(
          title: CustomTextFormField(
            controller: _searchController,
            borderColor: Colors.transparent,
            fillColor: context.color.secondaryColor,
            hintText: UiUtils.translate(context, 'searchHintLbl'),
            prefix: buildSearchIcon(
              isClose: cities != null,
              onTap: () {
                if (cities != null) {
                  cities = null;
                  _searchController.text = '';
                  setState(() {});
                }
              },
            ),
          ),
        ),
        body: Stack(
          children: [
            if (showGoogleMap)
              GoogleMap(
                onCameraMove: (position) {
                  HelperUtils.unfocus();
                },
                style: context.color.brightness == Brightness.dark
                    ? _darkMapStyle
                    : null,
                markers: marker,
                onMapCreated: (controller) {
                  if (!completer.isCompleted) {
                    completer.complete(controller);
                    isMapCreated = true;
                  } else {}
                  showSellRentLables = true;
                  setState(() {});
                },
                onTap: (argument) {
                  activePropertyModal = null;
                  selectedMarker = 99999999999999;
                  setState(() {});
                },
                compassEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                initialCameraPosition: CameraPosition(
                  target: cameraPosition,
                  zoom: 3,
                ),
              ),
            sellRentLable(context),
            if (cities != null)
              ColoredBox(
                color: context.color.backgroundColor,
                child: ListView.builder(
                  itemCount: cities?.length ?? 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () async {
                        activePropertyModal = null;
                        setState(() {});
                        await onTapCity(index);
                      },
                      leading: SvgPicture.asset(
                        AppIcons.location,
                        colorFilter: ColorFilter.mode(
                          context.color.textColorDark,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: CustomText(cities?.elementAt(index).city ?? ''),
                      subtitle: CustomText(
                        "${cities?.elementAt(index).state ?? ""},${cities?.elementAt(index).country ?? ""}",
                      ),
                    );
                  },
                ),
              ),
            PositionedDirectional(
              top: 0,
              end: 0,
              child: ValueListenableBuilder(
                valueListenable: isLoadingProperty,
                builder: (context, va, c) {
                  if (va == false) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsetsDirectional.only(
                      end: 8,
                      top: 8,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(
                        context.color.tertiaryColor,
                        context.color.secondaryColor,
                        0.8,
                      ),
                    ),
                    child: UiUtils.progress(
                      height: 20.rh(context),
                      width: 20.rw(context),
                    ),
                  );
                },
              ),
            ),
            PositionedDirectional(
              bottom: 8,
              child: cities != null
                  ? const SizedBox.shrink()
                  : activePropertyModal != null
                      ? SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: PropertyHorizontalCard(
                              showLikeButton: false,
                              property: activePropertyModal!,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Padding sellRentLable(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: context.color.borderColor),
              borderRadius: BorderRadius.circular(4),
              color: context.color.secondaryColor,
            ),
            child: Row(
              children: [
                Container(
                  width: 18.rw(context),
                  height: 18.rh(context),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(
                  width: 3,
                ),
                CustomText(
                  'sell'.translate(context),
                  color: context.color.inverseSurface,
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: context.color.borderColor),
              borderRadius: BorderRadius.circular(4),
              color: context.color.secondaryColor,
            ),
            child: Row(
              children: [
                Container(
                  width: 18.rw(context),
                  height: 18.rh(context),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(
                  width: 3,
                ),
                CustomText(
                  'rent'.translate(context),
                  color: context.color.inverseSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
