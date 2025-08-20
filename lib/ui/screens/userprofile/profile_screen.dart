import 'dart:developer';

import 'package:perfectshelter/data/cubits/auth/get_user_data_cubit.dart';
import 'package:perfectshelter/data/model/system_settings_model.dart';
import 'package:perfectshelter/data/repositories/auth_repository.dart';
import 'package:perfectshelter/data/repositories/system_repository.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin<ProfileScreen> {
  String verificationStatus = '';
  bool isGuest = false;
  @override
  void initState() {
    final settings = context.read<FetchSystemSettingsCubit>();

    isGuest = GuestChecker.value;
    GuestChecker.listen().addListener(() {
      isGuest = GuestChecker.value;
      if (mounted) setState(() {});
    });
    if (!const bool.fromEnvironment(
      'force-disable-demo-mode',
    )) {
      Constant.isDemoModeOn =
          settings.getSetting(SystemSetting.demoMode) as bool? ?? false;
    }

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  bool get wantKeepAlive => true;
  int? a;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = context.watch<FetchSystemSettingsCubit>();
    verificationStatus =
        settings.getSetting(SystemSetting.verificationStatus)?.toString() ?? '';
    if (!const bool.fromEnvironment(
      'force-disable-demo-mode',
    )) {
      Constant.isDemoModeOn =
          settings.getSetting(SystemSetting.demoMode) as bool? ?? false;
    }
    var username = 'anonymous'.translate(context);
    var email = 'notLoggedIn'.translate(context);
    if (!isGuest) {
      final user = context.watch<UserDetailsCubit>().state.user;
      username = user?.name!.firstUpperCase() ?? 'anonymous'.translate(context);
      email = user?.email ?? 'notLoggedIn'.translate(context);
    }
    final systemSettingsState = context.read<FetchSystemSettingsCubit>().state;

    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context),
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: CustomAppBar(
          title: CustomText(UiUtils.translate(context, 'myProfile')),
          showBackButton: false,
        ),
        body: BlocListener<DeleteAccountCubit, DeleteAccountState>(
          listener: (context, state) {
            if (state is DeleteAccountProgress) {
              unawaited(Widgets.showLoader(context));
            }
            if (state is DeleteAccountFailure) {
              Widgets.hideLoder(context);
            }
            if (state is AccountDeleted) {
              Widgets.hideLoder(context);
              context.read<UserDetailsCubit>().clear();
              Navigator.pushReplacementNamed(
                context,
                Routes.login,
                arguments: {'popToCurrent': false},
              );
            }
          },
          child: CustomRefreshIndicator(
            onRefresh: () async {
              await context.read<FetchSystemSettingsCubit>().fetchSettings(
                    isAnonymous: GuestChecker.value,
                  );
              await context.read<GetApiKeysCubit>().fetch();
            },
            child: systemSettingsState is FetchSystemSettingsInProgress
                ? buildProfileLoadingShimmer()
                : SingleChildScrollView(
                    physics: Constant.scrollPhysics,
                    controller: profileScreenController,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: <Widget>[
                          // Profile Image and Name
                          Container(
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: context.color.borderColor),
                              color: context.color.secondaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: profileImgWidget(),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      CustomText(
                                        username,
                                        color: context.color.inverseSurface,
                                        fontSize: context.font.md,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      CustomText(
                                        email,
                                        color: context.color.textColorDark,
                                        fontSize: context.font.xs,
                                        maxLines: 1,
                                      ),
                                      if (isGuest == false) ...[
                                        const SizedBox(height: 8),
                                        _buildVerificationUI(
                                          context,
                                          verificationStatus,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isGuest == true)
                                  Container(
                                    margin: EdgeInsetsDirectional.only(
                                      end: 16.rw(context),
                                    ),
                                    child: UiUtils.buildButton(
                                      context,
                                      height: 32.rh(context),
                                      fontSize: context.font.xs,
                                      showElevation: false,
                                      buttonTitle: 'login'.translate(context),
                                      buttonColor: context.color.secondaryColor,
                                      textColor: context.color.textLightColor,
                                      autoWidth: true,
                                      border: BorderSide(
                                        color: context.color.borderColor,
                                      ),
                                      onPressed: () {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          Routes.login,
                                          arguments: {'popToCurrent': false},
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          // Profile Settings
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: context.color.borderColor,
                              ),
                              color: context.color.secondaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isGuest == false)
                                  customTile(
                                    context,
                                    title: UiUtils.translate(
                                      context,
                                      'editProfile',
                                    ),
                                    svgImagePath: AppIcons.profile,
                                    onTap: () {
                                      context
                                          .read<GetUserDataCubit>()
                                          .getUserData();
                                      HelperUtils.goToNextPage(
                                        Routes.editProfile,
                                        context,
                                        false,
                                        args: {'from': 'profile'},
                                      );
                                    },
                                  ),
                                if (isGuest == false) dividerWithSpacing(),
                                customTile(
                                  context,
                                  title:
                                      UiUtils.translate(context, 'myProjects'),
                                  svgImagePath: AppIcons.myProjects,
                                  onTap: () async {
                                    await GuestChecker.check(
                                      onNotGuest: () async {
                                        await Navigator.pushNamed(
                                          context,
                                          Routes.myProjects,
                                        );
                                      },
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(context, 'myAds'),
                                  svgImagePath: AppIcons.promoted,
                                  onTap: () async {
                                    await GuestChecker.check(
                                      onNotGuest: () async {
                                        await Navigator.pushNamed(
                                          context,
                                          Routes.myAdvertisment,
                                        );
                                      },
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(
                                    context,
                                    'subscription',
                                  ),
                                  svgImagePath: AppIcons.subscription,
                                  onTap: () {
                                    GuestChecker.check(
                                      onNotGuest: () async {
                                        try {
                                          await context
                                              .read<GetApiKeysCubit>()
                                              .fetch();
                                          if (context
                                              .read<GetApiKeysCubit>()
                                              .state is GetApiKeysSuccess) {
                                            await Navigator.pushNamed(
                                              context,
                                              Routes
                                                  .subscriptionPackageListRoute,
                                              arguments: {
                                                'isBankTransferEnabled': (context
                                                                .read<
                                                                    GetApiKeysCubit>()
                                                                .state
                                                            as GetApiKeysSuccess)
                                                        .bankTransferStatus ==
                                                    '1',
                                              },
                                            );
                                          } else if (context
                                              .read<GetApiKeysCubit>()
                                              .state is GetApiKeysFail) {
                                            final errorMessage = (context
                                                    .read<GetApiKeysCubit>()
                                                    .state as GetApiKeysFail)
                                                .error
                                                .toString();
                                            await HelperUtils
                                                .showSnackBarMessage(
                                              context,
                                              errorMessage,
                                            );
                                          }
                                        } on Exception catch (e) {
                                          await HelperUtils.showSnackBarMessage(
                                            context,
                                            e.toString(),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(
                                    context,
                                    'transactionHistory',
                                  ),
                                  svgImagePath: AppIcons.transaction,
                                  onTap: () {
                                    GuestChecker.check(
                                      onNotGuest: () {
                                        Navigator.pushNamed(
                                          context,
                                          Routes.transactionHistory,
                                        );
                                      },
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(
                                    context,
                                    'personalized',
                                  ),
                                  svgImagePath: AppIcons.magic,
                                  onTap: () {
                                    GuestChecker.check(
                                      onNotGuest: () {
                                        Navigator.pushNamed(
                                          context,
                                          Routes.personalizedPropertyScreen,
                                          arguments: {
                                            'type':
                                                PersonalizedVisitType.normal,
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(
                                    context,
                                    'faqScreen',
                                  ),
                                  svgImagePath: AppIcons.faqs,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.faqsScreen,
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(context, 'language'),
                                  svgImagePath: AppIcons.language,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.languageListScreenRoute,
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(
                                    context,
                                    'darkTheme',
                                  ),
                                  svgImagePath: AppIcons.darkTheme,
                                  isSwitchBox: true,
                                  onTap: () {},
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(
                                    context,
                                    'notifications',
                                  ),
                                  svgImagePath: AppIcons.notification,
                                  onTap: () {
                                    GuestChecker.check(
                                      onNotGuest: () {
                                        Navigator.pushNamed(
                                          context,
                                          Routes.notificationPage,
                                        );
                                      },
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(context, 'articles'),
                                  svgImagePath: AppIcons.articles,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.articlesScreenRoute,
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title:
                                      UiUtils.translate(context, 'favorites'),
                                  svgImagePath: AppIcons.heartFilled,
                                  onTap: () {
                                    GuestChecker.check(
                                      onNotGuest: () {
                                        Navigator.pushNamed(
                                          context,
                                          Routes.favoritesScreen,
                                        );
                                      },
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(
                                    context,
                                    'areaConvertor',
                                  ),
                                  svgImagePath: AppIcons.areaConvertor,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.areaConvertorScreen,
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(context, 'shareApp'),
                                  svgImagePath: AppIcons.shareApp,
                                  onTap: shareApp,
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(context, 'rateUs'),
                                  svgImagePath: AppIcons.rateUs,
                                  onTap: rateUs,
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title:
                                      UiUtils.translate(context, 'contactUs'),
                                  svgImagePath: AppIcons.contactUs,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.contactUs,
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(context, 'aboutUs'),
                                  svgImagePath: AppIcons.aboutUs,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.profileSettings,
                                      arguments: {
                                        'title': UiUtils.translate(
                                          context,
                                          'aboutUs',
                                        ),
                                        'param': Api.aboutApp,
                                      },
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(
                                    context,
                                    'termsConditions',
                                  ),
                                  svgImagePath: AppIcons.terms,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.profileSettings,
                                      arguments: {
                                        'title': UiUtils.translate(
                                          context,
                                          'termsConditions',
                                        ),
                                        'param': Api.termsAndConditions,
                                      },
                                    );
                                  },
                                ),
                                dividerWithSpacing(),
                                customTile(
                                  context,
                                  title: UiUtils.translate(
                                    context,
                                    'privacyPolicy',
                                  ),
                                  svgImagePath: AppIcons.privacy,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.profileSettings,
                                      arguments: {
                                        'title': UiUtils.translate(
                                          context,
                                          'privacyPolicy',
                                        ),
                                        'param': Api.privacyPolicy,
                                      },
                                    );
                                  },
                                ),
                                if (Constant.isUpdateAvailable == true) ...[
                                  dividerWithSpacing(),
                                  updateTile(
                                    context,
                                    isUpdateAvailable:
                                        Constant.isUpdateAvailable,
                                    title: UiUtils.translate(context, 'update'),
                                    newVersion: Constant.newVersionNumber,
                                    svgImagePath: AppIcons.update,
                                    onTap: () async {
                                      if (Platform.isIOS) {
                                        await launchUrl(
                                          Uri.parse(Constant.appstoreURLios),
                                        );
                                      } else if (Platform.isAndroid) {
                                        await launchUrl(
                                          Uri.parse(
                                            Constant.playstoreURLAndroid,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                                if (isGuest == false) ...[
                                  dividerWithSpacing(),
                                  customTile(
                                    context,
                                    title: UiUtils.translate(
                                      context,
                                      'deleteAccount',
                                    ),
                                    svgImagePath: AppIcons.delete,
                                    onTap: () {
                                      if (Constant.isDemoModeOn &&
                                          context
                                                  .read<UserDetailsCubit>()
                                                  .state
                                                  .user
                                                  ?.authId ==
                                              Constant.demoFirebaseID) {
                                        HelperUtils.showSnackBarMessage(
                                          context,
                                          UiUtils.translate(
                                            context,
                                            'thisActionNotValidDemo',
                                          ),
                                        );
                                        return;
                                      }

                                      deleteConfirmWidget(
                                        UiUtils.translate(
                                          context,
                                          'deleteProfileMessageTitle',
                                        ),
                                        UiUtils.translate(
                                          context,
                                          'deleteProfileMessageContent',
                                        ),
                                        true,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          if (isGuest == false) ...[
                            UiUtils.buildButton(
                              context,
                              onPressed: logOutConfirmWidget,
                              height: 52.rh(context),
                              prefixWidget: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(end: 16),
                                child: FittedBox(
                                  fit: BoxFit.none,
                                  child: CustomImage(
                                    imageUrl: AppIcons.logout,
                                    width: 24.rw(context),
                                    height: 24.rh(context),
                                    color: context.color.buttonColor,
                                  ),
                                ),
                              ),
                              buttonTitle: UiUtils.translate(context, 'logout'),
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget buildProfileLoadingShimmer() {
    return SingleChildScrollView(
      physics: Constant.scrollPhysics,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomShimmer(height: MediaQuery.of(context).size.height * 0.13),
            const SizedBox(
              height: 16,
            ),
            CustomShimmer(
              height: MediaQuery.of(context).size.height,
            ),
            const SizedBox(
              height: 16,
            ),
            CustomShimmer(height: MediaQuery.of(context).size.height * 0.07),
          ],
        ),
      ),
    );
  }

  Padding dividerWithSpacing() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        color: context.color.borderColor,
      ),
    );
  }

  Widget updateTile(
    BuildContext context, {
    required String title,
    required String newVersion,
    required bool isUpdateAvailable,
    required String svgImagePath,
    required VoidCallback onTap,
    dynamic Function(dynamic value)? onTapSwitch,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: GestureDetector(
        onTap: () {
          if (isUpdateAvailable) {
            onTap.call();
          }
        },
        child: Row(
          children: [
            Container(
              width: 40.rw(context),
              height: 40.rh(context),
              decoration: BoxDecoration(
                color: context.color.tertiaryColor
                    .withValues(alpha: 0.10000000149011612),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FittedBox(
                fit: BoxFit.none,
                child: isUpdateAvailable == false
                    ? const Icon(Icons.done)
                    : CustomImage(
                        imageUrl: svgImagePath,
                        color: context.color.tertiaryColor,
                      ),
              ),
            ),
            SizedBox(
              width: 25.rw(context),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  isUpdateAvailable == false
                      ? 'uptoDate'.translate(context)
                      : title,
                  fontWeight: FontWeight.w700,
                  color: context.color.textColorDark,
                ),
                if (isUpdateAvailable)
                  CustomText(
                    'v$newVersion',
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                    color: context.color.textColorDark,
                    fontSize: context.font.xs,
                  ),
              ],
            ),
            if (isUpdateAvailable) ...[
              const Spacer(),
              Container(
                width: 32.rw(context),
                height: 32.rh(context),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: context.color.borderColor, width: 1.5),
                  color: context.color.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FittedBox(
                  fit: BoxFit.none,
                  child: CustomImage(
                    imageUrl: AppIcons.arrowRight,
                    matchTextDirection: true,
                    color: context.color.textColorDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget customTile(
    BuildContext context, {
    required String title,
    required String svgImagePath,
    required VoidCallback onTap,
    bool? isSwitchBox,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        absorbing: !(isSwitchBox ?? false),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.color.textColorDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FittedBox(
                fit: BoxFit.none,
                child: CustomImage(
                  imageUrl: svgImagePath,
                  height: 24.rh(context),
                  width: 24.rw(context),
                  color: context.color.textColorDark,
                ),
              ),
            ),
            SizedBox(
              width: 8.rw(context),
            ),
            Expanded(
              flex: 3,
              child: CustomText(
                title,
                fontSize: context.font.md,
                fontWeight: FontWeight.w700,
                color: context.color.textColorDark,
              ),
            ),
            const Spacer(),
            if (isSwitchBox != true)
              Container(
                width: 24.rw(context),
                height: 24.rh(context),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.color.borderColor,
                  ),
                  color: context.color.secondaryColor
                      .withValues(alpha: 0.10000000149011612),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FittedBox(
                  fit: BoxFit.none,
                  child: SizedBox(
                    child: CustomImage(
                      imageUrl: AppIcons.arrowRight,
                      matchTextDirection: true,
                      color: context.color.textColorDark,
                    ),
                  ),
                ),
              ),
            if (isSwitchBox ?? false) ...[
              const Spacer(),
              BlocBuilder<AppThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDark = context.read<AppThemeCubit>().isDarkMode;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Switch(
                      thumbColor: const WidgetStatePropertyAll(Colors.white),
                      trackOutlineColor:
                          const WidgetStatePropertyAll(Colors.transparent),
                      thumbIcon: const WidgetStatePropertyAll(
                        Icon(Icons.circle, color: Colors.white),
                      ),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
                      activeTrackColor: context.color.tertiaryColor,
                      value: isDark,
                      onChanged: (val) {
                        // Toggle between light and dark, keeping system theme as a separate option
                        final newTheme =
                            isDark ? ThemeMode.light : ThemeMode.dark;
                        context.read<AppThemeCubit>().changeTheme(newTheme);
                      },
                    ),
                  );
                },
              )
            ],
          ],
        ),
      ),
    );
  }

  void deleteConfirmWidget(String title, String desc, dynamic callDel) {
    UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: title,
        content: CustomText(
          desc,
          textAlign: TextAlign.center,
        ),
        acceptButtonName: 'deleteBtnLbl'.translate(context),
        acceptTextColor: context.color.buttonColor,
        cancelTextColor: context.color.textColorDark,
        svgImagePath: AppIcons.deleteIllustration,
        isAcceptContainesPush: true,
        onAccept: () async {
          final L = HiveUtils.getUserLoginType();
          Navigator.of(context).pop();
          if (callDel as bool? ?? false) {
            Future.delayed(
              const Duration(microseconds: 100),
              () async {
                unawaited(Widgets.showLoader(context));
                try {
                  // throw FirebaseAuthException(code: "requires-recent-login");
                  if (L == LoginType.phone &&
                      AppSettings.otpServiceProvider == 'firebase') {
                    await FirebaseAuth.instance.currentUser?.delete();
                  }
                  if (L == LoginType.apple || L == LoginType.google) {
                    await FirebaseAuth.instance.currentUser?.delete();
                  }

                  await context.read<DeleteAccountCubit>().deleteAccount(
                        context,
                      );
                  if (L == LoginType.email) {
                    Constant.interestedPropertyIds.clear();
                    context
                        .read<LikedPropertiesCubit>()
                        .state
                        .likedProperties
                        .clear();
                    context.read<LikedPropertiesCubit>().clear();
                    await context.read<LoadChatMessagesCubit>().close();
                  }
                  Widgets.hideLoder(context);
                  context.read<UserDetailsCubit>().clear();
                  await Navigator.pushReplacementNamed(
                    context,
                    Routes.login,
                    arguments: {'popToCurrent': true},
                  );
                } on Exception catch (e) {
                  Widgets.hideLoder(context);
                  if (e is FirebaseAuthException) {
                    if (e.code == 'requires-recent-login') {
                      await UiUtils.showBlurredDialoge(
                        context,
                        dialog: BlurredDialogBox(
                          title: 'Recent login required'.translate(context),
                          acceptTextColor: context.color.buttonColor,
                          showCancleButton: false,
                          content: CustomText(
                            'logoutAndLoginAgain'.translate(context),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                  } else {
                    await UiUtils.showBlurredDialoge(
                      context,
                      dialog: BlurredDialogBox(
                        title: 'somethingWentWrng'.translate(context),
                        acceptTextColor: context.color.buttonColor,
                        showCancleButton: false,
                        content: CustomText(e.toString()),
                      ),
                    );
                  }
                }
              },
            );
          } else {
            await HiveUtils.logoutUser(
              context,
              onLogout: () {},
            );
          }
        },
      ),
    );
  }

  Widget profileImgWidget() {
    return GestureDetector(
      onTap: () {
        UiUtils.showFullScreenImage(
          context,
          provider: NetworkImage(
            context.read<UserDetailsCubit>().state.user?.profile ?? '',
          ),
        );
      },
      child: (context.watch<UserDetailsCubit>().state.user?.profile ?? '')
              .trim()
              .isEmpty
          ? buildDefaultPersonSVG(context)
          : CustomImage(
              imageUrl:
                  context.watch<UserDetailsCubit>().state.user?.profile ?? '',
              width: 80.rw(context),
              height: 80.rh(context),
            ),
    );
  }

  Widget buildDefaultPersonSVG(BuildContext context) {
    return Container(
      width: 80.rw(context),
      height: 80.rh(context),
      color: context.color.tertiaryColor.withValues(alpha: 0.1),
      child: FittedBox(
        fit: BoxFit.none,
        child: CustomImage(
          imageUrl: AppIcons.defaultPersonLogo,
          color: context.color.tertiaryColor,
          width: 32.rw(context),
          height: 32.rh(context),
        ),
      ),
    );
  }

  void shareApp() {
    try {
      if (Platform.isAndroid) {
        SharePlus.instance.share(
          ShareParams(
            text:
                '${Constant.appName}\n${Constant.playstoreURLAndroid}\n${'shareApp'.translate(context)}',
            subject: Constant.appName,
          ),
        );
      } else if (Platform.isIOS) {
        SharePlus.instance.share(
          ShareParams(
            text:
                '${Constant.appName}\n${Constant.appstoreURLios}\n${'shareApp'.translate(context)}',
            subject: Constant.appName,
          ),
        );
      }
    } on Exception catch (e) {
      HelperUtils.showSnackBarMessage(context, e.toString());
    }
  }

  Future<void> rateUs() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.openStoreListing();
    }
  }

  void logOutConfirmWidget() {
    UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: UiUtils.translate(context, 'confirmLogoutTitle'),
        onAccept: () async {
          try {
            final L = HiveUtils.getUserLoginType();
            if (L == LoginType.email) {
              Future.delayed(
                Duration.zero,
                () {
                  Constant.interestedPropertyIds.clear();
                  context.read<UserDetailsCubit>().clear();
                  context.read<LikedPropertiesCubit>().clear();
                  context.read<LoadChatMessagesCubit>().close();
                  HiveUtils.logoutUser(context, onLogout: () {});
                },
              );
            }
            if (L == LoginType.phone &&
                AppSettings.otpServiceProvider == 'twilio') {
              Future.delayed(
                Duration.zero,
                () {
                  Constant.interestedPropertyIds.clear();
                  context.read<UserDetailsCubit>().clear();
                  context.read<LikedPropertiesCubit>().clear();
                  context.read<LoadChatMessagesCubit>().close();
                  HiveUtils.logoutUser(context, onLogout: () {});
                },
              );
            }
            if (L == LoginType.phone &&
                AppSettings.otpServiceProvider == 'firebase') {
              Future.delayed(
                Duration.zero,
                () {
                  Constant.interestedPropertyIds.clear();
                  context.read<UserDetailsCubit>().clear();
                  context.read<LikedPropertiesCubit>().clear();
                  context.read<LoadChatMessagesCubit>().close();
                  HiveUtils.logoutUser(context, onLogout: () {});
                },
              );
            }
            if (L == LoginType.google || L == LoginType.apple) {
              Future.delayed(
                Duration.zero,
                () {
                  Constant.interestedPropertyIds.clear();
                  context.read<UserDetailsCubit>().clear();
                  context.read<LikedPropertiesCubit>().clear();
                  context.read<LoadChatMessagesCubit>().close();
                  HiveUtils.logoutUser(context, onLogout: () {});
                },
              );
              await GoogleSignIn().signOut();
            }
          } on Exception catch (e) {
            log('Issue while logout is $e');
          }
        },
        cancelTextColor: context.color.textColorDark,
        svgImagePath: AppIcons.logoutIllustration,
        acceptTextColor: context.color.buttonColor,
        content: CustomText(
          UiUtils.translate(context, 'confirmLogOutMsg'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildVerificationUI(BuildContext context, String status) {
    const verifyButtonPadding = EdgeInsetsDirectional.only(
      start: 4,
      end: 8,
      top: 2,
      bottom: 2,
    );

    // Cache context-dependent values
    final colorScheme = context.color;

    switch (status) {
      case 'initial':
        return _buildVerificationButton(
          onTap: () => _handleVerificationTap(context, 'initial'),
          padding: verifyButtonPadding,
          backgroundColor: colorScheme.tertiaryColor,
          child: _buildVerificationContent(
            icon: _buildAgentBadgeIcon(colorScheme.buttonColor),
            text: 'verifyNow'.translate(context),
            textColor: colorScheme.buttonColor,
          ),
        );

      case 'pending':
        return _buildVerificationContainer(
          padding: verifyButtonPadding,
          backgroundColor: Colors.orangeAccent.withValues(alpha: 0.1),
          child: _buildVerificationContent(
            icon: Icon(
              Icons.access_time_filled_rounded,
              color: Colors.orangeAccent,
              size: 16.rh(context),
            ),
            text: 'verificationPending'.translate(context),
            textColor: Colors.orangeAccent,
            spacing: 2,
            leadingSpacing: 4,
          ),
        );

      case 'success':
        return _buildVerificationContainer(
          padding: verifyButtonPadding,
          backgroundColor: colorScheme.tertiaryColor.withValues(alpha: 0.1),
          child: _buildVerificationContent(
            icon: _buildAgentBadgeIcon(colorScheme.tertiaryColor),
            text: 'verified'.translate(context),
            textColor: colorScheme.tertiaryColor,
            spacing: 2,
          ),
        );

      case 'failed':
        return _buildVerificationButton(
          onTap: () => _handleVerificationTap(context, 'failed'),
          padding: verifyButtonPadding,
          backgroundColor: colorScheme.error.withValues(alpha: 0.1),
          child: _buildVerificationContent(
            icon: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Icon(
                Icons.cancel_rounded,
                color: colorScheme.error,
                size: 16.rh(context),
              ),
            ),
            text: 'formRejected'.translate(context),
            textColor: colorScheme.error,
            spacing: 2,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

// Helper method for tappable verification buttons
  Widget _buildVerificationButton({
    required VoidCallback onTap,
    required EdgeInsetsDirectional padding,
    required Color backgroundColor,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildVerificationContainer(
        padding: padding,
        backgroundColor: backgroundColor,
        child: child,
      ),
    );
  }

// Helper method for verification container styling
  Widget _buildVerificationContainer({
    required EdgeInsetsDirectional padding,
    required Color backgroundColor,
    required Widget child,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }

// Helper method for verification content layout
  Widget _buildVerificationContent({
    required Widget icon,
    required String text,
    required Color textColor,
    double spacing = 0,
    double leadingSpacing = 0,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingSpacing > 0) SizedBox(width: leadingSpacing),
        icon,
        if (spacing > 0) SizedBox(width: spacing),
        CustomText(
          text,
          fontWeight: FontWeight.bold,
          fontSize: context.font.xs,
          color: textColor,
        ),
      ],
    );
  }

// Helper method for agent badge icon
  Widget _buildAgentBadgeIcon(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: FittedBox(
        fit: BoxFit.none,
        child: CustomImage(
          imageUrl: AppIcons.agentBadge,
          height: 16.rh(context),
          width: 16.rw(context),
          color: color,
        ),
      ),
    );
  }

// Extracted and optimized verification tap handler
  Future<void> _handleVerificationTap(
    BuildContext context,
    String expectedStatus,
  ) async {
    try {
      final systemRepository = SystemRepository();
      final fetchSystemSettings = await systemRepository.fetchSystemSettings(
        isAnonymouse: false,
      );

      final currentStatus = fetchSystemSettings['data']['verification_status'];

      if (currentStatus == expectedStatus) {
        HelperUtils.goToNextPage(
          Routes.agentVerificationForm,
          context,
          false,
        );
      } else {
        await HelperUtils.showSnackBarMessage(
          context,
          'formAlreadySubmitted'.translate(context),
        );
      }
    } on Exception catch (_) {
      // Handle potential errors gracefully
      await HelperUtils.showSnackBarMessage(
        context,
        'errorOccurred'.translate(context),
      );
    }
  }
}
