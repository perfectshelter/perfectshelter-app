import 'package:perfectshelter/app/routes.dart';
import 'package:perfectshelter/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:perfectshelter/data/model/system_settings_model.dart';
import 'package:perfectshelter/utils/Extensions/extensions.dart';
import 'package:perfectshelter/utils/app_icons.dart';
import 'package:perfectshelter/utils/custom_image.dart';
import 'package:perfectshelter/utils/extensions/lib/custom_text.dart';
import 'package:perfectshelter/utils/hive_keys.dart';
import 'package:perfectshelter/utils/lottie/lottie_editor.dart';
import 'package:perfectshelter/utils/responsive_size.dart';
import 'package:perfectshelter/utils/ui_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPageIndex = 0;
  int previousePageIndex = 0;
  double changedOnPageScroll = 0.5;
  double currentSwipe = 0;
  late int totalPages;

  final LottieEditor _onBoardingOne = LottieEditor();
  final LottieEditor _onBoardingTwo = LottieEditor();
  final LottieEditor _onBoardingThree = LottieEditor();

  dynamic onBoardingOneData;
  dynamic onBoardingTwoData;
  dynamic onBoardingThreeData;

  @override
  void initState() {
    _onBoardingOne.openAndLoad('assets/lottie/onbo_a.json');
    _onBoardingTwo.openAndLoad('assets/lottie/onbo_b.json');
    _onBoardingThree.openAndLoad('assets/lottie/onbo_c.json');

    Future.delayed(
      Duration.zero,
      () {
        _onBoardingOne.changeWholeLottieFileColor(context.color.tertiaryColor);
        _onBoardingTwo.changeWholeLottieFileColor(context.color.tertiaryColor);
        _onBoardingThree
            .changeWholeLottieFileColor(context.color.tertiaryColor);

        onBoardingOneData = _onBoardingOne.convertToUint8List();
        onBoardingTwoData = _onBoardingTwo.convertToUint8List();
        onBoardingThreeData = _onBoardingThree.convertToUint8List();
        setState(() {});
      },
    );

    Future.delayed(Duration.zero, () {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final slidersList = [
      {
        'lottie': onBoardingOneData,
        'title': UiUtils.translate(context, 'onboarding_1_title'),
        'description': UiUtils.translate(context, 'onboarding_1_description'),
        'button': 'next_button.svg',
      },
      {
        'lottie': onBoardingTwoData,
        'title': UiUtils.translate(context, 'onboarding_2_title'),
        'description': UiUtils.translate(context, 'onboarding_2_description'),
      },
      {
        'lottie': onBoardingThreeData,
        'title': UiUtils.translate(context, 'onboarding_3_title'),
        'description': UiUtils.translate(context, 'onboarding_3_description'),
      },
    ];

    totalPages = slidersList.length;
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        body: Stack(
          children: <Widget>[
            Container(
              color: context.color.tertiaryColor.withValues(alpha: 0.1),
            ),
            PositionedDirectional(
              bottom: 282.rh(context),
              child: SizedBox(
                height: 400.rh(context),
                width: context.screenWidth,
                child: (slidersList[currentPageIndex]['lottie'] != null)
                    ? Lottie.memory(
                        width: 350.rw(context),
                        height: 350.rh(context),
                        fit: BoxFit.contain,
                        Uint8List.fromList(
                          slidersList[currentPageIndex]['lottie']
                                  as List<int>? ??
                              [],
                        ),
                        delegates: const LottieDelegates(
                          values: [],
                        ),
                        errorBuilder: (context, error, stackTrace) {
                          return Container();
                        },
                      )
                    : Container(),
              ),
            ),
            PositionedDirectional(
              top: kPagingTouchSlop,
              start: 16,
              child: GestureDetector(
                onTap: () async {
                  await context.read<FetchSystemSettingsCubit>().fetchSettings(
                        isAnonymous: true,
                      );
                  await Navigator.pushNamed(
                    context,
                    Routes.languageListScreenRoute,
                  );
                },
                child: Row(
                  children: [
                    StreamBuilder(
                      stream: Hive.box<dynamic>(HiveKeys.languageBox)
                          .watch(key: HiveKeys.currentLanguageKey),
                      builder: (context, AsyncSnapshot<BoxEvent> value) {
                        final language = context
                            .watch<FetchSystemSettingsCubit>()
                            .getSetting(SystemSetting.language)
                            .toString()
                            .firstUpperCase();

                        if (value.data?.value == null) {
                          if (language == 'null') {
                            return const CustomText('');
                          }
                          return CustomText(
                            context
                                .watch<FetchSystemSettingsCubit>()
                                .getSetting(SystemSetting.language)
                                .toString()
                                .firstUpperCase(),
                            color: context.color.textColorDark,
                            fontSize: context.font.md,
                            fontWeight: FontWeight.w600,
                          );
                        } else {
                          return CustomText(
                            value.data!.value!['code']
                                .toString()
                                .firstUpperCase(),
                            color: context.color.textColorDark,
                            fontSize: context.font.md,
                            fontWeight: FontWeight.w600,
                          );
                        }
                      },
                    ),
                    Container(
                      width: 24.rw(context),
                      height: 24.rh(context),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.keyboard_arrow_down_outlined,
                        color: context.color.textColorDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              top: kPagingTouchSlop,
              end: 16.rw(context),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, Routes.login);
                },
                child: CustomText(
                  'skip'.translate(context),
                  color: context.color.textColorDark,
                  fontSize: context.font.md,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            PositionedDirectional(
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (DragUpdateDetails details) {
                  currentSwipe = details.localPosition.direction;
                  setState(() {});
                },
                onHorizontalDragEnd: (details) {
                  if (currentSwipe < 0.5) {
                    if (changedOnPageScroll == 1 ||
                        changedOnPageScroll == 0.5) {
                      if (currentPageIndex > 0) {
                        currentPageIndex--;
                        changedOnPageScroll = 0;
                      }
                    }
                    setState(() {});
                  } else {
                    if (currentPageIndex < totalPages) {
                      if (changedOnPageScroll == 0 ||
                          changedOnPageScroll == 0.5) {
                        if (currentPageIndex < slidersList.length - 1) {
                          currentPageIndex++;
                        } else {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.login,
                            (route) => false,
                          );
                        }
                        setState(() {});
                      }
                    }
                  }

                  changedOnPageScroll = 0.5;
                  setState(() {});
                },
                child: Container(
                  height: 282.rh(context),
                  width: context.screenWidth,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(48),
                      topRight: Radius.circular(48),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: CustomText(
                          slidersList[currentPageIndex]['title']?.toString() ??
                              '',
                          key: const Key('onboarding_title'),
                          fontWeight: FontWeight.w500,
                          fontSize: context.font.xxl,
                          color: context.color.tertiaryColor,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      CustomText(
                        slidersList[currentPageIndex]['description']
                                ?.toString() ??
                            '',
                        maxLines: 3,
                        textAlign: TextAlign.center,
                        fontSize: context.font.md,
                        color: context.color.textColorDark,
                        fontWeight: FontWeight.w600,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Row(
                            children: [
                              for (var i = 0; i < slidersList.length; i++) ...[
                                buildIndicator(
                                  context,
                                  selected: i == currentPageIndex,
                                ),
                              ],
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            key: const ValueKey('next_screen'),
                            onTap: () {
                              if (currentPageIndex < slidersList.length - 1) {
                                currentPageIndex++;
                              } else {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  Routes.login,
                                  (route) => false,
                                );
                              }
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              width: 48.rw(context),
                              height: 48.rh(context),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: context.color.tertiaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: CustomImage(
                                matchTextDirection: true,
                                imageUrl: AppIcons.arrowRight,
                                fit: BoxFit.contain,
                                color: context.color.backgroundColor,
                                width: 24.rw(context),
                                height: 24.rh(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIndicator(BuildContext context, {required bool selected}) {
    if (selected) {
      return Container(
        margin: const EdgeInsetsDirectional.only(end: 10),
        width: 28.rw(context),
        height: 8.rh(context),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: context.color.tertiaryColor,
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsetsDirectional.only(end: 10),
        width: 8.rw(context),
        height: 8.rh(context),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: context.color.textColorDark,
          ),
        ),
      );
    }
  }
}
