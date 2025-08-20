import 'package:ebroker/data/cubits/agents/fetch_project_by_agents_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_projects_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_property_by_agent_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_property_cubit.dart';
import 'package:ebroker/data/model/agent/agents_properties_models/customer_data.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agents/agent_properties.dart';
import 'package:ebroker/ui/screens/agents/agents_projects.dart';
import 'package:ebroker/ui/screens/widgets/read_more_text.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AgentDetailsScreen extends StatefulWidget {
  const AgentDetailsScreen({
    required this.isAdmin,
    required this.agentID,
    super.key,
  });

  final bool isAdmin;
  final String agentID;

  static Route<dynamic> route(RouteSettings routeSettings) {
    final argument = routeSettings.arguments! as Map;

    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => FetchAgentsPropertyCubit(),
          ),
          BlocProvider(
            create: (_) => FetchAgentsProjectCubit(),
          ),
          BlocProvider(
            create: (_) => FetchProjectByAgentCubit(),
          ),
          BlocProvider(
            create: (_) => FetchPropertyByAgentCubit(),
          ),
        ],
        child: AgentDetailsScreen(
          isAdmin: argument['isAdmin'] as bool,
          agentID: argument['agentID'] as String,
        ),
      ),
    );
  }

  @override
  State<AgentDetailsScreen> createState() => _AgentDetailsScreenState();
}

class _AgentDetailsScreenState extends State<AgentDetailsScreen>
    with TickerProviderStateMixin {
  bool showProjects = false;
  bool isProjectAllowed = false;
  TabController? _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 2, vsync: this);
    getAgentProjectsAndProperties();

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // A small buffer (e.g., 20 pixels) for reaching the end to account for floating point inaccuracies
    // or slight overscrolls.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 20) {
      if (_tabController?.index == 1) {
        // Properties Tab
        if (context.read<FetchAgentsPropertyCubit>().hasMoreData()) {
          context.read<FetchAgentsPropertyCubit>().fetchMore(
                isAdmin: widget.isAdmin,
              );
        }
      } else if (_tabController?.index == 2) {
        // Projects Tab
        if (context.read<FetchAgentsProjectCubit>().hasMoreData()) {
          context.read<FetchAgentsProjectCubit>().fetchMore(
                isAdmin: widget.isAdmin,
              );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController
      ..removeListener(_scrollListener)
      ..dispose();
    super.dispose();
  }

  Future<void> getAgentProjectsAndProperties() async {
    // Ensure initial fetches are complete before potentially updating tab controller length
    await context.read<FetchAgentsProjectCubit>().fetchAgentsProject(
          forceRefresh: true,
          agentId: widget.agentID,
          isAdmin: widget.isAdmin,
        );

    final projectState = context.read<FetchAgentsProjectCubit>().state;
    if (projectState is FetchAgentsProjectSuccess) {
      final hasProjects =
          projectState.agentsProperty.customerData.projectCount != '0';
      final needsProjectsTab = hasProjects;

      // Only update state if tab count needs to change to prevent unnecessary rebuilds
      if (showProjects != needsProjectsTab) {
        setState(() {
          showProjects = needsProjectsTab;
          isProjectAllowed = projectState.agentsProperty.isFeatureAvailable;

          // Re-initialize tab controller if the number of tabs changes
          _tabController?.dispose();
          _tabController =
              TabController(length: showProjects ? 3 : 2, vsync: this);
        });
      }
    }

    await context.read<FetchAgentsPropertyCubit>().fetchAgentsProperty(
          forceRefresh: true,
          agentId: widget.agentID,
          isAdmin: widget.isAdmin,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: CustomAppBar(
        title: CustomText(UiUtils.translate(context, 'agentDetails')),
      ),
      body: BlocBuilder<FetchAgentsPropertyCubit, FetchAgentsPropertyState>(
        builder: (context, state) {
          if (state is FetchAgentsPropertyLoading ||
              state is FetchAgentsPropertyInitial) {
            return _buildShimmerView();
          }
          if (state is FetchAgentsPropertyFailure) {
            return const Center(child: SomethingWentWrong());
          }
          if (state is FetchAgentsPropertySuccess) {
            return _buildNestedScrollView(
                state.agentsProperty.customerData, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildShimmerView() {
    return Column(
      // Changed from CustomScrollView for shimmer as it's a fixed view
      children: [
        Container(
          height: 224.rh(context),
          margin: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
          ),
          child: const CustomShimmer(),
        ),
        Container(
          height: 40.rh(context),
          margin: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
          ),
          child: const CustomShimmer(),
        ),
        // If this part needs to scroll for shimmer, wrap in Expanded + ListView
        // For a shimmer, a simple container is often fine unless it's very tall
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            width: MediaQuery.of(context).size.width,
            child: const CustomShimmer(),
          ),
        ),
      ],
    );
  }

  Widget _buildNestedScrollView(
      CustomerData agent, FetchAgentsPropertySuccess propertyState) {
    return BlocConsumer<FetchProjectByAgentCubit, FetchProjectByAgentState>(
      listener: (context, state) {
        if (state is FetchProjectByAgentSuccess) {
          HelperUtils.goToNextPage(
            Routes.projectDetailsScreen,
            context,
            false,
            args: {
              'project': state.project,
            },
          );
        }
      },
      builder: (context, projectState) {
        return BlocConsumer<FetchPropertyByAgentCubit,
            FetchPropertyByAgentState>(
          listener: (context, state) {
            if (state is FetchPropertyByAgentSuccess) {
              HelperUtils.goToNextPage(
                Routes.propertyDetails,
                context,
                false,
                args: {
                  'propertyData': state.property,
                },
              );
            }
          },
          builder: (context, state) {
            return NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollEndNotification) {
                  _scrollListener();
                }
                return true;
              },
              child: NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverToBoxAdapter(
                      child: buildAgentProfileCard(agent: agent),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyTabBarDelegate(
                        tabBar: Container(
                          height: 48.rh(context),
                          padding: const EdgeInsets.all(4),
                          width: MediaQuery.sizeOf(context).width,
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.color.secondaryColor,
                            border: Border.all(
                              color: context.color.borderColor,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4),
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            dividerColor: Colors.transparent,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelStyle: TextStyle(
                              fontSize: context.font.xs,
                              fontWeight: FontWeight.w600,
                              overflow: TextOverflow.ellipsis,
                            ),
                            indicator: BoxDecoration(
                              color: context.color.tertiaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            labelColor: context.color.buttonColor,
                            unselectedLabelColor: context.color.inverseSurface,
                            tabs: [
                              Tab(
                                text: UiUtils.translate(context, 'details'),
                              ),
                              Tab(
                                text: UiUtils.translate(context, 'properties'),
                              ),
                              if (showProjects)
                                Tab(
                                  text: UiUtils.translate(context, 'projects'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ];
                },
                body: Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          SingleChildScrollView(
                            child: detailsTab(context,
                                propertyState.agentsProperty.customerData),
                          ),
                          AgentProperties(
                            agentId: propertyState
                                .agentsProperty.customerData.id
                                .toString(),
                            isAdmin: widget.isAdmin,
                          ),
                          if (showProjects && isProjectAllowed)
                            AgentProjects(
                              agentId: propertyState
                                  .agentsProperty.customerData.id
                                  .toString(),
                              isAdmin: widget.isAdmin,
                            ),
                          if (showProjects && !isProjectAllowed)
                            Builder(
                              builder: (context) {
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) {
                                    GuestChecker.check(
                                      onNotGuest: () {
                                        UiUtils.showBlurredDialoge(
                                          context,
                                          dialog:
                                              const BlurredSubscriptionDialogBox(
                                            packageType: SubscriptionPackageType
                                                .projectAccess,
                                            isAcceptContainesPush: true,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
                                  _tabController?.animateTo(1);
                                });
                                return Container();
                              },
                            ),
                        ],
                      ),
                    ),
                    // Bottom Button will scroll with the content of the active tab
                    if (propertyState.agentsProperty.premiumPropertyCount != '0' &&
                        propertyState.agentsProperty.isPackageAvailable ==
                            false &&
                        propertyState.agentsProperty.isFeatureAvailable ==
                            false)
                      bottomButton(
                        projectOrPropertyCount:
                            propertyState.agentsProperty.premiumPropertyCount,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildAgentProfileCard({
    required CustomerData agent,
  }) {
    final showSocialAccounts =
        (agent.facebookId != null && agent.facebookId != '') ||
            (agent.twitterId != null && agent.twitterId != '') ||
            (agent.instagramId != null && agent.instagramId != '') ||
            (agent.youtubeId != null && agent.youtubeId != '');
    final showSoldRentedCount =
        agent.propertiesSoldCount != '0' || agent.propertiesRentedCount != '0';

    return Container(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
      ),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        border: Border.all(
          color: context.color.borderColor,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 115.rw(context),
                height: 128.rh(context),
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(4),
                      ),
                      child: CustomImage(
                        fit: BoxFit.fill,
                        height: 128.rh(context),
                        width: 115.rw(context),
                        imageUrl: agent.profile,
                      ),
                    ),
                    if (agent.isVerified ?? false)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: buildVerifiedContainer(),
                      ),
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      agent.name.firstUpperCase(),
                      maxLines: 2,
                      fontWeight: FontWeight.w500,
                      fontSize: context.font.sm,
                    ),
                    const SizedBox(height: 8),
                    UiUtils.getDivider(context),
                    const SizedBox(height: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildCallEmailContainer(
                          title: 'call'.translate(context),
                          icon: AppIcons.call,
                          value: agent.mobile,
                          onTap: () {
                            _onTapCall(contactNumber: agent.mobile);
                          },
                        ),
                        const SizedBox(height: 8),
                        buildCallEmailContainer(
                          title: 'email'.translate(context),
                          icon: AppIcons.email,
                          value: agent.email,
                          onTap: () {
                            _onTapEmail(email: agent.email);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showSoldRentedCount || showSocialAccounts) ...[
            const SizedBox(height: 8),
            UiUtils.getDivider(context),
            const SizedBox(height: 8),
          ],
          if (showSoldRentedCount) ...[
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.color.textColorDark.withValues(alpha: .1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (agent.propertiesSoldCount != '0')
                        CustomText(
                          '${'soldProperties'.translate(context)}: ${agent.propertiesSoldCount}',
                          fontSize: context.font.xxs,
                          fontWeight: FontWeight.w500,
                          maxLines: 1,
                          color: context.color.textLightColor,
                        ),
                      if (agent.propertiesSoldCount != '0' &&
                          agent.propertiesRentedCount != '0')
                        Container(
                          margin: const EdgeInsetsDirectional.only(
                            start: 4,
                            end: 4,
                          ),
                          height: 8,
                          width: 1,
                          color: context.color.textLightColor
                              .withValues(alpha: 0.2),
                        ),
                      if (agent.propertiesRentedCount != '0')
                        CustomText(
                          '${'rentedProperties'.translate(context)}: ${agent.propertiesRentedCount}',
                          fontSize: context.font.xxs,
                          fontWeight: FontWeight.w500,
                          color: context.color.textLightColor,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
                if (showSocialAccounts) const SizedBox(height: 8),
              ],
            ),
          ],
          if (showSocialAccounts) ...[
            Row(
              children: [
                CustomText(
                  'followMe'.translate(context),
                  fontSize: context.font.sm,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(width: 8),
                if (agent.facebookId != null && agent.facebookId != '')
                  socialButton(
                    context: context,
                    name: 'facebook',
                    url: agent.facebookId ?? '',
                  ),
                if (agent.twitterId != null && agent.twitterId != '')
                  socialButton(
                    context: context,
                    name: 'twitter',
                    url: agent.twitterId ?? '',
                  ),
                if (agent.instagramId != null && agent.instagramId != '')
                  socialButton(
                    context: context,
                    name: 'instagram',
                    url: agent.instagramId ?? '',
                  ),
                if (agent.youtubeId != null && agent.youtubeId != '')
                  socialButton(
                    context: context,
                    name: 'youtube',
                    url: agent.youtubeId ?? '',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget buildVerifiedContainer() {
    return Container(
      padding: EdgeInsets.only(
        left: 8.rw(context),
        right: 8.rw(context),
        top: 4.rh(context),
        bottom: 4.rh(context),
      ),
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          CustomImage(
            imageUrl: AppIcons.verified,
            fit: BoxFit.contain,
            height: 18.rh(context),
            width: 18.rw(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: CustomText(
              'verified'.translate(context),
              fontSize: context.font.xs,
              maxLines: 1,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget socialButton({
    required BuildContext context,
    required String name,
    required String url,
  }) {
    final String iconName;
    switch (name) {
      case 'facebook':
        iconName = AppIcons.facebook;
      case 'twitter':
        iconName = AppIcons.twitter;
      case 'instagram':
        iconName = AppIcons.instagram;
      case 'youtube':
        iconName = AppIcons.youtube;
      default:
        iconName = '';
    }
    if (iconName == '') {
      return const SizedBox.shrink();
    }
    final uri = Uri.parse(url);
    return GestureDetector(
      onTap: () {
        _launchUrl(uri);
      },
      child: Container(
        height: 24.rh(context),
        width: 24.rw(context),
        alignment: Alignment.center,
        margin: const EdgeInsetsDirectional.only(end: 8),
        decoration: BoxDecoration(
          color: context.color.textLightColor.withValues(alpha: .1),
          shape: BoxShape.circle,
        ),
        child: CustomImage(
          height: 24.rh(context),
          width: 24.rw(context),
          imageUrl: iconName,
          color: context.color.textColorDark,
        ),
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget bottomButton({required String projectOrPropertyCount}) {
    return Container(
      color: context.color.secondaryColor,
      padding: const EdgeInsetsDirectional.only(
        start: 18,
        end: 18,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              end: 12,
              bottom: 8,
              top: 8,
            ),
            child: Row(
              children: [
                CustomImage(
                  imageUrl: AppIcons.info,
                  height: 20,
                  width: 20,
                ),
                const SizedBox(
                  width: 4,
                ),
                CustomText(
                  '${'unlock'.translate(context)} $projectOrPropertyCount ${'premiumProperties'.translate(context)}',
                  fontSize: context.font.sm,
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
          UiUtils.buildButton(
            context,
            onPressed: () async {
              await GuestChecker.check(
                onNotGuest: () {
                  Navigator.pushNamed(
                    context,
                    Routes.subscriptionPackageListRoute,
                    arguments: {
                      'from': 'agentDetails',
                      'isBankTransferEnabled': (context
                                  .read<GetApiKeysCubit>()
                                  .state as GetApiKeysSuccess)
                              .bankTransferStatus ==
                          '1',
                    },
                  );
                },
              );
            },
            height: 48.rh(context),
            fontSize: context.font.md,
            buttonTitle: UiUtils.translate(context, 'unlockPremium'),
          ),
        ],
      ),
    );
  }

  Widget detailsTab(BuildContext context, CustomerData customerData) {
    return Container(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        border: Border.all(
          color: context.color.borderColor,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'addressLbl'.translate(context),
            fontSize: context.font.sm,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          ReadMoreText(
            text: customerData.address ?? '',
            style: TextStyle(
              fontSize: context.font.xs,
              fontWeight: FontWeight.w500,
              color: context.color.textLightColor,
            ),
          ),
          const SizedBox(height: 8),
          UiUtils.getDivider(context),
          const SizedBox(height: 8),
          if (customerData.aboutMe!.isNotEmpty) ...[
            CustomText(
              'aboutAgent'.translate(context),
              fontSize: context.font.sm,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 8),
            CustomText(
              customerData.aboutMe ?? '',
              fontSize: context.font.xs,
              fontWeight: FontWeight.w500,
              color: context.color.textLightColor,
              maxLines: 100,
            ),
          ],
        ],
      ),
    );
  }

  List<String> locationName({
    required BuildContext context,
    required CustomerData customerData,
  }) {
    final location = <String>[
      if (customerData.city!.isNotEmpty) '${customerData.city}',
      if (customerData.state!.isNotEmpty) ...[
        if (customerData.city!.isNotEmpty) ', ',
        '${customerData.state}',
      ],
      if (customerData.country!.isNotEmpty) ...[
        if (customerData.state!.isNotEmpty || customerData.city!.isNotEmpty)
          ',',
        '${customerData.country}',
      ],
    ];

    if (location.isEmpty) {
      return [];
    } else {
      return location;
    }
  }

  Widget buildCallEmailContainer({
    required String title,
    required String icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 40.rh(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              width: 28.rw(context),
              height: 28.rh(context),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.color.textLightColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: CustomImage(
                imageUrl: icon,
                color: context.color.textColorDark,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  fontSize: context.font.sm,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 4),
                CustomText(
                  value,
                  fontWeight: FontWeight.w500,
                  fontSize: context.font.xxs,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTapCall({
    required String contactNumber,
  }) async {
    await GuestChecker.check(
      onNotGuest: () async {
        final url = Uri.parse('tel: +$contactNumber');
        try {
          await launchUrl(url);
        } on Exception catch (e) {
          throw Exception('Error calling $e');
        }
      },
    );
  }

  Future<void> _onTapEmail({
    required String email,
  }) async {
    await GuestChecker.check(
      onNotGuest: () async {
        final url = Uri.parse('mailto: +$email');
        try {
          await launchUrl(url);
        } on Exception catch (e) {
          throw Exception('Error mail $e');
        }
      },
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  _StickyTabBarDelegate({required this.tabBar});
  final Widget tabBar;

  @override
  double get minExtent => 80;
  @override
  double get maxExtent => 80;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: context.color.backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
