import 'dart:developer';

import 'package:perfectshelter/data/cubits/Personalized/add_update_personalized_interest.dart';
import 'package:perfectshelter/data/model/system_settings_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/utils/Extensions/lib/list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

part 'segments/choose_category.dart';
part 'segments/choose_nearby.dart';
part 'segments/other_interest.dart';

enum PersonalizedVisitType { firstTime, normal }

class PersonalizedPropertyScreen extends StatefulWidget {
  const PersonalizedPropertyScreen({required this.type, super.key});

  final PersonalizedVisitType type;

  static Route<dynamic> route(RouteSettings settings) {
    final args = settings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) => BlocProvider(
        create: (context) => AddUpdatePersonalizedInterest(),
        child: PersonalizedPropertyScreen(
          type: args?['type'] as PersonalizedVisitType? ??
              PersonalizedVisitType.normal,
        ),
      ),
    );
  }

  @override
  State<PersonalizedPropertyScreen> createState() =>
      _PersonalizedPropertyScreenState();
}

class _PersonalizedPropertyScreenState
    extends State<PersonalizedPropertyScreen> {
  List<int> selectedCategoryId = personalizedInterestSettings.categoryIds;
  List<int> selectedNearbyPlacesId = [];
  int selectedPage = 0;
  RangeValues? _selectedPriceRange;
  String selectedLocation = '';
  List<int> selectedPropertyType = [];

  @override
  void initState() {
    context.read<FetchCategoryCubit>().fetchCategories();
    context.read<FetchOutdoorFacilityListCubit>().fetch();
    super.initState();
  }

  final PageController _pageController = PageController();

  Future<void> onClearFilter() async {
    await PersonalizedFeedRepository().clearPersonalizedSettings(context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: BlocConsumer<AddUpdatePersonalizedInterest,
          AddUpdatePersonalizedInterestState>(
        listener: (context, state) {
          if (state is AddUpdatePersonalizedInterestInProgress) {
            Widgets.showLoader(context);
          }
          if (state is AddUpdatePersonalizedInterestFail) {
            Widgets.hideLoder(context);
            HelperUtils.showSnackBarMessage(
              context,
              'unableToSave'.translate(context),
            );
          }
          if (state is AddUpdatePersonalizedInterestSuccess) {
            Widgets.hideLoder(context);
            context.read<FetchPersonalizedPropertyList>().fetch(
                  forceRefresh: true,
                );
            if (widget.type == PersonalizedVisitType.firstTime) {
              Future.delayed(
                Duration.zero,
                () {
                  HelperUtils.showSnackBarMessage(
                    context,
                    'successfullyAdded'.translate(context),
                    type: MessageType.success,
                  );
                  HelperUtils.killPreviousPages(
                    context,
                    Routes.main,
                    {'from': 'login'},
                  );
                },
              );
            } else {
              HelperUtils.showSnackBarMessage(
                context,
                'successfullySaved'.translate(context),
                type: MessageType.success,
              );
              Navigator.pop(context);
            }
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SizedBox(
              width: context.screenWidth,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                pageSnapping: false,
                onPageChanged: _onPageChanged,
                children: [
                  CategoryInterestChoose(
                    controller: _pageController,
                    onClearFilter: onClearFilter,
                    type: widget.type,
                    onInteraction: _onCategoryInteraction,
                  ),
                  NearbyInterest(
                    controller: _pageController,
                    type: widget.type,
                    onInteraction: _onNearbyInteraction,
                  ),
                  OtherInterests(
                    type: widget.type,
                    onInteraction: _onOtherInterestsInteraction,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    const curve = Curves.easeInOut;
    return BottomAppBar(
      color: context.color.primaryColor,
      child: Row(
        children: [
          if (selectedPage > 0) ...[
            Expanded(
              child: UiUtils.buildButton(
                context,
                showElevation: false,
                height: 48.rh(context),
                onPressed: selectedCategoryId.isEmpty
                    ? () {}
                    : () {
                        _pageController.animateToPage(
                          --selectedPage,
                          duration: const Duration(milliseconds: 500),
                          curve: curve,
                        );
                      },
                textColor: context.color.tertiaryColor,
                buttonTitle: 'previouslbl'.translate(context),
                border: BorderSide(color: context.color.tertiaryColor),
                buttonColor: context.color.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: UiUtils.buildButton(
              context,
              height: 48.rh(context),
              showElevation: false,
              onPressed: selectedCategoryId.isEmpty
                  ? () {}
                  : () {
                      if (selectedPage < 2) {
                        _pageController.animateToPage(
                          ++selectedPage,
                          duration: const Duration(milliseconds: 500),
                          curve: curve,
                        );
                      } else {
                        _updatePersonalizedFeed();
                      }
                    },
              buttonTitle: 'next'.translate(context),
              textColor: selectedCategoryId.isEmpty
                  ? context.color.textColorDark
                  : null,
              buttonColor: selectedCategoryId.isEmpty
                  ? context.color.textLightColor
                  : context.color.tertiaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePersonalizedFeed() async {
    try {
      unawaited(Widgets.showLoader(context));
      await context.read<AddUpdatePersonalizedInterest>().addOrUpdate(
            action: PersonalizedFeedAction.add,
            categoryIds: selectedCategoryId,
            outdoorFacilityList: selectedNearbyPlacesId,
            priceRange: _selectedPriceRange,
            city: selectedLocation,
            selectedPropertyType: selectedPropertyType,
          );
      await context.read();
    } on Exception catch (e) {
      log('Error is $e');
    }
  }

  void _onPageChanged(int value) {
    selectedPage = value;
    setState(() {});
  }

  void _onCategoryInteraction(List<int> id) {
    selectedCategoryId = id;
    setState(() {});
  }

  void _onNearbyInteraction(List<int> idlist) {
    selectedNearbyPlacesId = idlist;
    setState(() {});
  }

  void _onOtherInterestsInteraction(
    RangeValues priceRange,
    String location,
    List<int> propertyTypes,
  ) {
    _selectedPriceRange = priceRange;
    selectedLocation = location;
    selectedPropertyType = propertyTypes;

    setState(() {});
  }
}
