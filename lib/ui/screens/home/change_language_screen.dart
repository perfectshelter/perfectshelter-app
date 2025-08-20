import 'package:perfectshelter/data/cubits/fetch_home_page_data_cubit.dart';
import 'package:perfectshelter/data/cubits/property/home_infinityscroll_cubit.dart';
import 'package:perfectshelter/data/model/system_settings_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:flutter/material.dart';

class LanguagesListScreen extends StatefulWidget {
  const LanguagesListScreen({super.key});
  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) => const LanguagesListScreen(),
    );
  }

  @override
  State<LanguagesListScreen> createState() => _LanguagesListScreenState();
}

class _LanguagesListScreenState extends State<LanguagesListScreen> {
  String? _initialLanguageCode;

  @override
  void initState() {
    super.initState();
    // Store the initial language code when the screen is first built
    _initialLanguageCode =
        (context.read<LanguageCubit>().state as LanguageLoader)
            .languageCode
            .toString();
  }

  @override
  Widget build(BuildContext context) {
    final setting = context
        .watch<FetchSystemSettingsCubit>()
        .getSetting(SystemSetting.languageType) as List;

    final languageState = context.watch<LanguageCubit>().state;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final currentLanguageCode =
            (context.read<LanguageCubit>().state as LanguageLoader)
                .languageCode
                .toString();
        // Only update if language has changed
        if (currentLanguageCode != _initialLanguageCode) {
          updateLanguage(context);
        }
        Navigator.pop(context);
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: CustomAppBar(
          title: CustomText(UiUtils.translate(context, 'chooseLanguage')),
          onTapBackButton: () {
            final currentLanguageCode =
                (context.read<LanguageCubit>().state as LanguageLoader)
                    .languageCode
                    .toString();
            // Only update if language has changed
            if (currentLanguageCode != _initialLanguageCode) {
              updateLanguage(context);
            }
          },
        ),
        body: context
                    .watch<FetchSystemSettingsCubit>()
                    .getSetting(SystemSetting.languageType) ==
                null
            ? Center(child: UiUtils.progress())
            : BlocListener<FetchLanguageCubit, FetchLanguageState>(
                listener: (context, state) {
                  if (state is FetchLanguageInProgress) {
                    Widgets.showLoader(context);
                  }
                  if (state is FetchLanguageFailure) {
                    Widgets.hideLoder(context);
                    HelperUtils.showSnackBarMessage(
                        context, state.errorMessage);
                  }
                  if (state is FetchLanguageSuccess) {
                    Widgets.hideLoder(context);
                    final map = state.toMap();
                    final data = map['file_name'];
                    map['data'] = data;

                    map.remove('file_name');
                    HiveUtils.storeLanguage(map);
                    context.read<LanguageCubit>().emitLanguageLoader(
                          code: state.code,
                          isRtl: state.isRTL,
                        );
                  }
                },
                child: ListView.separated(
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  physics: Constant.scrollPhysics,
                  padding: const EdgeInsets.all(18),
                  itemCount: setting.length,
                  itemBuilder: (context, index) {
                    final color = (languageState as LanguageLoader)
                                .languageCode ==
                            setting[index]['code']
                        ? context.color.tertiaryColor
                        : context.color.textLightColor.withValues(alpha: 0.03);

                    return GestureDetector(
                      onTap: () {
                        context.read<FetchLanguageCubit>().getLanguage(
                              setting[index]['code']?.toString() ?? '',
                            );
                      },
                      child: Container(
                        height: 48.rh(context),
                        alignment: AlignmentDirectional.centerStart,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: CustomText(
                          setting[index]['name']?.toString() ?? '',
                          fontWeight: FontWeight.bold,
                          fontSize: context.font.md,
                          color: languageState.languageCode ==
                                  setting[index]['code']
                              ? context.color.buttonColor
                              : context.color.textColorDark,
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  void updateLanguage(BuildContext context) {
    context.read<FetchHomePageDataCubit>().fetch(forceRefresh: true);
    context
        .read<FetchSystemSettingsCubit>()
        .fetchSettings(isAnonymous: HiveUtils.isUserAuthenticated());
    context.read<HomePageInfinityScrollCubit>().fetch();
    context.read<FetchCategoryCubit>().fetchCategories(forceRefresh: true);
    context.read<FetchOutdoorFacilityListCubit>().fetch();
    context.read<GetChatListCubit>().fetch(forceRefresh: true);
    context
        .read<FetchMyPropertiesCubit>()
        .fetchMyProperties(type: '', status: '');
    context.read<FetchMyProjectsListCubit>().fetchMyProjects();
  }
}
