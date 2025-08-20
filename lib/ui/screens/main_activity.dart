import 'dart:math';

import 'package:perfectshelter/data/model/system_settings_model.dart';
import 'package:perfectshelter/data/repositories/check_package.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/chat/chat_list_screen.dart';
import 'package:perfectshelter/ui/screens/home/home_screen.dart';
import 'package:perfectshelter/ui/screens/proprties/my_properties_screen.dart';
import 'package:perfectshelter/ui/screens/userprofile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

List<PropertyModel> myPropertylist = [];
Map<String, dynamic> searchbody = {};
String selectedcategoryId = '0';
String selectedcategoryName = '';
dynamic selectedCategory;
bool isFirstTime = true;

//this will set when i will visit in any category
dynamic currentVisitingCategoryId = '';
dynamic currentVisitingCategory = '';

List<int> navigationStack = [0];

ScrollController homeScreenController = ScrollController();
ScrollController chatScreenController = ScrollController();
ScrollController sellScreenController = ScrollController();
ScrollController rentScreenController = ScrollController();
ScrollController soldScreenController = ScrollController();
ScrollController rentedScreenController = ScrollController();
ScrollController profileScreenController = ScrollController();
ScrollController agentsListScreenController = ScrollController();
ScrollController faqsListScreenController = ScrollController();
ScrollController cityScreenController = ScrollController();

List<ScrollController> controllerList = [
  faqsListScreenController,
  agentsListScreenController,
  homeScreenController,
  chatScreenController,
  if (propertyScreenCurrentPage == 0) ...[
    sellScreenController,
  ] else if (propertyScreenCurrentPage == 1) ...[
    rentScreenController,
  ] else if (propertyScreenCurrentPage == 2) ...[
    soldScreenController,
  ] else if (propertyScreenCurrentPage == 3) ...[
    rentedScreenController,
  ],
  profileScreenController,
];

//
class MainActivity extends StatefulWidget {
  const MainActivity({required this.from, super.key});

  final String from;

  @override
  State<MainActivity> createState() => MainActivityState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map? ?? {};
    return CupertinoPageRoute(
      builder: (_) =>
          MainActivity(from: arguments['from'] as String? ?? 'main'),
    );
  }
}

class MainActivityState extends State<MainActivity>
    with TickerProviderStateMixin {
  int currtab = 0;
  static final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final List<dynamic> _pageHistory = [];
  late PageController pageController;
  DateTime? currentBackPressTime;

  // Artboard? artboard;
  bool isReverse = true;

  // StateMachineController? _controller;
  bool isAddMenuOpen = false;
  int rotateAnimationDurationMs = 2000;
  bool showSellRentButton = false;

  ///Animation for sell and rent button
  ///
  late AnimationController plusAnimationController = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  );
  late final AnimationController _forProjectAnimationController =
      AnimationController(
    vsync: this,
    duration: const Duration(
      milliseconds: 400,
    ),
    reverseDuration: const Duration(
      milliseconds: 400,
    ),
  );
  late final AnimationController _forPropertyController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 300),
  );

  ///END: Animation for sell and rent button
  late final Animation<double> _projectTween =
      Tween<double>(begin: -60.rh(context), end: 80.rh(context)).animate(
    CurvedAnimation(
      parent: _forProjectAnimationController,
      curve: Curves.easeIn,
    ),
  );
  late final Animation<double> _propertyTween =
      Tween<double>(begin: -60.rh(context), end: 30.rh(context)).animate(
    CurvedAnimation(parent: _forPropertyController, curve: Curves.easeIn),
  );

  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    plusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    if (appSettings.isUserActive == false) {
      Future.delayed(
        Duration.zero,
        () {
          HiveUtils.logoutUser(context, onLogout: () {});
        },
      );
    }

    GuestChecker.setContext(context);
    GuestChecker.set('main_activity', isGuest: HiveUtils.isGuest());
    final settings = context.read<FetchSystemSettingsCubit>();
    if (!const bool.fromEnvironment(
      'force-disable-demo-mode',
    )) {
      Constant.isDemoModeOn =
          settings.getSetting(SystemSetting.demoMode) as bool? ?? false;
    }
    final numberWithSuffix =
        settings.getSetting(SystemSetting.numberWithSuffix);
    if (numberWithSuffix == '1') {
      Constant.isNumberWithSuffix = true;
    } else {
      Constant.isNumberWithSuffix = false;
    }

    if (Constant.isDemoModeOn) {
      HiveUtils.setLocation(
        city: 'Bhuj',
        state: 'Gujrat',
        country: 'India',
        latitude: AppSettings.latitude,
        longitude: AppSettings.longitude,
        placeId: 'ChIJF28LAAniUDkRpnQHr1jzd3A',
      );
      HiveUtils.setHomeLocation(
        city: 'Bhuj',
        state: 'Gujrat',
        country: 'India',
        latitude: AppSettings.latitude,
        longitude: AppSettings.longitude,
        placeId: 'ChIJF28LAAniUDkRpnQHr1jzd3A',
        radius: AppSettings.maxRadius,
      );
    }

    ///this will check if your profile is complete or not if it is incomplete it will redirect you to the edit profile page
    // completeProfileCheck();

    ///This will check for update
    versionCheck(settings);

    ///This will check if location is set or not , If it is not set it will show popup dialoge so you can set for better result
    if (GuestChecker.value == false) {
      locationSetCheck();
    }

//This will init page controller
    initPageController();
  }

  void addHistory(int index) {
    final stack = navigationStack;

    if (stack.last != index) {
      if (index == 1 || index == 3) {
        if (GuestChecker.value == false) {
          stack.add(index);
          navigationStack = stack;
        }
      } else {
        stack.add(index);
        navigationStack = stack;
      }
    }

    setState(() {});
  }

  void initPageController() {
    pageController = PageController()
      ..addListener(() {
        _pageHistory.insert(0, pageController.page);
      });
  }

  Future<void> versionCheck(dynamic settings) async {
    var remoteVersion = settings.getSetting(
      Platform.isIOS ? SystemSetting.iosVersion : SystemSetting.androidVersion,
    );
    final remote = remoteVersion;

    final forceUpdate = settings.getSetting(SystemSetting.forceUpdate);

    final packageInfo = await PackageInfo.fromPlatform();

    final current = packageInfo.version;

    final currentVersion = HelperUtils.comparableVersion(packageInfo.version);
    if (remoteVersion == null) {
      return;
    }
    remoteVersion = HelperUtils.comparableVersion(
      remoteVersion?.toString() ?? '',
    );

    if ((remoteVersion > currentVersion) as bool? ?? false) {
      Constant.isUpdateAvailable = true;
      Constant.newVersionNumber = settings
              .getSetting(
                Platform.isIOS
                    ? SystemSetting.iosVersion
                    : SystemSetting.androidVersion,
              )
              ?.toString() ??
          '';

      Future.delayed(
        Duration.zero,
        () {
          if (forceUpdate == '1') {
            ///This is force update
            UiUtils.showBlurredDialoge(
              context,
              dialog: BlurredDialogBox(
                onAccept: () async {
                  if (Platform.isAndroid) {
                    await launchUrl(
                      Uri.parse(
                        Constant.playstoreURLAndroid,
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    await launchUrl(
                      Uri.parse(
                        Constant.appstoreURLios,
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                backAllowedButton: false,
                svgImagePath: AppIcons.update,
                isAcceptContainesPush: true,
                svgImageColor: context.color.tertiaryColor,
                showCancleButton: false,
                title: 'updateAvailable'.translate(context),
                acceptTextColor: context.color.buttonColor,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText('$current>$remote'),
                    CustomText(
                      'newVersionAvailableForce'.translate(context),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          } else {
            UiUtils.showBlurredDialoge(
              context,
              dialog: BlurredDialogBox(
                onAccept: () async {
                  if (Platform.isAndroid) {
                    await launchUrl(
                      Uri.parse(
                        Constant.playstoreURLAndroid,
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    await launchUrl(
                      Uri.parse(
                        Constant.appstoreURLios,
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                svgImagePath: AppIcons.update,
                svgImageColor: context.color.tertiaryColor,
                showCancleButton: true,
                title: 'updateAvailable'.translate(context),
                content: CustomText(
                  'newVersionAvailable'.translate(context),
                ),
              ),
            );
          }
        },
      );
    }
  }

  void locationSetCheck() {
    if (isFirstTime) {
      isFirstTime = false;
    } else {
      return;
    }

    if (HiveUtils.isShowChooseLocationDialoge() &&
        !HiveUtils.isLocationFilled()) {
      Future.delayed(
        Duration.zero,
        () {
          UiUtils.showBlurredDialoge(
            context,
            dialog: BlurredDialogBox(
              title: UiUtils.translate(context, 'setLocation'),
              acceptButtonName: 'continue'.translate(context),
              acceptTextColor: context.color.buttonColor,
              content: StatefulBuilder(
                builder: (context, update) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        UiUtils.translate(
                          context,
                          'setLocationforBetter',
                        ),
                        maxLines: 3,
                        textAlign: TextAlign.center,
                      ),
                      Row(
                        children: [
                          Checkbox(
                            fillColor: WidgetStateProperty.resolveWith(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return context.color.tertiaryColor;
                                } else {
                                  return context.color.primaryColor;
                                }
                              },
                            ),
                            value: isChecked,
                            onChanged: (value) {
                              isChecked = value ?? false;
                              update(() {});
                            },
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          CustomText(
                            UiUtils.translate(context, 'dontshowagain'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              isAcceptContainesPush: true,
              onCancel: () {
                if (isChecked == true) {
                  HiveUtils.dontShowChooseLocationDialoge();
                }
              },
              onAccept: () async {
                if (isChecked == true) {
                  HiveUtils.dontShowChooseLocationDialoge();
                }
                Navigator.pop(context);

                await Navigator.pushNamed(
                  context,
                  Routes.chooseLocaitonMap,
                  arguments: {
                    'from': 'home_location',
                  },
                );
              },
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  late List<Widget> pages = [
    HomeScreen(from: widget.from),
    const ChatListScreen(),
    const CustomText(''),
    const PropertiesScreen(),
    const ProfileScreen(),
  ];

  bool isProfileCompleted = HiveUtils.getUserDetails().email != '' &&
      HiveUtils.getUserDetails().mobile != '' &&
      HiveUtils.getUserDetails().name != '' &&
      HiveUtils.getUserDetails().address != '' &&
      HiveUtils.getUserDetails().profile != '';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final length = navigationStack.length;
        if (length == 1 && navigationStack[0] == 0) {
          final now = DateTime.now();
          if (currentBackPressTime == null ||
              now.difference(currentBackPressTime!) >
                  const Duration(seconds: 2)) {
            currentBackPressTime = now;
            await Fluttertoast.showToast(
              msg: 'pressAgainToExit'.translate(context),
            );
            return Future.value(false);
          }
        } else {
          //This will put our page on previous page.
          final secondLast = navigationStack[length - 2];
          navigationStack.removeLast();
          pageController.jumpToPage(secondLast);
          setState(() {});
          return Future.value(false);
        }

        Future.delayed(Duration.zero, () {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        });
      },
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        bottomNavigationBar:
            Constant.maintenanceMode == '1' ? null : bottomBar(),
        body: Stack(
          children: <Widget>[
            PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: pageController,
              onPageChanged: onItemSwipe,
              children: pages,
            ),
            if (Constant.maintenanceMode == '1')
              Container(
                color: Theme.of(context).colorScheme.primaryColor,
              ),
            SizedBox.expand(
              child: Stack(
                children: [
                  if (!isReverse)
                    Container(
                      height: double.infinity,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          plusAnimationController.reverse();
                          showSellRentButton = false;
                          isReverse = true;
                          _forPropertyController.reverse();
                          _forProjectAnimationController.reverse();
                          setState(() {});
                        },
                      ),
                    ),
                  AnimatedBuilder(
                    animation: _forPropertyController,
                    builder: (context, c) {
                      return Positioned(
                        bottom: _propertyTween.value,
                        left: (context.screenWidth / 2) - 90.rw(context),
                        child: GestureDetector(
                          onTap: () async {
                            await GuestChecker.check(
                              onNotGuest: () async {
                                try {
                                  if (Constant.isDemoModeOn &&
                                      HiveUtils.getUserDetails().email ==
                                          Constant.demoEmail) {
                                    await HelperUtils.showSnackBarMessage(
                                      context,
                                      'thisActionNotValidDemo'
                                          .translate(context),
                                    );
                                  } else if (AppSettings
                                              .isVerificationRequired ==
                                          true &&
                                      isProfileCompleted != true) {
                                    await UiUtils.showBlurredDialoge(
                                      context,
                                      dialog: BlurredDialogBox(
                                        title: 'completeProfile'
                                            .translate(context),
                                        isAcceptContainesPush: true,
                                        onAccept: () async {
                                          await Navigator.popAndPushNamed(
                                            context,
                                            Routes.editProfile,
                                            arguments: {
                                              'from': 'home',
                                              'navigateToHome': true,
                                            },
                                          );
                                        },
                                        content: HiveUtils.getUserDetails()
                                                        .profile ==
                                                    '' &&
                                                (HiveUtils.getUserDetails()
                                                            .name !=
                                                        '' &&
                                                    HiveUtils.getUserDetails()
                                                            .email !=
                                                        '' &&
                                                    HiveUtils.getUserDetails()
                                                            .address !=
                                                        '')
                                            ? CustomText(
                                                'uploadProfilePicture'
                                                    .translate(context),
                                              )
                                            : CustomText(
                                                'completeProfileFirst'
                                                    .translate(context),
                                              ),
                                      ),
                                    );
                                  } else {
                                    unawaited(Widgets.showLoader(context));
                                    final checkPackage = CheckPackage();

                                    final packageAvailable = await checkPackage
                                        .checkPackageAvailable(
                                      packageType: PackageType.propertyList,
                                    );
                                    if (packageAvailable) {
                                      if (context
                                          .read<FetchCategoryCubit>()
                                          .state is! FetchCategorySuccess) {
                                        await context
                                            .read<FetchCategoryCubit>()
                                            .fetchCategories(
                                              loadWithoutDelay: true,
                                              forceRefresh: false,
                                            );
                                      }
                                      Widgets.hideLoder(context);
                                      await Navigator.pushNamed(
                                        context,
                                        Routes.selectPropertyTypeScreen,
                                        arguments: {
                                          'type': PropertyAddType.property,
                                        },
                                      );
                                    } else {
                                      Widgets.hideLoder(context);
                                      await UiUtils.showBlurredDialoge(
                                        context,
                                        dialog:
                                            const BlurredSubscriptionDialogBox(
                                          packageType: SubscriptionPackageType
                                              .propertyList,
                                          isAcceptContainesPush: true,
                                        ),
                                      );
                                    }
                                    Widgets.hideLoder(context);
                                  }
                                } on Exception catch (_) {
                                  Widgets.hideLoder(context);
                                  await HelperUtils.showSnackBarMessage(
                                    context,
                                    'somethingWentWrng'.translate(context),
                                  );
                                }
                              },
                            );
                          },
                          child: Container(
                            width: 180.rw(context),
                            height: 44.rh(context),
                            decoration: BoxDecoration(
                              color: context.color.tertiaryColor,
                              borderRadius:
                                  BorderRadius.circular(22.rw(context)),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: CustomImage(
                                    imageUrl: AppIcons.propertiesIcon,
                                    color: context.color.buttonColor,
                                    width: 20.rw(context),
                                    height: 20.rh(context),
                                  ),
                                ),
                                SizedBox(
                                  width: 7.rw(context),
                                ),
                                CustomText(
                                  'property'.translate(context),
                                  fontSize: context.font.xs,
                                  fontWeight: FontWeight.w500,
                                  color: context.color.buttonColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _forProjectAnimationController,
                    builder: (context, c) {
                      return Positioned(
                        bottom: _projectTween.value,
                        left: (context.screenWidth / 2) - 64.rw(context),
                        child: GestureDetector(
                          onTap: () async {
                            await GuestChecker.check(
                              onNotGuest: () async {
                                try {
                                  if (Constant.isDemoModeOn &&
                                      HiveUtils.getUserDetails().email ==
                                          Constant.demoEmail) {
                                    await HelperUtils.showSnackBarMessage(
                                      context,
                                      'thisActionNotValidDemo'
                                          .translate(context),
                                    );
                                  } else if (AppSettings
                                              .isVerificationRequired ==
                                          true &&
                                      isProfileCompleted != true) {
                                    await UiUtils.showBlurredDialoge(
                                      context,
                                      dialog: BlurredDialogBox(
                                        title: 'completeProfile'
                                            .translate(context),
                                        isAcceptContainesPush: true,
                                        onAccept: () async {
                                          await Navigator.popAndPushNamed(
                                            context,
                                            Routes.editProfile,
                                            arguments: {
                                              'from': 'home',
                                              'navigateToHome': true,
                                            },
                                          );
                                        },
                                        content: CustomText(
                                          'completeProfileFirst'
                                              .translate(context),
                                        ),
                                      ),
                                    );
                                  } else {
                                    unawaited(Widgets.showLoader(context));

                                    final checkPackage = CheckPackage();

                                    final packageAvailable = await checkPackage
                                        .checkPackageAvailable(
                                      packageType: PackageType.projectList,
                                    );
                                    if (packageAvailable) {
                                      if (context
                                          .read<FetchCategoryCubit>()
                                          .state is! FetchCategorySuccess) {
                                        await context
                                            .read<FetchCategoryCubit>()
                                            .fetchCategories(
                                              loadWithoutDelay: true,
                                              forceRefresh: false,
                                            );
                                      }
                                      Widgets.hideLoder(context);
                                      await GuestChecker.check(
                                        onNotGuest: () {
                                          Navigator.pushNamed(
                                            context,
                                            Routes.selectPropertyTypeScreen,
                                            arguments: {
                                              'type': PropertyAddType.project,
                                            },
                                          );
                                        },
                                      );
                                    } else {
                                      Widgets.hideLoder(context);
                                      await UiUtils.showBlurredDialoge(
                                        context,
                                        dialog:
                                            const BlurredSubscriptionDialogBox(
                                          packageType: SubscriptionPackageType
                                              .projectList,
                                          isAcceptContainesPush: true,
                                        ),
                                      );
                                    }
                                    Widgets.hideLoder(context);
                                  }
                                } on Exception catch (_) {
                                  Widgets.hideLoder(context);
                                  await HelperUtils.showSnackBarMessage(
                                    context,
                                    'somethingWentWrng'.translate(context),
                                  );
                                }
                              },
                            );
                          },
                          child: Container(
                            width: 128.rw(context),
                            height: 44.rh(context),
                            decoration: BoxDecoration(
                              color: context.color.tertiaryColor,
                              borderRadius:
                                  BorderRadius.circular(22.rw(context)),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(
                                  child: CustomImage(
                                    imageUrl: AppIcons.upcomingProject,
                                    color: context.color.buttonColor,
                                    width: 20.rw(context),
                                    height: 20.rh(context),
                                  ),
                                ),
                                SizedBox(
                                  width: 7.rw(context),
                                ),
                                CustomText(
                                  UiUtils.translate(context, 'project'),
                                  color: context.color.buttonColor,
                                  fontSize: context.font.xs,
                                  fontWeight: FontWeight.w500,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onItemTapped(int index) {
    addHistory(index);

    if (index == currtab) {
      var xIndex = index;

      if (xIndex == 3) {
        xIndex = 2;
      } else if (xIndex == 4) {
        xIndex = 3;
      }
      if (controllerList[xIndex].hasClients) {
        controllerList[xIndex].animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.bounceOut,
        );
      }
    }
    FocusManager.instance.primaryFocus?.unfocus();
    isReverse = true;
    plusAnimationController.reverse();
    _forProjectAnimationController.reverse();
    _forPropertyController.reverse();

    if (index != 1) {
      context.read<SearchPropertyCubit>().clearSearch();

      SearchScreenState.searchController.text = '';
    }
    searchbody = {};
    if (index == 1 || index == 3) {
      GuestChecker.check(
        onNotGuest: () {
          currtab = index;
          pageController.jumpToPage(currtab);
          setState(
            () {},
          );
        },
      );
    } else {
      currtab = index;
      pageController.jumpToPage(currtab);
      setState(() {});
    }
  }

  double degreesToQuarterTurns(double degrees) {
    return degrees / 90;
  }

  void onItemSwipe(int index) {
    addHistory(index);

    FocusManager.instance.primaryFocus?.unfocus();
    isReverse = true;
    plusAnimationController.reverse();
    _forProjectAnimationController.reverse();
    _forPropertyController.reverse();

    if (index != 1) {
      context.read<SearchPropertyCubit>().clearSearch();

      SearchScreenState.searchController.text = '';
    }
    searchbody = {};
    setState(() {
      currtab = index;
    });
    pageController.jumpToPage(currtab);
  }

  Widget bottomBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: context.color.textColorDark.withValues(alpha: 0.3),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      child: BottomAppBar(
        height: 78.rh(context),
        elevation: 2,
        shadowColor: context.color.textColorDark,
        color: context.color.secondaryColor,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            buildBottomNavigationbarItem(
              0,
              AppIcons.home,
              AppIcons.homeActive,
              UiUtils.translate(context, 'homeTab'),
            ),
            buildBottomNavigationbarItem(
              1,
              AppIcons.chat,
              AppIcons.chatActive,
              UiUtils.translate(context, 'chat'),
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (isReverse) {
                  plusAnimationController.forward();
                  isReverse = false;
                  showSellRentButton = true;
                  _forPropertyController.forward();
                  _forProjectAnimationController.forward();
                } else {
                  plusAnimationController.reverse();
                  showSellRentButton = false;
                  isReverse = true;
                  _forPropertyController.reverse();
                  _forProjectAnimationController.reverse();
                }
                setState(() {});
              },
              child: Transform(
                transform: Matrix4.identity()
                  ..translate(0.toDouble(), -25.rh(context)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (context.color.brightness == Brightness.light)
                      Container(
                        height: 48.rh(context),
                        width: 46.rw(context),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99999),
                          boxShadow: [
                            BoxShadow(
                              color: context.color.textColorDark
                                  .withValues(alpha: 0.5),
                              offset: const Offset(0, -1.5),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    AnimatedScale(
                      scale: isReverse ? 1 : 1.15,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedRotation(
                        turns: isReverse ? 0 : 1 / 3,
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          alignment: Alignment.center,
                          child: CustomImage(
                            imageUrl: AppIcons.addButtonShape,
                            color: context.color.tertiaryColor,
                            height: 56.rh(context),
                            width: 56.rw(context),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 56.rh(context),
                      width: 56.rw(context),
                      alignment: Alignment.center,
                      child: AnimatedBuilder(
                        animation: plusAnimationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: plusAnimationController.value *
                                (135 * (pi / 180)), // Rotate 135 degrees
                            child: child,
                          );
                        },
                        child: CustomImage(
                          imageUrl: AppIcons.plusButtonIcon,
                          color: context.color.buttonColor,
                          height: 20.rh(context),
                          width: 20.rw(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            buildBottomNavigationbarItem(
              3,
              AppIcons.properties,
              AppIcons.propertiesActive,
              UiUtils.translate(context, 'properties'),
            ),
            buildBottomNavigationbarItem(
              4,
              AppIcons.profileOutlined,
              AppIcons.profileActive,
              UiUtils.translate(context, 'profileTab'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomNavigationbarItem(
    int index,
    String svgImage,
    String selectedSvgImage,
    String title,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedScale(
              scale: currtab == index ? 1.3 : 1,
              duration: const Duration(milliseconds: 200),
              child: Container(
                alignment: Alignment.center,
                child: CustomImage(
                  imageUrl: currtab == index ? selectedSvgImage : svgImage,
                  height: 24.rh(context),
                  width: 24.rw(context),
                  color: currtab == index
                      ? context.color.tertiaryColor
                      : context.color.textColorDark.withValues(alpha: .5),
                ),
              ),
            ),
            SizedBox(height: 4.rh(context)),
            CustomText(
              title,
              maxLines: 1,
              textAlign: TextAlign.center,
              fontSize: context.font.xs,
              color: currtab == index
                  ? context.color.tertiaryColor
                  : context.color.textColorDark.withValues(alpha: .5),
            ),
          ],
        ),
      ),
    );
  }
}
