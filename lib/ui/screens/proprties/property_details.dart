import 'dart:developer';

import 'package:ebroker/data/cubits/agents/fetch_property_cubit.dart';
import 'package:ebroker/data/cubits/interested/get_interested_user_cubit.dart';
import 'package:ebroker/data/cubits/property/change_property_status_cubit.dart';
import 'package:ebroker/data/cubits/property/delete_property_cubit.dart';
import 'package:ebroker/data/cubits/property/fetch_similar_properties_cubit.dart';
import 'package:ebroker/data/cubits/property/interest/change_interest_in_property_cubit.dart';
import 'package:ebroker/data/cubits/property/update_property_status.dart';
import 'package:ebroker/data/cubits/report/property_report_cubit.dart';
import 'package:ebroker/data/cubits/utility/mortgage_calculator_cubit.dart';
import 'package:ebroker/data/model/category.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/chat_screen.dart';
import 'package:ebroker/ui/screens/home/widgets/property_card_big.dart';
import 'package:ebroker/ui/screens/proprties/sell_rent_screen.dart';
import 'package:ebroker/ui/screens/proprties/widgets/agent_profile.dart';
import 'package:ebroker/ui/screens/proprties/widgets/download_doc.dart';
import 'package:ebroker/ui/screens/proprties/widgets/interested_users.dart';
import 'package:ebroker/ui/screens/proprties/widgets/mortgage_calculator.dart';
import 'package:ebroker/ui/screens/proprties/widgets/outdoor_facilities.dart';
import 'package:ebroker/ui/screens/proprties/widgets/property_contact_buttons.dart';
import 'package:ebroker/ui/screens/proprties/widgets/property_gallery.dart';
import 'package:ebroker/ui/screens/proprties/widgets/property_header.dart';
import 'package:ebroker/ui/screens/proprties/widgets/property_location_section.dart';
import 'package:ebroker/ui/screens/proprties/widgets/property_parameters_grid.dart';
import 'package:ebroker/ui/screens/proprties/widgets/report_property_widget.dart';
import 'package:ebroker/ui/screens/widgets/like_button_widget.dart';
import 'package:ebroker/ui/screens/widgets/panaroma_image_view.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:ebroker/ui/screens/widgets/read_more_text.dart';
import 'package:ebroker/utils/admob/banner_ad_load_widget.dart';
import 'package:ebroker/utils/admob/interstitial_ad_manager.dart';
import 'package:ebroker/utils/network/network_availability.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PropertyDetails extends StatefulWidget {
  const PropertyDetails({
    required this.property,
    super.key,
    this.fromPropertyAddSuccess,
    this.fromMyProperty,
    this.fromCompleteEnquiry,
  });

  final PropertyModel? property;

  final bool? fromMyProperty;
  final bool? fromCompleteEnquiry;
  final bool? fromPropertyAddSuccess;

  @override
  PropertyDetailsState createState() => PropertyDetailsState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    try {
      final arguments = routeSettings.arguments as Map?;
      return CupertinoPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => ChangeInterestInPropertyCubit(),
            ),
            BlocProvider(
              create: (context) => UpdatePropertyStatusCubit(),
            ),
            BlocProvider(
              create: (context) => DeletePropertyCubit(),
            ),
            BlocProvider(
              create: (context) => PropertyReportCubit(),
            ),
            BlocProvider(
              create: (context) => GetInterestedUserCubit(),
            ),
            BlocProvider(
              create: (context) => FetchAgentsPropertyCubit(),
            ),
            BlocProvider(
              create: (context) => FetchSimilarPropertiesCubit(),
            ),
          ],
          child: PropertyDetails(
            property:
                arguments?['propertyData'] as PropertyModel? ?? PropertyModel(),
            fromMyProperty: arguments?['fromMyProperty'] as bool? ?? false,
            fromCompleteEnquiry:
                arguments?['fromCompleteEnquiry'] as bool? ?? false,
            fromPropertyAddSuccess: arguments?['fromSuccess'] as bool? ?? false,
          ),
        ),
      );
    } on Exception catch (_) {
      rethrow;
    }
  }
}

class PropertyDetailsState extends State<PropertyDetails>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  FlickManager? flickManager;
  ValueNotifier<bool> shouldShowSubscriptionOverlay = ValueNotifier(false);

  // late Property propertyData;
  static const detailsPageSizedBoxHeight = 8.0;
  int selectedIndexExpansionTileForYears = -1;
  int selectedIndexExpansionTileForMonths = -1;
  bool favoriteInProgress = false;
  bool isPlayingYoutubeVideo = false;
  bool fromMyProperty = false; //get its value from Widget
  bool fromCompleteEnquiry = false; //get its value from Widget
  List<dynamic> promotedProeprtiesIds = [];
  bool toggleEnqButton = false;
  PropertyModel? property;
  bool isPromoted = false;
  bool showGoogleMap = false;
  bool isEnquiryFromChat = false;
  bool _adLoaded = false;
  bool isVerified = false;
  ValueNotifier<bool> isEnabled = ValueNotifier(false);
  bool isApproved = false;
  bool isProfileCompleted = HiveUtils.getUserDetails().email != '' &&
      HiveUtils.getUserDetails().mobile != '' &&
      HiveUtils.getUserDetails().name != '' &&
      HiveUtils.getUserDetails().address != '' &&
      HiveUtils.getUserDetails().profile != '';

  InterstitialAdManager interstitialAdManager = InterstitialAdManager();
  bool isPremiumProperty = true;
  bool isPremiumUser = false;
  bool isReported = false;

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  List<Gallery>? gallary;
  String youtubeVideoThumbnail = '';
  late bool? isLoaded;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    isEnabled.value = widget.property?.status.toString() == '1';
    isApproved = widget.property?.requestStatus.toString() == 'approved';
    isVerified = widget.property?.isVerified ?? false;
    isPremiumProperty =
        widget.property?.allPropData['is_premium'] as bool? ?? false;

    isReported = widget.property?.allPropData?['is_reported'] as bool? ?? false;
    if (widget.property?.addedBy.toString() != HiveUtils.getUserId()) {
      loadAd();
      interstitialAdManager.load();
    }
    // customListenerForConstant();
    //add title image along with gallery images
    context.read<FetchOutdoorFacilityListCubit>().fetch();
    if (widget.property?.addedBy.toString() == HiveUtils.getUserId()) {
      try {
        context.read<GetInterestedUserCubit>().fetch(
              '${widget.property?.id}',
            );
      } on Exception catch (_) {
        Widgets.hideLoder(context);
      }
    }
    if (HiveUtils.isGuest() == false) {
      context.read<GetChatListCubit>().fetch(forceRefresh: false);
    }
    context.read<FetchSimilarPropertiesCubit>().fetchSimilarProperty(
          propertyId: widget.property!.id!,
        );

    Future.delayed(
      const Duration(seconds: 3),
      () {
        showGoogleMap = true;
        if (mounted) setState(() {});
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      gallary = List.from(widget.property!.gallery!);
      if (widget.property?.video != '' && widget.property?.video != null) {
        injectVideoInGallery();
        setState(() {});
      }
    });

    property = widget.property;
    setData();

    if (widget.property?.video != '' &&
        widget.property?.video != null &&
        HelperUtils.isYoutubeVideo(widget.property?.video ?? '')) {
      final videoId = YoutubePlayer.convertUrlToId(property!.video!);
      final thumbnail = YoutubePlayer.getThumbnail(videoId: videoId!);
      youtubeVideoThumbnail = thumbnail;
      flickManager = FlickManager(
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse(property!.video!),
        ),
      );
      flickManager?.onVideoEnd = () {};
      setState(() {});
    }
    context.read<FetchPropertyReportReasonsListCubit>().fetch();
  }

  Future<void> onBackPress({required bool isFromAppBar}) async {
    if (widget.property?.addedBy.toString() != HiveUtils.getUserId()) {
      await interstitialAdManager.show();
    }
    context.read<MortgageCalculatorCubit>().emptyMortgageCalculatorData();
    if (widget.property?.addedBy.toString() == HiveUtils.getUserId()) {
      unawaited(context.read<FetchMyPropertiesCubit>().fetchMyProperties(
            type: '',
            status: '',
          ));
    }
    setState(() {
      showGoogleMap = false;
    });
    if (!isFromAppBar) {
      Future.delayed(Duration.zero, () {
        Navigator.pop(context);
      });
    }
  }

  Future<void> loadAd() async {
    if (widget.property?.addedBy.toString() == HiveUtils.getUserId() ||
        !Constant.isAdmobAdsEnabled) {
      return;
    }

    setState(() {
      _adLoaded = true;
    });
  }

  void setData() {
    fromMyProperty = widget.fromMyProperty!;
    fromCompleteEnquiry = widget.fromCompleteEnquiry!;
  }

  late final CameraPosition _kInitialPlace = CameraPosition(
    target: LatLng(
      double.parse(
        property?.latitude ?? '0',
      ),
      double.parse(
        property?.longitude ?? '0',
      ),
    ),
    zoom: 14.4746,
  );

  @override
  void dispose() {
    _controller.future.then((value) => value.dispose());

    flickManager?.dispose();
    super.dispose();
  }

  void injectVideoInGallery() {
    ///This will inject video in image list just like another platforms
    if ((gallary?.length ?? 0) < 2) {
      if (widget.property?.video != null && widget.property?.video != '') {
        gallary?.add(
          Gallery(
            id: 99999999999,
            image: property!.video ?? '',
            imageUrl: '',
            isVideo: true,
          ),
        );
      }
    } else {
      gallary?.insert(
        0,
        Gallery(
          id: 99999999999,
          image: property!.video!,
          imageUrl: '',
          isVideo: true,
        ),
      );
    }
    setState(() {});
  }

  String? _statusFilter(String value) {
    if (value == 'Sell' || value == 'sell') {
      return 'sold'.translate(context);
    }
    if (value == 'Rent' || value == 'rent') {
      return 'Rented'.translate(context);
    }

    return null;
  }

  int? _getStatus(String type) {
    int? value;
    if (type == 'Sell' || type == 'sell') {
      value = 2;
    } else if (type == 'Rent' || type == 'rent') {
      value = 3;
    } else if (type == 'Rented' || type == 'rented') {
      value = 1;
    }
    return value;
  }

  bool hasDocuments() {
    return widget.property!.documents!.isNotEmpty;
  }

//main build
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await onBackPress(isFromAppBar: false);
        },
        child: BlocListener<GetSubsctiptionPackageLimitsCubit,
            GetSubscriptionPackageLimitsState>(
          listener: (context, state) {
            if (state is GetSubscriptionPackageLimitsSuccess) {
              isPremiumUser = state.hasSubscription;
              setState(() {});
            }
          },
          child: Scaffold(
            appBar: CustomAppBar(
              onTapBackButton: () async {
                await onBackPress(isFromAppBar: true);
              },
              actions: [
                if (HiveUtils.isGuest() == false &&
                    property?.addedBy.toString() == HiveUtils.getUserId()) ...[
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'share') {
                        await HelperUtils.share(
                          context,
                          property?.slugId ?? '',
                        );
                      }
                      if (value == 'interestedUsers') {
                        final interestedUserCubitReference =
                            context.read<GetInterestedUserCubit>();
                        await showModalBottomSheet<dynamic>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          backgroundColor: context.color.secondaryColor,
                          constraints: BoxConstraints(
                            minWidth: double.infinity,
                            maxHeight: context.screenHeight * 0.7,
                            minHeight: context.screenHeight * 0.3,
                          ),
                          builder: (context) {
                            return InterestedUserListWidget(
                              totalCount:
                                  '${widget.property?.totalInterestedUsers}',
                              interestedUserCubitReference:
                                  interestedUserCubitReference,
                            );
                          },
                        );
                        return;
                      }
                      if (value == 'markAsSold') {
                        final action = await UiUtils.showBlurredDialoge(
                          context,
                          dialog: BlurredDialogBuilderBox(
                            title: 'changePropertyStatus'.translate(context),
                            acceptButtonName: 'change'.translate(context),
                            titleSize: context.font.md,
                            titleWeight: FontWeight.w500,
                            cancelButtonBorderColor:
                                context.color.tertiaryColor,
                            acceptTextColor: context.color.buttonColor,
                            cancelTextColor: context.color.tertiaryColor,
                            cancelButtonColor: context.color.secondaryColor,
                            contentBuilder: (context, s) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: context.color.secondaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: context.color.borderColor),
                                    ),
                                    width: s.maxWidth,
                                    height: 48.rh(context),
                                    child: Center(
                                      child: CustomText(
                                        '${property!.propertyType!.translate(context)} ${'property'.translate(context)}',
                                        color: context.color.inverseSurface,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: CustomText(
                                      'to'.translate(context),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    width: s.maxWidth,
                                    decoration: BoxDecoration(
                                      color: context.color.secondaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: context.color.borderColor,
                                      ),
                                    ),
                                    height: 48.rh(context),
                                    child: Center(
                                      child: CustomText(
                                        '${_statusFilter(
                                          property!.propertyType!,
                                        )} ${'property'.translate(context)}',
                                        color: context.color.inverseSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                        if (action == true) {
                          Future.delayed(Duration.zero, () {
                            context.read<UpdatePropertyStatusCubit>().update(
                                  propertyId: property!.id,
                                  status:
                                      _getStatus(property!.propertyType ?? ''),
                                );
                          });
                        }
                      }
                    },
                    color: context.color.secondaryColor,
                    itemBuilder: (BuildContext context) {
                      return [
                        buildPopupMenuItem(
                          context: context,
                          title: 'share',
                          icon: AppIcons.shareIcon,
                          index: 0,
                        ),
                        buildPopupMenuItem(
                          context: context,
                          title: 'interestedUsers',
                          icon: AppIcons.interestedUsers,
                          index: 1,
                        ),
                        if (property?.propertyType != 'sold' &&
                            property?.propertyType != 'rented')
                          buildPopupMenuItem(
                            context: context,
                            title: 'markAsSold',
                            icon: AppIcons.changeStatus,
                            index: 2,
                          ),
                      ];
                    },
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(end: 16),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 24.rh(context),
                        color: context.color.textColorDark,
                      ),
                    ),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: () {
                      HelperUtils.share(
                        context,
                        property?.slugId ?? '',
                      );
                    },
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(end: 16),
                      alignment: Alignment.center,
                      child: CustomImage(
                        imageUrl: AppIcons.shareIcon,
                        height: 24.rh(context),
                        color: context.color.textColorDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: context.color.primaryColor,
            floatingActionButton: (property == null ||
                    property!.addedBy.toString() == HiveUtils.getUserId())
                ? const SizedBox.shrink()
                : Container(),
            bottomNavigationBar:
                isPlayingYoutubeVideo == false ? bottomNavBar() : null,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            body: BlocListener<DeletePropertyCubit, DeletePropertyState>(
              listener: (context, state) {
                if (state is DeletePropertyInProgress) {
                  Widgets.showLoader(context);
                }

                if (state is DeletePropertySuccess) {
                  Widgets.hideLoder(context);

                  Navigator.pop(context, true);
                }
                if (state is DeletePropertyFailure) {
                  Widgets.showLoader(context);
                }
              },
              child: SingleChildScrollView(
                physics: Constant.scrollPhysics,
                child: BlocListener<UpdatePropertyStatusCubit,
                    UpdatePropertyStatusState>(
                  listener: (context, state) {
                    if (state is UpdatePropertyStatusSuccess) {
                      Widgets.hideLoder(context);
                      Fluttertoast.showToast(
                        msg: 'statusUpdated'.translate(context),
                        backgroundColor: successMessageColor,
                        gravity: ToastGravity.TOP,
                        toastLength: Toast.LENGTH_LONG,
                      );

                      (cubitReference!).updateStatus(
                        property!.id!,
                        property!.propertyType!,
                      );
                      setState(() {});
                    }
                    if (state is UpdatePropertyStatusFail) {
                      Widgets.hideLoder(context);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPropertyImage(),
                      if (!isPlayingYoutubeVideo)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              PropertyHeader(
                                property: property!,
                              ),
                              const SizedBox(height: detailsPageSizedBoxHeight),
                              if (property?.addedBy.toString() ==
                                  HiveUtils.getUserId()) ...[
                                buildEnableDisableSwitch(),
                                const SizedBox(
                                    height: detailsPageSizedBoxHeight),
                              ],
                              if (property?.description != null) ...[
                                buildPropertyDescription(),
                                const SizedBox(
                                    height: detailsPageSizedBoxHeight),
                              ],
                              if (widget.property?.propertyType
                                      .toString()
                                      .toLowerCase() ==
                                  'sell') ...[
                                _buildMortgageCalculatorContainer(),
                                const SizedBox(
                                    height: detailsPageSizedBoxHeight),
                              ],
                              if (property?.parameters?.isNotEmpty ??
                                  false) ...[
                                PropertyParametersGrid(property: property!),
                                const SizedBox(
                                    height: detailsPageSizedBoxHeight),
                              ],
                              // This is for banner ads
                              buildAdWidget(),
                              if (widget.property?.assignedOutdoorFacility
                                      ?.isNotEmpty ??
                                  false) ...[
                                OutdoorFacilityListWidget(
                                  outdoorFacilityList: widget
                                          .property?.assignedOutdoorFacility ??
                                      [],
                                ),
                                const SizedBox(
                                    height: detailsPageSizedBoxHeight),
                              ],

                              PropertyLocationSection(
                                property: property!,
                                kInitialPlace: _kInitialPlace,
                                controller: _controller,
                                showGoogleMap: showGoogleMap,
                                onShowGoogleMapToggle: () {
                                  setState(() {
                                    showGoogleMap = !showGoogleMap;
                                  });
                                },
                              ),

                              if (!HiveUtils.isGuest() &&
                                  (HiveUtils.getUserId() !=
                                      property?.addedBy)) ...[
                                const SizedBox(
                                    height: detailsPageSizedBoxHeight),
                                setInterest(),
                              ],
                              const SizedBox(height: detailsPageSizedBoxHeight),
                              buildAgentProfileAndGallery(),

                              if (!reportedProperties.contains(
                                    widget.property!.id,
                                  ) &&
                                  widget.property!.addedBy.toString() !=
                                      HiveUtils.getUserId() &&
                                  !isReported) ...[
                                const SizedBox(
                                    height: detailsPageSizedBoxHeight),
                                ReportPropertyButton(
                                  propertyId: property!.id!,
                                  onSuccess: () {
                                    setState(() {});
                                  },
                                ),
                              ],
                              if (hasDocuments()) ...[
                                const SizedBox(
                                    height: detailsPageSizedBoxHeight),
                                buildDocuments(),
                              ],
                              const SizedBox(height: detailsPageSizedBoxHeight),
                              buildSimilarProperties(),
                              SizedBox(height: 24.rh(context)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDocuments() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Documents'.translate(context),
            fontWeight: FontWeight.bold,
            fontSize: context.font.md,
          ),
          const SizedBox(height: 8),
          UiUtils.getDivider(context),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final document = widget.property!.documents![index];
              return Column(
                children: [
                  DownloadableDocuments(
                    url: document.file!,
                  ),
                  if (index != widget.property!.documents!.length - 1) ...[
                    const SizedBox(height: 8),
                    UiUtils.getDivider(context),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
            itemCount: widget.property!.documents!.length,
          ),
        ],
      ),
    );
  }

  Widget buildAgentProfileAndGallery() {
    final isAddedByMe =
        widget.property?.addedBy.toString() == HiveUtils.getUserId();
    final gallaryIsEmpty = widget.property?.gallery?.isEmpty ?? false;
    if (isAddedByMe && gallaryIsEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Column(
        children: [
          if (!isAddedByMe)
            AgentProfileWidget(
              addedBy: widget.property?.addedBy ?? '',
              name: widget.property?.customerName ?? '',
              email: widget.property?.customerEmail ?? '',
              profileImage: widget.property?.customerProfile ?? '',
              isVerified: widget.property?.isVerified ?? false,
              propertiesCount: widget.property?.propertiesCount ?? '',
              projectsCount: widget.property?.projectsCount ?? '',
            ),
          if (!gallaryIsEmpty) ...[
            if (!isAddedByMe) ...[
              const SizedBox(height: 8),
              UiUtils.getDivider(context),
              const SizedBox(height: 8),
            ],
            PropertyGallery(
              gallary: widget.property?.gallery ?? [],
              youtubeVideoThumbnail: youtubeVideoThumbnail,
              flickManager: flickManager,
              onShowGoogleMap: () {
                setState(() {
                  showGoogleMap = !showGoogleMap;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget buildSimilarProperties() {
    return BlocBuilder<FetchSimilarPropertiesCubit,
        FetchSimilarPropertiesState>(
      builder: (context, state) {
        if (state is FetchSimilarPropertiesSuccess) {
          if (state.properties.isEmpty) {
            return const SizedBox.shrink();
          }
          if (widget.property?.requestStatus.toString() == 'pending' ||
              widget.property?.requestStatus.toString() == 'rejected') {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: context.color.borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: CustomText(
                    UiUtils.translate(context, 'similarProperties'),
                    fontWeight: FontWeight.w600,
                    fontSize: context.font.md,
                    color: context.color.textColorDark,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 360.rh(context),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    itemCount: state.properties.length,
                    itemBuilder: (context, index) {
                      return BlocProvider(
                        create: (context) {
                          return AddToFavoriteCubitCubit();
                        },
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(end: 16),
                          child: PropertyCardBig(
                            key: UniqueKey(),
                            showEndPadding: true,
                            isFromCompare: true,
                            isFirst: index == 0,
                            property: state.properties[index],
                            sourceProperty: property,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  PopupMenuItem<String> buildPopupMenuItem({
    required BuildContext context,
    required String title,
    required String icon,
    required int index,
  }) {
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        children: [
          Container(
            height: 20.rh(context),
            width: 20.rw(context),
            alignment: Alignment.center,
            child: CustomImage(
              imageUrl: icon,
              color: context.color.textColorDark,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          CustomText(
            title.translate(context),
          ),
        ],
      ),
    );
  }

  Widget buildEnableDisableSwitch() {
    return Container(
      height: 48.rh(context),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Row(
        children: [
          CustomText(
            'updatePropertyStatus'.translate(context),
            fontSize: context.font.sm,
            color: context.color.textColorDark,
            fontWeight: FontWeight.w500,
          ),
          const Spacer(),
          ValueListenableBuilder(
            valueListenable: isEnabled,
            builder: (context, value, child) {
              return Switch(
                trackColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.disabled)) {
                      return context.color.textColorDark.withValues(alpha: 0.1);
                    }
                    if (states.contains(WidgetState.selected)) {
                      return context.color.tertiaryColor;
                    }
                    return Colors.grey;
                  },
                ),
                thumbColor: const WidgetStatePropertyAll(
                  Colors.white,
                ),
                trackOutlineColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                thumbIcon: WidgetStateProperty.resolveWith<Icon>(
                  (Set<WidgetState> states) {
                    return const Icon(
                      Icons.circle,
                      color: Colors.white,
                    );
                  },
                ),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey,
                activeTrackColor: context.color.tertiaryColor,
                value: value,
                onChanged: property?.requestStatus.toString() == 'pending'
                    ? null
                    : (newValue) async {
                        // Get current state to check if we're already in progress
                        final cubit = context.read<ChangePropertyStatusCubit>();
                        final currentState = cubit.state;

                        if (currentState is ChangePropertyStatusInProgress) {
                          return;
                        }

                        final status = value == false ? 1 : 0;

                        // Update UI immediately for responsive feedback
                        setState(() {
                          isEnabled.value = newValue;
                        });

                        try {
                          // Make API call
                          await cubit.enableProperty(
                            propertyId: property!.id!,
                            status: status,
                          );

                          // Listen for state changes after API call completes
                          final newState = cubit.state;

                          if (newState is ChangePropertyStatusFailure) {
                            // If API failed, revert the UI change
                            setState(() {
                              isEnabled.value = !newValue;
                            });

                            final errorMessage = newState.error.contains('429')
                                ? 'tooManyRequestsPleaseWait'.translate(context)
                                : newState.error;

                            await HelperUtils.showSnackBarMessage(
                              context,
                              errorMessage,
                              type: MessageType.error,
                            );
                          }
                          // Success state is already reflected in UI
                        } on Exception catch (_) {
                          // Handle unexpected errors
                          setState(() {
                            isEnabled.value = !newValue;
                          });

                          await HelperUtils.showSnackBarMessage(
                            context,
                            'somethingWentWrong'.translate(context),
                            type: MessageType.error,
                          );
                        }
                      },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMortgageCalculatorContainer() {
    return Container(
      height: 66.rh(context),
      padding: const EdgeInsets.all(8),
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            context.color.tertiaryColor.withValues(alpha: 0.05),
            context.color.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: context.color.borderColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.color.tertiaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            height: 42.rh(context),
            width: 42.rw(context),
            child: CustomImage(
              imageUrl: AppIcons.calculator,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  'calculateMortgage'.translate(context),
                  maxLines: 1,
                  color: context.color.textColorDark,
                  fontSize: context.font.xs,
                  fontWeight: FontWeight.w500,
                ),
                CustomText(
                  property?.price?.toString().priceFormat(context: context) ??
                      '',
                  color: context.color.tertiaryColor,
                  maxLines: 1,
                  fontWeight: FontWeight.w600,
                  fontSize: context.font.md,
                ),
              ],
            ),
          ),
          UiUtils.buildButton(
            context,
            padding: const EdgeInsetsDirectional.only(end: 10, start: 10),
            height: 36.rh(context),
            autoWidth: true,
            showElevation: false,
            buttonColor: Colors.transparent,
            border: BorderSide(
              color: context.color.tertiaryColor,
            ),
            onPressed: () async {
              try {
                final checkPackage = CheckPackage();
                final packageAvailable =
                    await checkPackage.checkPackageAvailable(
                  packageType: PackageType.mortgageCalculatorDetail,
                );
                if (packageAvailable) {
                  await showModalBottomSheet<dynamic>(
                    sheetAnimationStyle: const AnimationStyle(
                      duration: Duration(milliseconds: 500),
                      reverseDuration: Duration(milliseconds: 200),
                    ),
                    showDragHandle: true,
                    backgroundColor: context.color.secondaryColor,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    context: context,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: MortgageCalculator(property: widget.property!),
                    ),
                  );
                } else {
                  await UiUtils.showBlurredDialoge(
                    context,
                    dialog: const BlurredSubscriptionDialogBox(
                      packageType:
                          SubscriptionPackageType.mortgageCalculatorDetail,
                    ),
                  );
                }
              } on Exception catch (e) {
                log(e.toString());
              }
            },
            buttonTitle: 'tryNow'.translate(context),
            textColor: context.color.tertiaryColor,
            fontSize: 14,
            radius: 5,
          ),
        ],
      ),
    );
  }

  Widget myPropertyButton({
    required dynamic Function() onPressed,
    required String title,
    required String icon,
  }) {
    return Expanded(
      child: UiUtils.buildButton(
        context,
        fontSize: context.font.md,
        buttonTitle: title,
        padding: const EdgeInsets.all(2),
        height: 48.rh(context),
        onPressed: onPressed,
        prefixWidget: Container(
          alignment: Alignment.center,
          padding: const EdgeInsetsDirectional.only(end: 4),
          child: CustomImage(
            imageUrl: icon,
            color: context.color.buttonColor,
            width: 18.rw(context),
            height: 18.rh(context),
          ),
        ),
      ),
    );
  }

  Widget bottomNavBar() {
    // Early return for guest users or properties not owned by current user
    if (HiveUtils.isGuest() || HiveUtils.getUserId() != property?.addedBy) {
      return PropertyContactButtons(property: property!);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        boxShadow: [
          BoxShadow(
            color: context.color.textColorDark.withValues(alpha: 0.3),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      height: 72.rh(context),
      child: BlocBuilder<FetchMyPropertiesCubit, FetchMyPropertiesState>(
        builder: (context, state) {
          final model = _getPropertyModel(state);
          if (model == null) {
            return const SizedBox.shrink();
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!HiveUtils.isGuest() &&
                  Constant.isDemoModeOn == false &&
                  (model.isFeatureAvailable ?? false)) ...[
                _buildFeatureButton(model),
                const SizedBox(width: 16),
              ],
              _buildEditButton(),
              const SizedBox(width: 16),
              _buildDeleteButton(),
            ],
          );
        },
      ),
    );
  }

  /// Gets the property model from state or fallback to widget property
  PropertyModel? _getPropertyModel(FetchMyPropertiesState state) {
    if (state is FetchMyPropertiesSuccess) {
      if (property?.id == null) {
        return null;
      }
      try {
        return state.myProperty.firstWhere(
          (element) => element.id == property?.id,
          orElse: () {
            // This block is executed if the property is not found in state.myProperty
            // This is expected behavior after a delete operation.
            log('Property with ID ${property?.id} not found in FetchMyPropertiesSuccess state. It might have been deleted. Falling back to widget.property.',
                name: 'FetchMyPropertiesCubit');
            return widget.property ??
                PropertyModel(); // Fallback to the original widget.property (which is now likely "stale" but won't cause a crash)
          },
        );
      } on Exception catch (e, st) {
        // This catch block might still be useful for other unexpected exceptions,
        // but 'Bad state: No element' will now be handled by orElse.
        log(st.toString(), name: e.toString());
      }
    }
    return widget.property;
  }

  /// Builds feature button if available and conditions are met
  Widget _buildFeatureButton(PropertyModel? model) {
    return BlocBuilder<GetSubsctiptionPackageLimitsCubit,
        GetSubscriptionPackageLimitsState>(
      builder: (context, state) {
        return myPropertyButton(
          onPressed: () => _handleFeatureButtonPress(state),
          icon: AppIcons.promoted,
          title: UiUtils.translate(context, 'feature'),
        );
      },
    );
  }

  /// Handles feature button press logic
  Future<void> _handleFeatureButtonPress(
    GetSubscriptionPackageLimitsState state,
  ) async {
    await context
        .read<GetSubsctiptionPackageLimitsCubit>()
        .getLimits(packageType: 'property_feature');

    if (state is GetSubsctiptionPackageLimitsFailure) {
      await _showFeatureSubscriptionDialog();
    } else if (state is GetSubscriptionPackageLimitsSuccess) {
      if (state.error) {
        await _showPackageLimitDialog(state.message);
      } else {
        await _showCreateAdvertisementDialog();
      }
    }
  }

  /// Shows feature subscription dialog
  Future<void> _showFeatureSubscriptionDialog() async {
    await UiUtils.showBlurredDialoge(
      context,
      dialog: const BlurredSubscriptionDialogBox(
        packageType: SubscriptionPackageType.propertyFeature,
        isAcceptContainesPush: true,
      ),
    );
  }

  /// Shows package limit exceeded dialog
  Future<void> _showPackageLimitDialog(String message) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: message.firstUpperCase(),
        isAcceptContainesPush: true,
        onAccept: _navigateToSubscriptionPackages,
        content: CustomText('yourPackageLimitOver'.translate(context)),
      ),
    );
  }

  /// Navigates to subscription packages
  Future<void> _navigateToSubscriptionPackages() async {
    final isBankTransferEnabled = _getBankTransferStatus();
    await Navigator.popAndPushNamed(
      context,
      Routes.subscriptionPackageListRoute,
      arguments: {
        'from': 'propertyDetails',
        'isBankTransferEnabled': isBankTransferEnabled,
      },
    );
  }

  /// Gets bank transfer status from API keys
  bool _getBankTransferStatus() {
    final apiKeysState = context.read<GetApiKeysCubit>().state;
    return apiKeysState is GetApiKeysSuccess &&
        apiKeysState.bankTransferStatus == '1';
  }

  /// Shows create advertisement dialog
  Future<void> _showCreateAdvertisementDialog() async {
    try {
      await showDialog<dynamic>(
        context: context,
        builder: (context) => CreateAdvertisementPopup(
          property: property!,
          isProject: false,
          project: ProjectModel(),
        ),
      );
    } on Exception catch (e) {
      await HelperUtils.showSnackBarMessage(context, e.toString());
    }
  }

  /// Builds edit button
  Widget _buildEditButton() {
    return myPropertyButton(
      icon: AppIcons.edit,
      onPressed: _handleEditButtonPress,
      title: UiUtils.translate(context, 'edit'),
    );
  }

  /// Handles edit button press logic
  Future<void> _handleEditButtonPress() async {
    if (Constant.isDemoModeOn &&
        HiveUtils.getUserDetails().email == Constant.demoEmail) {
      await HelperUtils.showSnackBarMessage(
        context,
        'thisActionNotValidDemo'.translate(context),
      );
      return;
    }

    unawaited(Widgets.showLoader(context));

    try {
      if (!await _checkProfileCompletion()) {
        return;
      }

      await _processEditProperty();
    } on Exception catch (_) {
      // Error handling is done in _processEditProperty
    } finally {
      Widgets.hideLoder(context);
    }
  }

  /// Checks if profile completion is required
  Future<bool> _checkProfileCompletion() async {
    if (AppSettings.isVerificationRequired == true &&
        isProfileCompleted != true) {
      await _showProfileCompletionDialog();
      Widgets.hideLoder(context);
      return false;
    }
    return true;
  }

  /// Shows profile completion dialog
  Future<void> _showProfileCompletionDialog() async {
    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: 'completeProfile'.translate(context),
        isAcceptContainesPush: true,
        onAccept: _navigateToEditProfile,
        content: CustomText('completeProfileFirst'.translate(context)),
      ),
    );
  }

  /// Navigates to edit profile
  Future<void> _navigateToEditProfile() async {
    await Navigator.popAndPushNamed(
      context,
      Routes.editProfile,
      arguments: {
        'from': 'home',
        'navigateToHome': true,
      },
    );
  }

  /// Processes property editing logic
  Future<void> _processEditProperty() async {
    try {
      final category =
          await context.read<FetchCategoryCubit>().get(property!.category!.id!);

      final mappedParameters = _mapCategoryParameters(category);

      _updateConstantAddProperty(category, mappedParameters);

      Widgets.hideLoder(context);

      await _navigateToAddPropertyDetails();
    } on Exception catch (_) {
      Widgets.hideLoder(context);
      rethrow;
    }
  }

  /// Maps category parameters with existing property parameters
  List<dynamic> _mapCategoryParameters(Category category) {
    return category.parameterTypes!.map((id) {
      final index = property?.parameters?.indexWhere(
            (element) => element.id == id['id'],
          ) ??
          -1;

      return index != -1 ? property!.parameters![index] : id;
    }).toList();
  }

  /// Updates the constant add property data
  void _updateConstantAddProperty(
    Category category,
    List<dynamic> mappedParameters,
  ) {
    Constant.addProperty.addAll({
      'category': Category(
        category: property?.category!.category,
        id: property?.category?.id,
        image: property?.category?.image,
        parameterTypes: mappedParameters,
      ),
    });
  }

  /// Navigates to add property details screen
  Future<void> _navigateToAddPropertyDetails() async {
    await Navigator.pushNamed(
      context,
      Routes.addPropertyDetailsScreen,
      arguments: {
        'details': _buildPropertyDetails(),
      },
    );
  }

  /// Builds property details map for navigation
  Map<String, dynamic> _buildPropertyDetails() {
    return {
      'id': property?.id,
      'catId': property?.category?.id,
      'propType': property?.propertyType,
      'name': property?.title,
      'desc': property?.description,
      'city': property?.city,
      'state': property?.state,
      'country': property?.country,
      'latitude': property?.latitude,
      'longitude': property?.longitude,
      'address': property?.address,
      'client': property?.clientAddress,
      'price': property?.price,
      'parms': property?.parameters,
      'allPropData': property?.allPropData,
      'images': property?.gallery?.map((e) => e.imageUrl).toList(),
      'gallary_with_id': property?.gallery,
      'rentduration': property?.rentduration,
      'assign_facilities': property?.assignedOutdoorFacility,
      'titleImage': property?.titleImage,
      'slug_id': property?.slugId,
      'three_d_image': property?.threeDImage,
      'documents': property?.documents,
      'translations': property?.translations,
    };
  }

  /// Builds delete button
  Widget _buildDeleteButton() {
    return myPropertyButton(
      icon: AppIcons.delete,
      onPressed: _handleDeleteButtonPress,
      title: UiUtils.translate(context, 'deleteBtnLbl'),
    );
  }

  /// Handles delete button press logic
  Future<void> _handleDeleteButtonPress() async {
    if (await _checkDemoModeDelete() == false) {
      return;
    }

    await _showDeleteConfirmationDialog();
  }

  /// Checks demo mode delete restrictions
  Future<bool> _checkDemoModeDelete() async {
    final isPropertyActive = property?.status.toString() == '1';
    final isDemoUser = HiveUtils.getUserDetails().email == Constant.demoEmail;

    if (Constant.isDemoModeOn && isPropertyActive && isDemoUser) {
      await HelperUtils.showSnackBarMessage(
        context,
        'thisActionNotValidDemo'.translate(context),
      );
    }
    return true;
  }

  /// Shows delete confirmation dialog
  Future<dynamic> _showDeleteConfirmationDialog() async {
    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: UiUtils.translate(context, 'deleteBtnLbl'),
        isAcceptContainesPush: true,
        onAccept: () async {
          await context.read<DeletePropertyCubit>().delete(property!.id!).then(
            (value) {
              Navigator.pop(context);
              context.read<FetchMyPropertiesCubit>().fetchMyProperties(
                    type: '',
                    status: '',
                  );
            },
          );
        },
        content: CustomText(
          UiUtils.translate(context, 'deletepropertywarning'),
          maxLines: 5,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget setInterest() {
    // check if list has this id or not
    final interestedProperty =
        Constant.interestedPropertyIds.contains(widget.property?.id);

    /// default icon
    dynamic icon = AppIcons.interested;

    /// first priority is Constant list .
    if (interestedProperty == true || widget.property?.isInterested == '1') {
      /// If list has id or our property is interested so we are gonna show icon of No Interest
      icon = Icons.not_interested_outlined;
    }

    return BlocBuilder<ChangeInterestInPropertyCubit,
        ChangeInterestInPropertyState>(
      builder: (context, state) {
        if (state is ChangeInterestInPropertySuccess) {
          if (state.interest == PropertyInterest.interested) {
            //If interested show no interested icon
            icon = Icons.not_interested_outlined;
          } else {
            icon = AppIcons.interested;
          }
        }

        return UiUtils.buildButton(
          context,
          height: 48.rh(context),
          isInProgress: state is ChangeInterestInPropertyInProgress,
          onPressed: () {
            PropertyInterest interest;

            final contains =
                Constant.interestedPropertyIds.contains(widget.property!.id);

            if (contains == true || widget.property!.isInterested == '1') {
              //change to not interested
              interest = PropertyInterest.notInterested;
            } else {
              //change to not unterested
              interest = PropertyInterest.interested;
            }
            context.read<ChangeInterestInPropertyCubit>().changeInterest(
                  propertyId: widget.property!.id!.toString(),
                  interest: interest,
                );
          },
          buttonTitle: (icon == Icons.not_interested_outlined
              ? UiUtils.translate(context, 'interested')
              : UiUtils.translate(context, 'interest')),
          fontSize: context.font.md,
          textColor: context.color.secondaryColor,
          buttonColor: context.color.textColorDark,
          prefixWidget: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: (icon is String)
                ? Container(
                    alignment: Alignment.center,
                    child: CustomImage(
                      imageUrl: icon?.toString() ?? '',
                      width: 18.rw(context),
                      height: 18.rh(context),
                      color: context.color.secondaryColor,
                    ),
                  )
                : Icon(
                    icon as IconData,
                    color: context.color.secondaryColor,
                    size: 18.rh(context),
                  ),
          ),
        );
      },
    );
  }

  Widget callButton() {
    return UiUtils.buildButton(
      context,
      fontSize: context.font.md,
      outerPadding: const EdgeInsets.all(1),
      buttonTitle: UiUtils.translate(context, 'call'),
      height: 45.rh(context),
      onPressed: _onTapCall,
      prefixWidget: Container(
        margin: const EdgeInsets.only(right: 3, left: 3),
        child: Container(
          alignment: Alignment.center,
          width: 18.rw(context),
          height: 18.rh(context),
          child: CustomImage(
            imageUrl: AppIcons.callFilled,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget messageButton() {
    return UiUtils.buildButton(
      context,
      fontSize: context.font.md,
      outerPadding: const EdgeInsets.all(1),
      buttonTitle: UiUtils.translate(context, 'sms'),
      height: 45.rh(context),
      onPressed: _onTapMessage,
      prefixWidget: Container(
        margin: const EdgeInsets.only(right: 3, left: 3),
        alignment: Alignment.center,
        width: 18.rw(context),
        height: 18.rh(context),
        child: CustomImage(
          imageUrl: AppIcons.message,
          color: context.color.buttonColor,
        ),
      ),
    );
  }

  Widget chatButton() {
    return UiUtils.buildButton(
      context,
      fontSize: context.font.md,
      outerPadding: const EdgeInsets.all(1),
      buttonTitle: UiUtils.translate(context, 'chat'),
      height: 45.rh(context),
      onPressed: _onTapChat,
      prefixWidget: Container(
        alignment: Alignment.center,
        width: 18.rw(context),
        height: 18.rh(context),
        margin: const EdgeInsets.only(right: 3, left: 3),
        child: CustomImage(
          imageUrl: AppIcons.chatActive,
          color: context.color.buttonColor,
        ),
      ),
    );
  }

  Future<void> _onTapCall() async {
    final contactNumber = widget.property?.customerNumber;

    final url = Uri.parse('tel: $contactNumber'); //{contactNumber.data}
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      log('Could not launch $url');
    }
  }

  Future<void> _onTapMessage() async {
    final contactNumber = widget.property?.customerNumber;

    final url = Uri.parse('sms: +$contactNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      log('Could not launch $url');
    }
  }

  void _onTapChat() {
    CheckInternet.check(
      onInternet: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            final chatState = context.read<GetChatListCubit>().state;
            if (chatState is GetChatListSuccess) {
              await Navigator.push(
                context,
                CupertinoPageRoute<dynamic>(
                  builder: (context) {
                    return MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (context) => SendMessageCubit(),
                        ),
                        BlocProvider(
                          create: (context) => LoadChatMessagesCubit(),
                        ),
                        BlocProvider(
                          create: (context) => DeleteMessageCubit(),
                        ),
                      ],
                      child: ChatScreenNew(
                        profilePicture: property?.customerProfile ?? '',
                        userName: property?.customerName ?? '',
                        propertyImage: property?.titleImage ?? '',
                        proeprtyTitle: property?.title ?? '',
                        userId: (property?.addedBy).toString(),
                        from: 'property',
                        propertyId: (property?.id).toString(),
                        isBlockedByMe: property?.isBlockedByMe ?? true,
                        isBlockedByUser: property?.isBlockedByUser ?? true,
                      ),
                    );
                  },
                ),
              );
            }
            if (chatState is GetChatListFailed) {
              await HelperUtils.showSnackBarMessage(
                context,
                chatState.error.toString(),
              );
            }
          },
        );
      },
      onNoInternet: () {
        HelperUtils.showSnackBarMessage(
          context,
          'noInternet'.translate(context),
        );
      },
    );
  }

  Widget _buildPropertyImage() {
    return SizedBox(
      height: 218.rs(context),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              UiUtils.showFullScreenImage(
                context,
                provider: NetworkImage(property?.titleImage ?? ''),
              );
            },
            child: Container(
              alignment: Alignment.center,
              child: CustomImage(
                imageUrl: property?.titleImage ?? '',
                width: double.infinity,
                fit: BoxFit.fill,
                height: 218.rs(context),
                showFullScreenImage: true,
              ),
            ),
          ),
          PositionedDirectional(
            top: 16.rh(context),
            end: 16.rh(context),
            child: LikeButtonWidget(
              isFromDetailsPage: true,
              propertyId: property!.id!,
              isFavourite: property?.isFavourite == '1',
            ),
          ),
          if (property?.threeDImage != '')
            PositionedDirectional(
              bottom: 16,
              end: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute<dynamic>(
                      builder: (context) => PanaromaImageScreen(
                        imageUrl: property?.threeDImage ?? '',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 38.rw(context),
                  height: 38.rw(context),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.color.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: const Offset(0, 1),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: CustomImage(
                    imageUrl: AppIcons.v360Degree,
                    height: 24.rh(context),
                    width: 24.rw(context),
                    fit: BoxFit.contain,
                    color: context.color.tertiaryColor,
                  ),
                ),
              ),
            ),
          if (property?.allPropData['is_premium'] == true)
            PositionedDirectional(
              start: 16.rh(context),
              top: 16.rh(context),
              child: Container(
                alignment: Alignment.center,
                child: CustomImage(
                  imageUrl: AppIcons.premium,
                  height: 24.rh(context),
                  width: 24.rw(context),
                ),
              ),
            ),
          if ((property?.promoted ?? false) && property?.promoted != null)
            PositionedDirectional(
              bottom: 16.rh(context),
              start: 16.rh(context),
              child: const PromotedCard(),
            ),
        ],
      ),
    );
  }

  Widget buildPropertyDescription() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        border: Border.all(
          color: context.color.borderColor,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            UiUtils.translate(
              context,
              'aboutThisPropLbl',
            ),
            fontWeight: FontWeight.w600,
            fontSize: context.font.md,
            color: context.color.textColorDark,
          ),
          const SizedBox(height: 8),
          UiUtils.getDivider(context),
          const SizedBox(height: 8),
          ReadMoreText(
            text:
                property?.translatedDescription ?? property?.description ?? '',
            style: TextStyle(
              fontSize: context.font.xs,
              fontWeight: FontWeight.w500,
              color: context.color.textColorDark,
            ),
            readMoreButtonStyle: TextStyle(
              color: context.color.tertiaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAdWidget() {
    if (!_adLoaded || !Constant.isAdmobAdsEnabled) {
      return const SizedBox.shrink();
    }

    // Use the BannerAdWidget from the admob package
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 8),
      child: const BannerAdWidget(),
    );
  }
}
