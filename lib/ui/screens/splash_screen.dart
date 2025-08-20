import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:perfectshelter/data/model/system_settings_model.dart';
import 'package:perfectshelter/data/repositories/system_repository.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/utils/hive_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AuthenticationState authenticationState;

  bool isSettingsLoaded = false;
  bool isLanguageLoaded = false;

  @override
  void initState() {
    locationPermission();
    checkIsUserAuthenticated();
    super.initState();
    getDefaultLanguage(() {
      isLanguageLoaded = true;
    });
    MobileAds.instance.initialize();

    Connectivity().checkConnectivity().then((value) {
      if (value.contains(ConnectivityResult.none)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<dynamic>(
            builder: (context) {
              return NoInternet(
                onRetry: () async {
                  try {
                    await LoadAppSettings().load(initBox: true);

                    // Check internet connectivity before redirecting
                    final connectivityResult =
                        await Connectivity().checkConnectivity();
                    if (!connectivityResult.contains(ConnectivityResult.none)) {
                      // Only redirect to splash screen if internet is available
                      Future.delayed(Duration.zero, () {
                        Navigator.pushReplacementNamed(context, Routes.splash);
                      });
                    } else {
                      await HelperUtils.showSnackBarMessage(
                        context,
                        isFloating: true,
                        'noInternetErrorMsg'.translate(context),
                      );
                    }
                  } on Exception catch (_) {
                    log('no internet');
                  }
                },
              );
            },
          ),
        );
      }
    });
    //get Currency Symbol from Admin Panel
    Future.delayed(Duration.zero, () {
      context
          .read<ProfileSettingCubit>()
          .fetchProfileSetting(Api.currencySymbol);
    });
  }

  Future<void> locationPermission() async {
    if ((await Permission.location.status) == PermissionStatus.denied) {
      await Permission.location.request();
    }
  }

  Future<void> checkIsUserAuthenticated() async {
    authenticationState = context.read<AuthenticationCubit>().state;
    if (authenticationState == AuthenticationState.authenticated) {
      ///Only load sensitive details if user is authenticated
      ///This call will load sensitive details with settings
      await context.read<FetchSystemSettingsCubit>().fetchSettings(
            isAnonymous: false,
          );
    } else {
      //This call will hide sensitive details.
      await context.read<FetchSystemSettingsCubit>().fetchSettings(
            isAnonymous: true,
          );
    }
  }

  void navigateCheck() {
    ({'setting': isSettingsLoaded, 'language': isLanguageLoaded}).logg;

    if (isSettingsLoaded) {
      navigateToScreen();
    }
  }

  void navigateToScreen() {
    if (context.read<FetchSystemSettingsCubit>().getSetting(
              SystemSetting.maintenanceMode,
            ) ==
        '1') {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushReplacementNamed(Routes.maintenanceMode);
      });
    } else if (authenticationState == AuthenticationState.authenticated) {
      Future.delayed(Duration.zero, () {
        Navigator.of(
          context,
        ).pushReplacementNamed(Routes.main, arguments: {'from': 'main'});
      });
    } else if (authenticationState == AuthenticationState.unAuthenticated) {
      if (Hive.box<dynamic>(HiveKeys.userDetailsBox).get('isGuest') == true) {
        Future.delayed(Duration.zero, () {
          Navigator.of(
            context,
          ).pushReplacementNamed(Routes.main, arguments: {'from': 'splash'});
        });
      } else {
        Future.delayed(Duration.zero, () {
          Navigator.of(context).pushReplacementNamed(Routes.login);
        });
      }
    } else if (authenticationState == AuthenticationState.firstTime) {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushReplacementNamed(Routes.onboarding);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    navigateCheck();

    return BlocListener<FetchLanguageCubit, FetchLanguageState>(
      listener: (context, state) {},
      child: BlocListener<FetchSystemSettingsCubit, FetchSystemSettingsState>(
        listener: (context, state) {
          if (state is FetchSystemSettingsFailure) {
            log(
              'FetchSystemSettings Issue while load system settings ${state.errorMessage}',
            );
          }
          if (state is FetchSystemSettingsSuccess) {
            if (kDebugMode) {
              print('FetchSystemSettingsSuccess');
            }
            final setting = <dynamic>[];
            if (setting.isNotEmpty) {
              if ((setting[0] as Map).containsKey('package_id')) {
                Constant.subscriptionPackageId = '';
              }
            }

            if ((state.settings['data'].containsKey('demo_mode') as bool?) ??
                false) {
              Constant.isDemoModeOn =
                  state.settings['data']['demo_mode'] as bool? ?? false;
            }
            isSettingsLoaded = true;
            setState(() {});
          }
        },
        child: AnnotatedRegion(
          value: SystemUiOverlayStyle(
            statusBarColor: context.color.tertiaryColor,
            systemNavigationBarColor: context.color.tertiaryColor,
          ),
          child: Scaffold(
            backgroundColor: context.color.tertiaryColor,
            extendBody: true,
            body: Stack(
              children: [
                Center(
                  child: Container(
                    alignment: Alignment.center,
                    child: CustomImage(
                      imageUrl: AppIcons.splashLogo,
                      height: 151.rs(context),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    key: const ValueKey('companylogo'),
                    child: CustomImage(
                      imageUrl: AppIcons.companyLogo,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<dynamic> getDefaultLanguage(VoidCallback onSuccess) async {
  try {
    // await Hive.initFlutter();v
    await Hive.openBox<dynamic>(HiveKeys.languageBox);
    await Hive.openBox<dynamic>(HiveKeys.userDetailsBox);
    await Hive.openBox<dynamic>(HiveKeys.authBox);

    if (kDebugMode) {
      print(
        'Here in SplashScreen HiveBox ${Hive.isBoxOpen(HiveKeys.languageBox)}',
      );
    }
    if (kDebugMode) {
      print('${HiveUtils.getLanguage()}');
    }
    if (HiveUtils.getLanguage() == null ||
        HiveUtils.getLanguage()?['data'] == null) {
      final result = await SystemRepository().fetchSystemSettings(
        isAnonymouse: true,
      );

      final code = result['data']['default_language'];

      await Api.get(
        url: Api.getLanguages,
        queryParameters: {Api.languageCode: code},
        useAuthToken: false,
      ).then((value) {
        HiveUtils.storeLanguage({
          'code': value['data']['code'],
          'data': value['data']['file_name'],
          'name': value['data']['name'],
          'isRTL': value['data']['rtl']?.toString() == '1',
        });
        onSuccess.call();
      });
    } else {
      onSuccess.call();
    }
  } on Exception catch (e, st) {
    log('Error while load default language $st');
  }
}
