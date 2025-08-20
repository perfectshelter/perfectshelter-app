import 'package:dio/dio.dart';
import 'package:perfectshelter/data/cubits/fetch_home_page_data_cubit.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class ChooseLocationMap extends StatefulWidget {
  const ChooseLocationMap({
    super.key,
    this.from,
  });

  final String? from;

  static Route<dynamic> route(RouteSettings settings) {
    final arguments = settings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) {
        return ChooseLocationMap(
          from: arguments?['from'] as String? ?? '',
        );
      },
    );
  }

  @override
  State<ChooseLocationMap> createState() => _ChooseLocationMapState();
}

class _ChooseLocationMapState extends State<ChooseLocationMap> {
  late String _darkMapStyle;
  double radius =
      double.parse(HiveUtils.getRadius() as String? ?? AppSettings.minRadius);
  bool isFirstTime = true;
  Set<Circle> circles = {};
  final TextEditingController _searchController = TextEditingController();
  String previouseSearchQuery = '';
  LatLng? citylatLong;
  Timer? _timer;
  Marker? marker;
  Map<dynamic, dynamic> map = {};
  Completer<GoogleMapController> completer = Completer<GoogleMapController>();
  GoogleMapController? _googleMapController;
  final FocusNode _searchFocus = FocusNode();
  List<GooglePlaceModel>? cities;
  int selectedMarker = 999999999999999;
  int? propertyId;
  ValueNotifier<bool> isLoadingProperty = ValueNotifier<bool>(false);
  ValueNotifier<bool> loadintCitiesInProgress = ValueNotifier<bool>(false);
  bool showGoogleMap = false;

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

  late LatLng assigned = LatLng(
    double.parse(AppSettings.latitude),
    double.parse(AppSettings.longitude),
  );
  late LatLng cameraPosition = assigned;

  Future<void> setCurrentLocation() async {
    try {
      final locationPermission = await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.denied) {
        await Geolocator.requestPermission();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final controller = await completer.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 7,
          ),
        ),
      );

      marker = Marker(
        markerId: const MarkerId('9999999'),
        position: LatLng(position.latitude, position.longitude),
      );

      setState(() {});
    } on Exception catch (e) {
      debugPrint('Error in setCurrentLocation: $e');
    }
  }

  @override
  void initState() {
    _loadMapStyles();
    _searchController.addListener(searchDelayTimer);
    if (AppSettings.latitude == '' || AppSettings.longitude == '') {
      marker = Marker(markerId: const MarkerId('9999999'), position: assigned);

      setState(() {});
    } else {
      setCurrentLocation();
    }
    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        showGoogleMap = true;
        setState(() {});
      },
    );

    super.initState();
  }

  Future<void> _loadMapStyles() async {
    _darkMapStyle =
        await rootBundle.loadString('assets/map_styles/dark_map.json');
  }

  Future<void> onTapCity(int index) async {
    try {
      final latLng = await getCityLatLong(index);

      if (latLng != null) {
        final controller = await completer.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 7),
          ),
        );

        marker = Marker(
          markerId: MarkerId(index.toString()),
          position: latLng,
        );

        _searchFocus.unfocus();
        HelperUtils.unfocus();

        cities = null;
        setState(() {});
        Widgets.hideLoder(context);
      }
    } on Exception catch (e) {
      debugPrint('Error in onTapCity: $e');
    } finally {
      Widgets.hideLoder(context);
    }
  }

  Future<LatLng?>? getCityLatLong(dynamic index) async {
    final rawCityLatLong =
        await GooglePlaceRepository().getPlaceDetailsFromPlaceId(
      cities?.elementAt(index as int).placeId ?? '',
    );

    final citylatLong = LatLng(
      rawCityLatLong['lat'] as double,
      rawCityLatLong['lng'] as double,
    );
    return citylatLong;
  }

  @override
  Future<void> dispose() async {
    _searchController.removeListener(searchDelayTimer);
    _timer?.cancel();
    if (_googleMapController != null) {
      _googleMapController!.dispose();
    }
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String? getComponent(List<dynamic> data, dynamic dm) {
    try {
      return data
          .where((element) {
            return (element['types'] as List).contains(dm);
          })
          .first['long_name']
          ?.toString();
    } on Exception catch (_) {
      return '';
    }
  }

  Widget buildSearchIcon() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CustomImage(
        imageUrl: AppIcons.search,
        color: context.color.tertiaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.from == 'home_location' && isFirstTime) {
      isFirstTime = false;
      if (HiveUtils.getLatitude() != '' &&
          HiveUtils.getLongitude() != '' &&
          HiveUtils.getLatitude() != null &&
          HiveUtils.getLongitude() != null) {
        _addCircle(
          LatLng(
            double.parse(HiveUtils.getLatitude().toString()),
            double.parse(HiveUtils.getLongitude().toString()),
          ),
          radius,
        );
      }
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_googleMapController != null) {
          _googleMapController!.dispose();
        }
        showGoogleMap = false;
        setState(() {});

        Future.delayed(Duration.zero, () {
          Navigator.of(context).pop();
        });
      },
      child: Scaffold(
        backgroundColor: context.color.secondaryColor,
        appBar: CustomAppBar(
          title: CustomText('chooseLocation'.translate(context)),
          actions: [
            if (widget.from == 'home_location' && marker != null)
              GestureDetector(
                onTap: () {
                  marker = null;
                  circles.clear();
                  radius = double.parse(AppSettings.minRadius);
                  setState(() {});
                },
                child: CustomText(
                  'clear'.translate(context),
                  color: context.color.tertiaryColor,
                  fontSize: context.font.sm,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.from == 'home_location') buildRadiusSelector(),
            if (widget.from != 'home_location') const SizedBox(height: 16),
            UiUtils.buildButton(
              context,
              height: 48.rh(context),
              outerPadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 24,
              ),
              onPressed: marker == null
                  ? () {
                      HelperUtils.showSnackBarMessage(
                        context,
                        'pleaseSelectLocation'.translate(context),
                        messageDuration: 5,
                      );
                    }
                  : () async {
                      try {
                        String? state = '';
                        String? city = '';
                        String? country = '';
                        final placeApiUrl =
                            'https://maps.googleapis.com/maps/api/geocode/json?key=$demoPlaceApiKey&language=en&latlng=${marker?.position.latitude},${marker?.position.longitude}';
                        final response = await Dio().get<dynamic>(placeApiUrl);

                        final component = List<dynamic>.from(
                          response.data['results'][0]['address_components']
                                  as List? ??
                              [],
                        );

                        city = getComponent(component, 'locality') ?? '';
                        state = getComponent(
                                component, 'administrative_area_level_1') ??
                            '';
                        country = getComponent(component, 'country') ?? '';

                        final place = Placemark(
                          locality: city,
                          administrativeArea: state,
                          country: country,
                        );

                        showGoogleMap = false;

                        setState(() {});

                        Future.delayed(
                          Duration.zero,
                          () async {
                            if (widget.from == 'home_location') {
                              await HiveUtils.setHomeLocation(
                                city: place.locality.toString(),
                                state: place.administrativeArea.toString(),
                                latitude: marker!.position.latitude.toString(),
                                longitude:
                                    marker!.position.longitude.toString(),
                                country: place.country.toString(),
                                placeId: HiveUtils.getHomeCityPlaceId()
                                        ?.toString() ??
                                    '',
                                radius: radius.toString(),
                              );
                              setState(() {});
                            } else {
                              await HiveUtils.setLocation(
                                city: place.locality.toString(),
                                state: place.administrativeArea.toString(),
                                latitude: marker!.position.latitude.toString(),
                                longitude:
                                    marker!.position.longitude.toString(),
                                country: place.country.toString(),
                                placeId: HiveUtils.getUserCityPlaceId()
                                        ?.toString() ??
                                    '',
                              );
                              setState(() {});
                            }

                            Navigator.pop<Map<dynamic, dynamic>>(context, {
                              'latlng': LatLng(
                                marker!.position.latitude,
                                marker!.position.longitude,
                              ),
                              'place': place,
                              if (widget.from == 'home_location')
                                'radius': radius.toString(),
                            });
                            if (widget.from == 'home_location') {
                              unawaited(context
                                  .read<FetchHomePageDataCubit>()
                                  .fetch(forceRefresh: true));
                            }
                          },
                        );
                      } on Exception catch (e) {
                        if (e.toString().contains('error_message')) {
                          await HelperUtils.showSnackBarMessage(
                            context,
                            e.toString(),
                          );
                        }

                        if (e.toString().contains('IO_ERROR')) {
                          await HelperUtils.showSnackBarMessage(
                            context,
                            'pleaseChangeNetwork'.translate(context),
                          );
                        }
                      }
                    },
              buttonTitle: widget.from == 'home_location'
                  ? 'apply'.translate(context)
                  : 'proceed'.translate(context),
            ),
          ],
        ),
        body: Stack(
          children: [
            SizedBox(
              height: context.screenHeight,
              width: context.screenWidth,
              child: showGoogleMap == true
                  ? GoogleMap(
                      style: context.color.brightness == Brightness.dark
                          ? _darkMapStyle
                          : null,
                      markers: marker == null ? {} : {marker!},
                      circles: circles,
                      onCameraMove: (position) =>
                          FocusScope.of(context).unfocus(),
                      onMapCreated: (GoogleMapController controller) {
                        if (!completer.isCompleted) {
                          completer.complete(controller);
                          _googleMapController = controller;
                        }
                        setState(() {});
                      },
                      onTap: (argument) async {
                        setState(() {
                          selectedMarker = 99999999999999;
                          cameraPosition = LatLng(
                            argument.latitude,
                            argument.longitude,
                          );
                          marker = Marker(
                            markerId: const MarkerId('0'),
                            position: cameraPosition,
                          );
                          _addCircle(
                            LatLng(
                              marker!.position.latitude,
                              marker!.position.longitude,
                            ),
                            radius,
                          );
                        });
                      },
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      trafficEnabled: true,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: true,
                      initialCameraPosition:
                          CameraPosition(target: cameraPosition, zoom: 7),
                      key: const Key('G-map'),
                    )
                  : const SizedBox.shrink(),
            ),
            if (cities != null)
              ColoredBox(
                color: context.color.backgroundColor,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 64.rh(context)),
                  itemCount: cities?.length ?? 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () async {
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
                        '',
                        isRichText: true,
                        textSpan: TextSpan(
                          text: cities?.elementAt(index).state ?? '',
                          children: [
                            if (cities?.elementAt(index).country != '')
                              TextSpan(
                                text:
                                    ',${cities?.elementAt(index).country ?? ''}',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ValueListenableBuilder(
              valueListenable: loadintCitiesInProgress,
              builder: (context, value, child) {
                if (cities == null && loadintCitiesInProgress.value == true) {
                  return ColoredBox(
                    color: context.color.backgroundColor,
                    child: Center(
                      child: UiUtils.progress(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            PositionedDirectional(
              top: 0,
              start: 0,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: context.color.secondaryColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: context.color.borderColor),
                    ),
                    margin:
                        const EdgeInsetsDirectional.only(top: 16, start: 16),
                    height: 48.rh(context),
                    width: context.screenWidth - 80.rw(context),
                    child: CustomTextFormField(
                      controller: _searchController,
                      borderColor: Colors.transparent,
                      hintText: 'searhCity'.translate(context),
                      prefix: GestureDetector(
                        onTap: () {
                          if (_searchController.text.isEmpty &&
                              cities == null) {
                            return;
                          }
                          cities = null;
                          _searchController.text = '';
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 16,
                            end: 8,
                          ),
                          child: CustomImage(
                            width: 24.rw(context),
                            height: 24.rh(context),
                            imageUrl:
                                _searchController.text.isEmpty && cities == null
                                    ? AppIcons.search
                                    : AppIcons.closeCircle,
                            color: context.color.tertiaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: context.color.secondaryColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: context.color.borderColor),
                    ),
                    margin: const EdgeInsetsDirectional.only(
                      top: 16,
                      start: 8,
                      end: 16,
                    ),
                    height: 48.rh(context),
                    width: 48.rw(context),
                    child: GestureDetector(
                      onTap: () async {
                        if (marker == null) {
                          return;
                        }
                        await _googleMapController?.animateCamera(
                          duration: const Duration(milliseconds: 300),
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: marker!.position, zoom: 7),
                          ),
                        );
                        setState(() {});
                      },
                      child: Icon(
                        Icons.my_location_sharp,
                        color: context.color.textColorDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRadiusSelector() {
    final minRadius = double.parse(
      AppSettings.minRadius.isEmpty ? '1' : AppSettings.minRadius,
    );
    return Container(
      color: context.color.secondaryColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'selectAreaRange'.translate(context),
            color: context.color.textColorDark,
            fontSize: context.font.md,
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 8),
          UiUtils.getDivider(context),
          const SizedBox(height: 8),
          CustomText(
            '${'range'.translate(context)} : ${radius.toInt()} ${AppSettings.distanceOption.translate(context)}',
            color: context.color.textColorDark,
            fontSize: context.font.sm,
          ),
          const SizedBox(height: 12),
          Slider(
            thumbColor: marker == null
                ? context.color.textLightColor
                : context.color.tertiaryColor,
            value: radius < minRadius ? minRadius : radius,
            padding: EdgeInsets.zero,
            min: double.parse(AppSettings.minRadius),
            max: double.parse(AppSettings.maxRadius),
            activeColor: marker == null
                ? context.color.textLightColor
                : context.color.tertiaryColor,
            inactiveColor: context.color.textLightColor.withValues(alpha: 0.1),
            divisions: (double.parse(AppSettings.maxRadius) -
                    double.parse(AppSettings.minRadius))
                .toInt(),
            label:
                '${radius.toInt()} ${AppSettings.distanceOption.translate(context)}',
            onChanged: (value) {
              if (marker == null) {
                HelperUtils.showSnackBarMessage(
                  context,
                  'pleaseSelectLocation'.translate(context),
                  messageDuration: 1,
                );
                return; // Exit early if no location is selected
              }

              // Use a single setState call to update the radius and redraw the circle.
              // This is much more efficient.
              setState(() {
                radius = value;
                _addCircle(
                  LatLng(marker!.position.latitude, marker!.position.longitude),
                  radius,
                );
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                '${AppSettings.minRadius} ${AppSettings.distanceOption.translate(context)}',
                color: context.color.textColorDark,
                fontSize: context.font.sm,
                fontWeight: FontWeight.w400,
              ),
              CustomText(
                '${AppSettings.maxRadius} ${AppSettings.distanceOption.translate(context)}',
                color: context.color.textColorDark,
                fontSize: context.font.sm,
                fontWeight: FontWeight.w400,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addCircle(LatLng position, double radiusInKm) {
    if (widget.from != 'home_location') return;
    final radiusInMeters = radiusInKm * 1000; // Convert km to meters

    // IMPORTANT: This method no longer calls setState.
    // It just prepares the 'circles' set. The caller will handle the UI update.
    circles
      ..clear() // Clear any existing circles
      ..add(
        Circle(
          circleId: const CircleId('searchRadius'),
          center: position,
          radius: radiusInMeters,
          fillColor: context.color.tertiaryColor.withValues(alpha: .2),
          strokeWidth: 1,
          strokeColor: context.color.tertiaryColor,
        ),
      );
  }
}
