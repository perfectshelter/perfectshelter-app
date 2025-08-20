import 'package:perfectshelter/data/repositories/favourites_repository.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/firebase_options.dart';
import 'package:flutter/material.dart';

PersonalizedInterestSettings personalizedInterestSettings =
    PersonalizedInterestSettings.empty();
AppSettingsDataModel appSettings = fallbackSettingAppSettings;

Future<void> initApp() async {
  ///Note: this file's code is very necessary and sensitive if you change it,
  ///This might affect whole app , So change it carefully.
  ///This must be used do not remove this line
  await HiveUtils.initBoxes();
  Api.initInterceptors();
  Api.initCurlLoggerInterceptor();

  ///This is the widget to show uncaught runtime error in this custom widget so
  ///that user can know in that screen something is wrong instead of grey screen
  SomethingWentWrong.asGlobalErrorBuilder();

  if (Firebase.apps.isNotEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(
    NotificationService.onBackgroundMessageHandler,
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) async {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    await LoadAppSettings().load(initBox: false);
    runApp(const EntryPoint());
  });
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    ///Here Fetching property report reasons
    context.read<LanguageCubit>().loadCurrentLanguage();

    ///////////////////////////////////////
    NotificationService.init(context);
    ///////////////////////////////////////

    APICallTrigger.onTrigger(
      () {
        ///THIS WILL be CALLED WHEN USER WILL LOGIN FROM ANONYMOUS USER.
        context.read<LikedPropertiesCubit>().clear();

        loadInitialData(
          context,
          loadWithoutDelay: true,
        );
      },
    );

    UiUtils.setContext(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkManager.initDeepLinks(context);
    });
    super.initState();
  }

  @override
  void dispose() {
    DeepLinkManager.dispose(); // Clean up the deep link subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GetApiKeysCubit, GetApiKeysState>(
      listener: (context, state) {
        context.read<GetApiKeysCubit>().setAPIKeys();
      },
      child: BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, languageState) {
          return BlocBuilder<AppThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp(
                initialRoute: Routes.splash,
                navigatorKey: Constant.navigatorKey,
                title: Constant.appName,
                debugShowCheckedModeBanner: false,
                onGenerateRoute: Routes.onGenerateRouted,
                themeMode: themeMode,
                theme: appThemeData[Brightness.light],
                darkTheme: appThemeData[Brightness.dark],
                builder: (context, child) {
                  ErrorFilter.setContext(context);
                  TextDirection direction;

                  // Set text direction based on language
                  if (languageState is LanguageLoader) {
                    direction = languageState.isRTL
                        ? TextDirection.rtl
                        : TextDirection.ltr;
                  } else {
                    direction = TextDirection.ltr;
                  }

                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.noScaling,
                    ),
                    child: Directionality(
                      textDirection: direction,
                      child: child!,
                    ),
                  );
                },
                localizationsDelegates: const [
                  AppLocalization.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                locale: loadLocalLanguageIfFail(languageState),
              );
            },
          );
        },
      ),
    );
  }

  Locale loadLocalLanguageIfFail(LanguageState state) {
    if (state is LanguageLoader) {
      return Locale(state.languageCode.toString());
    } else if (state is LanguageLoadFail) {
      return const Locale('en');
    } else {
      return const Locale('en');
    }
  }
}

void loadInitialData(
  BuildContext context, {
  bool? loadWithoutDelay,
  bool? forceRefresh,
}) {
  GuestChecker.check(
    onNotGuest: () async {
      final favoritesData = await FavoriteRepository().fechFavorites(offset: 0);
      final favoriteIds =
          favoritesData.modelList.map((property) => property.id!).toList();
      context.read<LikedPropertiesCubit>().setFavorites(favoriteIds);
    },
  );
  if (context.read<FetchCategoryCubit>().state is! FetchCategorySuccess) {
    context.read<FetchCategoryCubit>().fetchCategories(
          loadWithoutDelay: loadWithoutDelay,
          forceRefresh: forceRefresh,
        );
  }
  context.read<FetchNearbyPropertiesCubit>().fetch(
        loadWithoutDelay: loadWithoutDelay,
        forceRefresh: forceRefresh,
      );
  context.read<FetchCityCategoryCubit>().fetchCityCategory(
        loadWithoutDelay: loadWithoutDelay,
        forceRefresh: forceRefresh,
      );

  if (context.read<AuthenticationCubit>().isAuthenticated()) {
    context.read<GetChatListCubit>().setContext(context);
    context.read<GetChatListCubit>().fetch(forceRefresh: forceRefresh ?? false);
    context.read<FetchPersonalizedPropertyList>().fetch(
          loadWithoutDelay: loadWithoutDelay,
          forceRefresh: forceRefresh,
        );

    PersonalizedFeedRepository().getUserPersonalizedSettings().then((value) {
      personalizedInterestSettings = value;
    });
  }

  GuestChecker.listen().addListener(() {
    if (GuestChecker.value == false) {
      PersonalizedFeedRepository().getUserPersonalizedSettings().then((value) {
        personalizedInterestSettings = value;
      });
    }
  });

  //    // }
}
