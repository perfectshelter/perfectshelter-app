import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:perfectshelter/data/cubits/fetch_home_page_data_cubit.dart';
import 'package:perfectshelter/data/cubits/property/fetch_city_property_list.dart';
import 'package:perfectshelter/data/cubits/property/fetch_premium_properties_cubit.dart';
import 'package:perfectshelter/data/cubits/property/home_infinityscroll_cubit.dart';
import 'package:perfectshelter/data/model/agent/agent_model.dart';
import 'package:perfectshelter/data/model/category.dart';
import 'package:perfectshelter/data/model/city_model.dart';
import 'package:perfectshelter/data/model/home_page_data_model.dart';
import 'package:perfectshelter/data/model/home_slider.dart';
import 'package:perfectshelter/data/model/project_model.dart';
import 'package:perfectshelter/data/model/system_settings_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/agents/cards/agent_card.dart';
import 'package:perfectshelter/ui/screens/home/Widgets/property_card_big.dart';
import 'package:perfectshelter/ui/screens/home/city_properties_screen.dart';
import 'package:perfectshelter/ui/screens/home/widgets/category_card.dart';
import 'package:perfectshelter/ui/screens/home/widgets/custom_grid.dart';
import 'package:perfectshelter/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:perfectshelter/ui/screens/home/widgets/header_card.dart';
import 'package:perfectshelter/ui/screens/home/widgets/home_search.dart';
import 'package:perfectshelter/ui/screens/home/widgets/home_shimmers.dart';
import 'package:perfectshelter/ui/screens/home/widgets/location_and_profile_widget.dart';
import 'package:perfectshelter/ui/screens/project/widgets/project_card_big.dart';
import 'package:perfectshelter/ui/screens/proprties/view_all.dart';
import 'package:perfectshelter/utils/admob/banner_ad_load_widget.dart';
import 'package:perfectshelter/utils/extensions/lib/iterable.dart';
import 'package:perfectshelter/utils/network/network_availability.dart';
import 'package:perfectshelter/utils/sliver_grid_delegate_with_fixed_cross_axis_count_and_fixed_height.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
// JWT Token

const double sidePadding = 18;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.from});
  final String? from;

  @override
  HomeScreenState createState() => HomeScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments! as Map;
    return CupertinoPageRoute(
      builder: (_) => HomeScreen(from: arguments['from'] as String),
    );
  }
}

class HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<HomeScreen> {
  @override
  bool get wantKeepAlive => true;

  bool isAlreadyShowingLocationDialog = false;
  bool isFirstTime = true;

  // Add a local ScrollController instead of using the global one
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    context.read<FetchHomePageDataCubit>().fetch(
          forceRefresh: false,
        );
    context.read<HomePageInfinityScrollCubit>().fetch();

    if (GuestChecker.value == false) {
      context.read<GetApiKeysCubit>().fetch();
    }

    initializeSettings();
    addPageScrollListener();
    _requestNotificationPermission();
    super.initState();
  }

  @override
  void dispose() {
    // Dispose the local controller
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _requestNotificationPermission() async {
    if (!(await AwesomeNotifications().isNotificationAllowed()) &&
        isFirstTime) {
      isFirstTime = false;
      // Show custom alert: open settings manually
      await showDialog<dynamic>(
        context: Constant.navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          backgroundColor: context.color.secondaryColor,
          title: CustomText(
            'allowNotifications'.translate(context),
          ),
          content: CustomText(
            'turnOnNotification'.translate(context),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: CustomText(
                'cancelBtnLbl'.translate(context),
                color: context.color.tertiaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                AwesomeNotifications().requestPermissionToSendNotifications(
                  channelKey: Constant.notificationChannel,
                  permissions: [
                    NotificationPermission.Alert,
                    NotificationPermission.Sound,
                    NotificationPermission.Badge,
                    NotificationPermission.Vibration,
                  ],
                );
              },
              child: CustomText(
                'openSettings'.translate(context),
                color: context.color.tertiaryColor,
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> initializeSettings() async {
    final settingsCubit = context.read<FetchSystemSettingsCubit>();

    if (!const bool.fromEnvironment(
      'force-disable-demo-mode',
    )) {
      Constant.isDemoModeOn =
          settingsCubit.getSetting(SystemSetting.demoMode) as bool? ?? false;
    }
  }

  void addPageScrollListener() {
    _scrollController.addListener(pageScrollListener);
  }

  void pageScrollListener() {
    ///This will load data on page end
    if (_scrollController.isEndReached()) {
      if (mounted) {
        if (context.read<HomePageInfinityScrollCubit>().hasMoreData()) {
          context.read<HomePageInfinityScrollCubit>().fetchMore();
        }
      }
    }
  }

  /// Generic method to handle 'See All' taps for different property types
  ///
  /// This method creates a ViewAllScreen with the appropriate state map and cubit,
  /// navigates to it, and ensures data is loaded if not already available.
  ///
  /// Type parameters:
  /// * [C] - The cubit type that manages the property data
  /// * [S] - The state type associated with the cubit
  /// * [I] - The initial state type
  /// * [P] - The in-progress state type
  /// * [Success] - The success state type (must implement PropertySuccessStateWireframe)
  /// * [F] - The failure state type (must implement PropertyErrorStateWireframe)
  Future<void> _handleSeeAllTap<
      C extends StateStreamable<S>,
      S,
      I,
      P,
      Success extends PropertySuccessStateWireframe,
      F extends PropertyErrorStateWireframe>({
    required String title,
    required C Function() getCubit,
    required bool Function(S state) isSuccessState,
    required Future<void> Function({bool forceRefresh}) fetchData,
  }) async {
    final stateMap = StateMap<I, P, Success, F>();

    ViewAllScreen<C, S>(
      title: title.translate(context),
      map: stateMap,
    ).open(context);

    final cubit = getCubit();
    if (!isSuccessState(cubit.state)) {
      await fetchData(forceRefresh: true);
    }
  }

  Future<void> _onTapPromotedSeeAll({required String title}) async {
    await _handleSeeAllTap<
        FetchPromotedPropertiesCubit,
        FetchPromotedPropertiesState,
        FetchPromotedPropertiesInitial,
        FetchPromotedPropertiesInProgress,
        FetchPromotedPropertiesSuccess,
        FetchPromotedPropertiesFailure>(
      title: title,
      getCubit: () => context.read<FetchPromotedPropertiesCubit>(),
      isSuccessState: (state) => state is FetchPromotedPropertiesSuccess,
      fetchData: ({bool forceRefresh = false}) => context
          .read<FetchPromotedPropertiesCubit>()
          .fetch(forceRefresh: forceRefresh),
    );
  }

  Future<void> _onTapPremiumSeeAll({required String title}) async {
    await _handleSeeAllTap<
        FetchPremiumPropertiesCubit,
        FetchPremiumPropertiesState,
        FetchPremiumPropertiesInitial,
        FetchPremiumPropertiesInProgress,
        FetchPremiumPropertiesSuccess,
        FetchPremiumPropertiesFailure>(
      title: title,
      getCubit: () => context.read<FetchPremiumPropertiesCubit>(),
      isSuccessState: (state) => state is FetchPremiumPropertiesSuccess,
      fetchData: ({bool forceRefresh = false}) => context
          .read<FetchPremiumPropertiesCubit>()
          .fetch(forceRefresh: forceRefresh),
    );
  }

  Future<void> _onTapNearByPropertiesAll({required String title}) async {
    await _handleSeeAllTap<
        FetchNearbyPropertiesCubit,
        FetchNearbyPropertiesState,
        FetchNearbyPropertiesInitial,
        FetchNearbyPropertiesInProgress,
        FetchNearbyPropertiesSuccess,
        FetchNearbyPropertiesFailure>(
      title: title,
      getCubit: () => context.read<FetchNearbyPropertiesCubit>(),
      isSuccessState: (state) => state is FetchNearbyPropertiesSuccess,
      fetchData: ({bool forceRefresh = false}) => context
          .read<FetchNearbyPropertiesCubit>()
          .fetch(forceRefresh: forceRefresh),
    );
  }

  Future<void> _onTapMostLikedAll({required String title}) async {
    await _handleSeeAllTap<
        FetchMostLikedPropertiesCubit,
        FetchMostLikedPropertiesState,
        FetchMostLikedPropertiesInitial,
        FetchMostLikedPropertiesInProgress,
        FetchMostLikedPropertiesSuccess,
        FetchMostLikedPropertiesFailure>(
      title: title,
      getCubit: () => context.read<FetchMostLikedPropertiesCubit>(),
      isSuccessState: (state) => state is FetchMostLikedPropertiesSuccess,
      fetchData: ({bool forceRefresh = false}) => context
          .read<FetchMostLikedPropertiesCubit>()
          .fetch(forceRefresh: forceRefresh),
    );
  }

  Future<void> _onTapMostViewedSeeAll({required String title}) async {
    await _handleSeeAllTap<
        FetchMostViewedPropertiesCubit,
        FetchMostViewedPropertiesState,
        FetchMostViewedPropertiesInitial,
        FetchMostViewedPropertiesInProgress,
        FetchMostViewedPropertiesSuccess,
        FetchMostViewedPropertiesFailure>(
      title: title,
      getCubit: () => context.read<FetchMostViewedPropertiesCubit>(),
      isSuccessState: (state) => state is FetchMostViewedPropertiesSuccess,
      fetchData: ({bool forceRefresh = false}) => context
          .read<FetchMostViewedPropertiesCubit>()
          .fetch(forceRefresh: forceRefresh),
    );
  }

  Future<void> _onTapPersonalizedSeeAll({required String title}) async {
    await _handleSeeAllTap<
        FetchPersonalizedPropertyList,
        FetchPersonalizedPropertyListState,
        FetchPersonalizedPropertyInitial,
        FetchPersonalizedPropertyInProgress,
        FetchPersonalizedPropertySuccess,
        FetchPersonalizedPropertyFail>(
      title: title,
      getCubit: () => context.read<FetchPersonalizedPropertyList>(),
      isSuccessState: (state) => state is FetchPersonalizedPropertySuccess,
      fetchData: ({bool forceRefresh = false}) =>
          context.read<FetchPersonalizedPropertyList>().fetch(
                loadWithoutDelay: true,
                forceRefresh: forceRefresh,
              ),
    );
  }

  Future<void> _onTapChangeLocation() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final placeMark = await Navigator.pushNamed(
      context,
      Routes.chooseLocaitonMap,
      arguments: {
        'from': 'home_location',
      },
    ) as Map?;
    try {
      final latlng = placeMark?['latlng'] as LatLng;
      final place = placeMark?['place'] as Placemark;
      final radius = placeMark?['radius'] as String? ?? '';

      await HiveUtils.setHomeLocation(
        city: place.locality ?? '',
        state: place.administrativeArea ?? '',
        latitude: latlng.latitude.toString(),
        longitude: latlng.longitude.toString(),
        country: place.country ?? '',
        placeId: place.postalCode ?? '',
        radius: radius,
      );
    } on Exception catch (e) {
      log(e.toString());
    }
  }

  Future<void> _onRefresh() async {
    await CheckInternet.check(
      onInternet: () async {
        await context.read<FetchHomePageDataCubit>().fetch(forceRefresh: false);

        await context.read<HomePageInfinityScrollCubit>().fetch();
      },
      onNoInternet: () {
        return HelperUtils.showSnackBarMessage(
          context,
          'noInternet'.translate(context),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // final homeScreenState = homeStateListener.listen(context);
    HiveUtils.getJWT()?.log('JWT');
    log(ResponsiveHelper.getScreenType(context), name: 'screenType');

    ///
    return Scaffold(
      appBar: CustomAppBar(
        backgroundColor: context.color.primaryColor,
        showBackButton: false,
        showShadow: false,
        title: const LocationAndProfileWidget(),
      ),
      backgroundColor: context.color.primaryColor,
      body: CustomRefreshIndicator(
        onRefresh: _onRefresh,
        child: Builder(
          builder: (context) {
            return BlocBuilder<FetchSystemSettingsCubit,
                FetchSystemSettingsState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: Constant.scrollPhysics,
                  padding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).padding.top,
                  ),
                  child: Column(
                    children: [
                      // Fixed sections that should always be at the top
                      const HomeSearchField(), // Search section
                      BlocConsumer<FetchHomePageDataCubit,
                          FetchHomePageDataState>(
                        listener: (context, state) {
                          if (state is FetchHomePageDataSuccess &&
                              state.refreshing != true &&
                              state.homePageDataModel
                                      .homePageLocationDataAvailable ==
                                  false &&
                              AppSettings.homePageLocatoinAlertStatus) {
                            showNoDataAtLocation(context);
                          }
                        },
                        builder: (homeContext, homeState) {
                          if (homeState is FetchHomePageDataLoading) {
                            return const HomeShimmer();
                          }
                          if (homeState is FetchHomePageDataSuccess) {
                            final home = homeState.homePageDataModel;

                            return BlocProvider(
                              create: (context) => FetchHomePageDataCubit(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  // Slider section
                                  sliderWidget(
                                    home.sliderSection ?? [],
                                  ),
                                  // Dynamic sections from API in their original order
                                  ...(home.originalSections ??
                                          <HomePageSection>[])
                                      .mapIndexed<HomePageSection, Widget>(
                                          (section, index) {
                                    final sectionTitle = home
                                            .originalSections?[index]
                                            .translatedTitle ??
                                        home.originalSections?[index].title;
                                    switch (section.type) {
                                      case 'premium_properties_section':
                                        return premiumProperties(
                                          title: sectionTitle ??
                                              UiUtils.translate(
                                                context,
                                                'premiumProperties',
                                              ),
                                          premiumProperties:
                                              home.premiumProperties ?? [],
                                        );
                                      case 'categories_section':
                                        return categoryWidget(
                                          categories:
                                              home.categoriesSection ?? [],
                                          title: sectionTitle ??
                                              'categories'.translate(context),
                                        );
                                      case 'featured_properties_section':
                                        return featuredProperties(
                                          title: sectionTitle ??
                                              UiUtils.translate(
                                                context,
                                                'promotedProperties',
                                              ),
                                          featuredProperties:
                                              home.featuredSection ?? [],
                                        );
                                      case 'most_liked_properties_section':
                                        return mostLikedProperties(
                                          title: sectionTitle ??
                                              UiUtils.translate(
                                                context,
                                                'mostLikedProperties',
                                              ),
                                          mostLikedProperties:
                                              home.mostLikedProperties ?? [],
                                        );
                                      case 'most_viewed_properties_section':
                                        return mostViewedProperties(
                                          title: sectionTitle ??
                                              UiUtils.translate(
                                                context,
                                                'mostViewed',
                                              ),
                                          mostViewedProperties:
                                              home.mostViewedProperties ?? [],
                                        );
                                      case 'projects_section':
                                        return buildProjects(
                                          title: sectionTitle ??
                                              'Project section'
                                                  .translate(context),
                                          projectSection:
                                              home.projectSection ?? [],
                                        );
                                      case 'agents_list_section':
                                        return buildAgents(
                                          title: sectionTitle ??
                                              UiUtils.translate(
                                                context,
                                                'agents',
                                              ),
                                          agents: home.agentsList ?? [],
                                        );
                                      case 'nearby_properties_section':
                                        return buildNearByProperties(
                                          title: sectionTitle ??
                                              '${UiUtils.translate(
                                                context,
                                                "nearByProperties",
                                              )} (${HiveUtils.getUserCityName()})',
                                          nearByProperties:
                                              home.nearByProperties ?? [],
                                        );
                                      case 'featured_projects_section':
                                        return buildFeaturedProjects(
                                          title: sectionTitle ??
                                              'featuredProjects'
                                                  .translate(context),
                                          projectSection:
                                              home.featuredProjectSection ?? [],
                                        );
                                      case 'user_recommendations_section':
                                        return buildPersonalizedProperty(
                                          title: sectionTitle ??
                                              'personalizedFeed'
                                                  .translate(context),
                                          personalizedProperties:
                                              home.personalizedProperties ?? [],
                                        );
                                      case 'properties_by_cities_section':
                                        return popularCityProperties(
                                          title: sectionTitle ??
                                              'popularCities'
                                                  .translate(context),
                                          cities: home.propertiesByCities ?? [],
                                        );
                                      default:
                                        return const SizedBox.shrink();
                                    }
                                  }),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          const BannerAdWidget(),
                          allProperties(context: context),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> showNoDataAtLocation(BuildContext context) {
    if (HiveUtils.isGuest() || HiveUtils.getHomeCityName() == null) {
      return Future.value();
    }

    if (isAlreadyShowingLocationDialog) return Future.value();
    isAlreadyShowingLocationDialog = true;
    return UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: 'nodatafound'.translate(context),
        titleColor: context.color.tertiaryColor,
        titleWeight: FontWeight.w600,
        showAcceptButton: false,
        showCancleButton: false,
        svgImagePath: AppIcons.noDataFound,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              'noDataFoundAtThisLocation'.translate(context),
              fontSize: context.font.md,
              color: context.color.textColorDark,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.w500,
            ),
            const SizedBox(
              height: 8,
            ),
            UiUtils.buildButton(
              context,
              buttonTitle: 'changeLocation'.translate(context),
              height: 42.rh(context),
              onPressed: () async {
                isAlreadyShowingLocationDialog = false;
                Navigator.pop(context);
                await _onTapChangeLocation();
              },
              border: BorderSide(
                color: context.color.borderColor,
              ),
              showElevation: false,
              buttonColor: context.color.primaryColor,
              textColor: context.color.tertiaryColor,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(
              height: 8,
            ),
            UiUtils.buildButton(
              context,
              buttonTitle: 'continue'.translate(context),
              height: 42.rh(context),
              showElevation: false,
              onPressed: () {
                isAlreadyShowingLocationDialog = false;
                Navigator.pop(context);
              },
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget allProperties({required BuildContext context}) {
    return BlocBuilder<HomePageInfinityScrollCubit,
        HomePageInfinityScrollState>(
      builder: (context, state) {
        if (state is HomePageInfinityScrollFailure) {
          const SizedBox.shrink();
        }
        if (state is HomePageInfinityScrollInProgress) {
          return LayoutBuilder(
            builder: (context, c) {
              return UiUtils.buildHorizontalShimmer(context);
            },
          );
        }

        if (state is HomePageInfinityScrollSuccess) {
          return Builder(
            builder: (context) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleHeader(
                    enableShowAll: false,
                    title: UiUtils.translate(
                      context,
                      'allProperties',
                    ),
                  ),
                  if (ResponsiveHelper.isLargeTablet(context) ||
                      ResponsiveHelper.isTablet(context))
                    GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        mainAxisExtent: 132.rh(context),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: sidePadding,
                      ),
                      itemCount: state.properties.length,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return PropertyHorizontalCard(
                          property: state.properties[index],
                        );
                      },
                    )
                  else
                    ListView.separated(
                      separatorBuilder: (context, index) {
                        return SizedBox(height: 8.rh(context));
                      },
                      padding: const EdgeInsets.symmetric(
                        horizontal: sidePadding,
                      ),
                      itemCount: state.properties.length,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return PropertyHorizontalCard(
                          property: state.properties[index],
                        );
                      },
                    ),
                  if (context
                      .watch<HomePageInfinityScrollCubit>()
                      .isLoadingMore())
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Center(
                        child: UiUtils.progress(
                          height: 30.rh(context),
                          width: 30.rw(context),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget buildProjects({
    required String title,
    required List<ProjectModel> projectSection,
  }) {
    return Column(
      children: [
        if (projectSection.isNotEmpty) ...[
          TitleHeader(
            title: title,
            onSeeAll: () {
              Navigator.pushNamed(
                context,
                Routes.allProjectsScreen,
                arguments: {
                  'isPromoted': false,
                  'title': title,
                },
              );
            },
          ),
          Container(
            height: 268.rh(context),
            alignment: AlignmentDirectional.centerStart,
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return SizedBox(width: 8.rw(context));
              },
              padding: EdgeInsets.symmetric(horizontal: 18.rw(context)),
              itemCount: projectSection.length,
              physics: Constant.scrollPhysics,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final project = projectSection[index];
                return ProjectCardBig(
                  project: project,
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget buildFeaturedProjects({
    required String title,
    required List<ProjectModel> projectSection,
  }) {
    return Column(
      children: [
        if (projectSection.isNotEmpty) ...[
          TitleHeader(
            title: title,
            onSeeAll: () {
              Navigator.pushNamed(
                context,
                Routes.allProjectsScreen,
                arguments: {
                  'isPromoted': true,
                  'title': title,
                },
              );
            },
          ),
          Container(
            alignment: AlignmentDirectional.centerStart,
            height: 268.rh(context),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: sidePadding),
              itemCount: projectSection.length,
              physics: Constant.scrollPhysics,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final project = projectSection[index];
                return Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: index == projectSection.length - 1 ? 0 : 10,
                  ),
                  child: ProjectCardBig(
                    project: project,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget buildAgents({
    required String title,
    required List<AgentModel> agents,
  }) {
    if (agents.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitleHeader(
            title: title,
            onSeeAll: () {
              Navigator.pushNamed(
                context,
                Routes.agentListScreen,
                arguments: {
                  'title': title,
                },
              );
            },
          ),
          SizedBox(
            height: 258.rh(context),
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return SizedBox(width: 8.rw(context));
              },
              itemCount: agents.length < 5 ? agents.length : 5,
              physics: Constant.scrollPhysics,
              padding: EdgeInsets.symmetric(horizontal: 18.rw(context)),
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final agent = agents[index];
                return AgentCard(
                  agent: agent,
                  propertyCount: agent.propertyCount,
                  name: agent.name,
                );
              },
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget popularCityProperties({
    required String title,
    required List<City> cities,
  }) {
    if (cities.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routes.cityListScreen,
                  arguments: {
                    'title': title,
                  },
                );
              },
              child: Stack(
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: context.screenWidth,
                    height: 120.rh(context),
                    child: CustomImage(
                      width: double.infinity,
                      height: 120.rh(context),
                      imageUrl: AppIcons.citySectionTitleImage,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  Container(
                    width: context.screenWidth,
                    height: 120.rh(context),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 18,
                    start: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3.rw(context),
                              height: 20.rh(context),
                              color: Colors.white,
                            ),
                            const SizedBox(
                              width: 4,
                            ),
                            CustomText(
                              title.firstUpperCase(),
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: context.font.md,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        CustomText(
                          '${cities.length.clamp(0, 10)}${cities.length > 10 ? '+' : ''} ${'cities'.translate(context)}',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: context.font.xs,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          CustomImageGrid(
            cities: cities,
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget mostViewedProperties({
    required String title,
    required List<PropertyModel> mostViewedProperties,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mostViewedProperties.isNotEmpty)
          TitleHeader(
            onSeeAll: () async {
              await _onTapMostViewedSeeAll(title: title);
            },
            title: title,
          ),
        buildMostViewedProperties(mostViewedProperties),
      ],
    );
  }

  Widget mostLikedProperties({
    required String title,
    required List<PropertyModel> mostLikedProperties,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mostLikedProperties.isNotEmpty) ...[
          TitleHeader(
            onSeeAll: () async {
              await _onTapMostLikedAll(title: title);
            },
            title: title,
          ),
          buildMostLikedProperties(mostLikedProperties),
        ],
      ],
    );
  }

  Widget premiumProperties({
    required String title,
    required List<PropertyModel> premiumProperties,
  }) {
    return Column(
      children: [
        if (premiumProperties.isNotEmpty) ...[
          TitleHeader(
            onSeeAll: () async {
              await _onTapPremiumSeeAll(title: title);
            },
            title: title,
          ),
          buildPremiumProperties(premiumProperties),
        ],
      ],
    );
  }

  Widget buildPremiumProperties(List<PropertyModel> premiumProperties) {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(
        horizontal: sidePadding,
      ),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
        crossAxisCount: ResponsiveHelper.isLargeTablet(context)
            ? 4
            : ResponsiveHelper.isTablet(context)
                ? 3
                : 2,
        height: 284.rh(context),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: premiumProperties.length.clamp(
        0,
        ResponsiveHelper.isLargeTablet(context)
            ? 8
            : ResponsiveHelper.isTablet(context)
                ? 6
                : 4,
      ),
      itemBuilder: (context, index) {
        final property = premiumProperties[index];
        return BlocProvider(
          create: (context) => AddToFavoriteCubitCubit(),
          child: PropertyCardBig(
            isFromCompare: false,
            showEndPadding: false,
            isFirst: index == 0,
            property: property,
          ),
        );
      },
    );
  }

  Widget featuredProperties({
    required List<PropertyModel> featuredProperties,
    required String title,
  }) {
    if (featuredProperties.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitleHeader(
            onSeeAll: () async {
              await _onTapPromotedSeeAll(title: title);
            },
            title: title,
          ),
          buildPromotedProperties(featuredProperties),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget sliderWidget(List<HomeSlider> banners) {
    if (banners.isNotEmpty) {
      final directionalBanners = Directionality.of(context) == TextDirection.rtl
          ? banners.reversed.toList()
          : banners;
      return Column(
        children: <Widget>[
          SizedBox(
            height: 15.rh(context),
          ),
          CarouselSlider(
            items: directionalBanners.map((e) {
              return Builder(
                builder: (context) {
                  return _buildBanner(e);
                },
              );
            }).toList(),
            options: CarouselOptions(
              height: 170.rs(context),
              viewportFraction: 1,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {},
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBanner(HomeSlider banner) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: sidePadding),
      child: GestureDetector(
        onTap: () async {
          if (banner.sliderType == '1') {
            UiUtils.showFullScreenImage(
              context,
              provider: NetworkImage(banner.image.toString()),
            );
          } else if (banner.sliderType == '2') {
            await Navigator.pushNamed(
              context,
              Routes.propertiesList,
              arguments: {
                'catID': banner.categoryId,
                'catName': banner.category!.translatedName ??
                    banner.category!.category,
              },
            );
          } else if (banner.sliderType == '3') {
            try {
              unawaited(Widgets.showLoader(context));
              final fetch = PropertyRepository();
              final dataOutput = await fetch.fetchPropertyFromPropertyId(
                id: int.parse(banner.propertysId!),
                isMyProperty: banner.property!.addedBy.toString() ==
                    HiveUtils.getUserId(),
              );
              Future.delayed(
                Duration.zero,
                () {
                  Widgets.hideLoder(context);
                  HelperUtils.goToNextPage(
                    Routes.propertyDetails,
                    context,
                    false,
                    args: {
                      'propertyData': dataOutput,
                      'propertiesList': dataOutput,
                      'fromMyProperty': false,
                    },
                  );
                },
              );
            } on Exception catch (e) {
              log('Error is $e');
              Widgets.hideLoder(context);
            }
          } else if (banner.sliderType == '4') {
            await url_launcher.launchUrl(Uri.parse(banner.link!));
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomImage(
            imageUrl: banner.image.toString(),
            width: context.screenWidth,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }

  Widget buildCityCard(FetchCityCategorySuccess state, int index) {
    if (index >= state.cities.length) {
      return const SizedBox.shrink();
    }
    final city = state.cities[index];
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: GestureDetector(
        onTap: () {
          context.read<FetchCityPropertyList>().fetch(
                cityName: city.name,
                forceRefresh: true,
              );
          Navigator.push(
            context,
            CupertinoPageRoute<dynamic>(
              builder: (context) {
                return CityPropertiesScreen(
                  cityName: city.name,
                );
              },
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomImage(
              imageUrl: city.image,
              height: 100,
              width: 100,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.68),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              bottom: 8,
              start: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    city.name.firstUpperCase(),
                    color: context.color.buttonColor,
                    fontSize: context.font.sm,
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  CustomText(
                    '${city.count} ${'properties'.translate(context)}',
                    color: context.color.buttonColor,
                    fontSize: context.font.xs,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPromotedProperties(List<PropertyModel> promotedProperties) {
    return SizedBox(
      height: 284.rh(context),
      child: ListView.separated(
        separatorBuilder: (context, index) {
          return SizedBox(width: 8.rw(context));
        },
        itemCount: promotedProperties.length.clamp(0, 6),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          horizontal: sidePadding,
        ),
        physics: Constant.scrollPhysics,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return BlocProvider(
            create: (context) {
              return AddToFavoriteCubitCubit();
            },
            child: PropertyCardBig(
              key: UniqueKey(),
              isFirst: index == 0,
              property: promotedProperties[index],
              isFromCompare: false,
            ),
          );
        },
      ),
    );
  }

  Widget buildMostLikedProperties(List<PropertyModel> mostLiked) {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(
        horizontal: sidePadding,
      ),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
        mainAxisSpacing: 6,
        crossAxisCount: ResponsiveHelper.isLargeTablet(context)
            ? 4
            : ResponsiveHelper.isTablet(context)
                ? 3
                : 2,
        height: 284.rh(context),
        crossAxisSpacing: 6,
      ),
      itemCount: mostLiked.length.clamp(
        0,
        ResponsiveHelper.isLargeTablet(context)
            ? 8
            : ResponsiveHelper.isTablet(context)
                ? 6
                : 4,
      ),
      itemBuilder: (context, index) {
        final properties = mostLiked[index];
        return BlocProvider(
          create: (context) => AddToFavoriteCubitCubit(),
          child: PropertyCardBig(
            isFromCompare: false,
            showEndPadding: false,
            isFirst: index == 0,
            property: properties,
          ),
        );
      },
    );
  }

  Widget buildNearByProperties({
    required String title,
    required List<PropertyModel> nearByProperties,
  }) {
    if (nearByProperties.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleHeader(
          onSeeAll: () async {
            await _onTapNearByPropertiesAll(title: title);
          },
          title: title,
        ),
        SizedBox(
          height: 284.rh(context),
          child: ListView.separated(
            separatorBuilder: (context, index) {
              return SizedBox(width: 8.rw(context));
            },
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              horizontal: sidePadding,
            ),
            physics: Constant.scrollPhysics,
            itemCount: nearByProperties.length.clamp(0, 6),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              var model = nearByProperties[index];
              model = context.watch<PropertyEditCubit>().get(model);
              return PropertyCardBig(
                property: model,
                isFromCompare: false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildMostViewedProperties(List<PropertyModel> mostViewed) {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(
        horizontal: sidePadding,
      ),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
        mainAxisSpacing: 8,
        crossAxisCount: ResponsiveHelper.isLargeTablet(context)
            ? 4
            : ResponsiveHelper.isTablet(context)
                ? 3
                : 2,
        height: 284.rh(context),
        crossAxisSpacing: 8,
      ),
      itemCount: mostViewed.length.clamp(
        0,
        ResponsiveHelper.isLargeTablet(context)
            ? 8
            : ResponsiveHelper.isTablet(context)
                ? 6
                : 4,
      ),
      itemBuilder: (context, index) {
        final property = mostViewed[index];
        return BlocProvider(
          create: (context) => AddToFavoriteCubitCubit(),
          child: PropertyCardBig(
            showEndPadding: false,
            isFirst: index == 0,
            isFromCompare: false,
            property: property,
          ),
        );
      },
    );
  }

  Widget categoryWidget({
    required List<Category> categories,
    required String title,
  }) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TitleHeader(
          title: title,
          enableShowAll: true,
          onSeeAll: () {
            Navigator.pushNamed(context, Routes.categories);
          },
        ),
        SizedBox(
          height: 44.rh(context),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: sidePadding,
            ),
            physics: Constant.scrollPhysics,
            scrollDirection: Axis.horizontal,
            itemCount: categories.length.clamp(0, Constant.maxCategoryLength),
            itemBuilder: (context, index) {
              final category = categories[index];
              Constant.propertyFilter = null;
              return buildCategoryCard(
                context: context,
                category: category,
                frontSpacing: index != 0,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildCategoryCard({
    required BuildContext context,
    required Category category,
    bool? frontSpacing,
  }) {
    return CategoryCard(
      frontSpacing: frontSpacing ?? false,
      onTapCategory: (category) {
        currentVisitingCategoryId = category.id;
        currentVisitingCategory = category;
        Navigator.of(context).pushNamed(
          Routes.propertiesList,
          arguments: {
            'catID': category.id,
            'catName': category.translatedName ?? category.category
          },
        );
      },
      category: category,
    );
  }

  Widget buildPersonalizedProperty({
    required String title,
    required List<PropertyModel> personalizedProperties,
  }) {
    if (personalizedProperties.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleHeader(
          onSeeAll: () async {
            await _onTapPersonalizedSeeAll(title: title);
          },
          title: title,
        ),
        SizedBox(
          height: 284.rh(context),
          child: ListView.separated(
            separatorBuilder: (context, index) {
              return SizedBox(width: 8.rw(context));
            },
            itemCount: personalizedProperties.length.clamp(0, 6),
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              horizontal: sidePadding,
            ),
            physics: Constant.scrollPhysics,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              var propertyModel = personalizedProperties[index];
              propertyModel =
                  context.watch<PropertyEditCubit>().get(propertyModel);
              return BlocProvider(
                create: (context) {
                  return AddToFavoriteCubitCubit();
                },
                child: PropertyCardBig(
                  key: UniqueKey(),
                  showEndPadding: true,
                  isFromCompare: false,
                  isFirst: index == 0,
                  property: propertyModel,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
