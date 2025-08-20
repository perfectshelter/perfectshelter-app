import 'dart:developer';

import 'package:ebroker/exports/main_export.dart';

AppSettingsDataModel fallbackSettingAppSettings = AppSettingsDataModel(
  appHomeScreen: AppIcons.fallbackHomeLogo,
  placeholderLogo: AppIcons.fallbackPlaceholderLogo,
  lightPrimary: primaryColor_,
  lightSecondary: secondaryColor_,
  lightTertiary: tertiaryColor_,
  darkPrimary: primaryColorDark,
  darkSecondary: secondaryColorDark,
  darkTertiary: tertiaryColorDark,
);

///DO not touch this
class LoadAppSettings {
  Future<void> load({required bool initBox}) async {
    try {
      try {
        if (initBox == true) {
          await HiveUtils.initBoxes();
        }
        final response = await Api.get(
          url: Api.apiGetAppSettings,
          queryParameters: {
            if (HiveUtils.getUserId() != null) 'user_id': HiveUtils.getUserId(),
          },
        );
        final data = response['data'] as Map<String, dynamic>;
        appSettings = AppSettingsDataModel.fromJson(data);
        HiveUtils.setAppThemeSetting(data);
      } on ApiException {
        appSettings =
            AppSettingsDataModel.fromJson(HiveUtils.getAppThemeSettings());
      }
    } on Exception catch (ee) {
      log('Issue in load default setting $ee');
    }
  }

  SvgPicture svg(
    String svg, {
    Color? color,
    double? width,
    double? height,
  }) {
    if (svg.startsWith('assets/svg/')) {
      return SvgPicture.asset(
        svg,
        colorFilter:
            color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
        width: width,
        height: height,
      );
    } else {
      return SvgPicture.string(
        svg,
        colorFilter:
            color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
        width: width,
        height: height,
      );
    }
  }

  Widget loadHomeLogo(String homeLogoURL) {
    return CustomImage(
      imageUrl: appSettings.appHomeScreen ?? homeLogoURL,
      fit: BoxFit.scaleDown,
      width: 100,
      height: 100,
    );
  }
}
