import 'package:perfectshelter/data/cubits/utility/fetch_facilities_cubit.dart';
import 'package:perfectshelter/data/helper/filter.dart';
import 'package:perfectshelter/data/model/category.dart';
import 'package:perfectshelter/data/model/propery_filter_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/widgets/bottom_sheets/choose_location_bottomsheet.dart';
import 'package:perfectshelter/utils/admob/banner_ad_load_widget.dart';
import 'package:flutter/material.dart';

dynamic city = '';
dynamic _state = '';

dynamic country = '';

class FilterScreen extends StatefulWidget {
  const FilterScreen({
    super.key,
    this.showPropertyType,
    this.selectedFilter,
  });
  final bool? showPropertyType;
  final FilterApply? selectedFilter;

  @override
  FilterScreenState createState() => FilterScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (_) => FilterScreen(
        selectedFilter: arguments?['filter'] as FilterApply? ?? FilterApply(),
        showPropertyType: arguments?['showPropertyType'] as bool? ?? false,
      ),
    );
  }
}

class FilterScreenState extends State<FilterScreen> {
  FilterScreenState() {
    Constant.propertyFilter = PropertyFilterModel.createEmpty();
  }
  late FilterApply filter = widget.selectedFilter ?? FilterApply();

  TextEditingController minController =
      TextEditingController(text: Constant.propertyFilter?.minPrice);
  TextEditingController maxController =
      TextEditingController(text: Constant.propertyFilter?.maxPrice);

  String propertyType = Constant.propertyFilter?.propertyType ?? '';
  //0: last_week   1: yesterday
  static String filterLastWeek = '0';
  static String filterYesterday = '1';
  static String filterLastMonth = '2';
  static String filterLastThreeMonth = '3';
  static String filterLastSixMonth = '4';
  static String filterAll = '';
  String postedOn = Constant.propertyFilter?.postedSince ??
      filterAll; // = 2; // 0: last_week   1: yesterday
  dynamic defaultCategoryID = currentVisitingCategoryId;
  dynamic defaultCategory = currentVisitingCategory;
  List<int> selectedFacilities = Constant.filterFacilities ?? [];
  // In your State class
  final List<_PostedSinceOption> _postedSinceOptions = [
    _PostedSinceOption(
      labelKey: 'anytimeLbl',
      filterValue: filterAll,
      duration: PostedSinceDuration.anytime,
    ),
    _PostedSinceOption(
      labelKey: 'lastWeekLbl',
      filterValue: filterLastWeek,
      duration: PostedSinceDuration.lastWeek,
    ),
    _PostedSinceOption(
      labelKey: 'yesterdayLbl',
      filterValue: filterYesterday,
      duration: PostedSinceDuration.yesterday,
    ),
    _PostedSinceOption(
      labelKey: 'lastMonthLbl',
      filterValue: filterLastMonth,
      duration: PostedSinceDuration.lastMonth,
    ),
    _PostedSinceOption(
      labelKey: 'lastThreeMonthLbl',
      filterValue: filterLastThreeMonth,
      duration: PostedSinceDuration.lastThreeMonth,
    ),
    _PostedSinceOption(
      labelKey: 'lastSixMonthLbl',
      filterValue: filterLastSixMonth,
      duration: PostedSinceDuration.lastSixMonth,
    ),
  ];

  @override
  void dispose() {
    minController.dispose();
    maxController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchFacilities();

    if (widget.selectedFilter == null) {
      filter
        ..addOrUpdate(PropertyTypeFilter(''))
        ..addOrUpdate(PostedSince(PostedSinceDuration.anytime));
    }

    setDefaultVal();
  }

  Future<void> fetchFacilities() async {
    await context.read<FetchFacilitiesCubit>().fetch();
  }

  void setDefaultVal() {
    postedOn = filterAll;
    Constant.propertyFilter = null;
    searchbody[Api.postedSince] = filterAll;
    propertyType = '';
    selectedcategoryId = '0';
    city = '';
    _state = '';
    country = '';
    selectedcategoryName = '';
    selectedCategory = defaultCategory;
    selectedFacilities = [];
    Constant.filterFacilities = [];

    // Reset the filter object
    filter = FilterApply();
    filter
      ..addOrUpdate(PropertyTypeFilter(''))
      ..addOrUpdate(PostedSince(PostedSinceDuration.anytime));

    minController.clear();
    maxController.clear();
    checkFilterValSet();
  }

  bool checkFilterValSet() {
    if (postedOn != filterAll ||
        propertyType.isNotEmpty ||
        minController.text.trim().isNotEmpty ||
        maxController.text.trim().isNotEmpty ||
        selectedCategory != defaultCategory ||
        selectedFacilities.isNotEmpty) {
      return true;
    }

    return false;
  }

  Future<void> _onTapChooseLocation() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showModalBottomSheet<dynamic>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      context: context,
      builder: (context) {
        return const ChooseLocatonBottomSheet();
      },
    );
    if (result != null) {
      final place = result as GooglePlaceModel;

      city = place.city;
      country = place.country;
      _state = place.state;
      filter.addOrUpdate(
        LocationFilter(
          placeId: place.placeId,
          // city: place.city,
          // country: place.country,
          // state: place.country,
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        Future.delayed(Duration.zero, () {
          Navigator.of(context).pop();
        });
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primaryColor,
          appBar: CustomAppBar(
            onTapBackButton: checkFilterValSet,
            title: CustomText(UiUtils.translate(context, 'filterTitle')),
          ),
          bottomNavigationBar: BottomAppBar(
            height: 72.rh(context),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: context.color.primaryColor,
            child: Row(
              children: [
                Expanded(
                  child: UiUtils.buildButton(
                    context,
                    onPressed: () {
                      setState(setDefaultVal);
                    },
                    buttonColor: context.color.secondaryColor,
                    showElevation: false,
                    textColor: context.color.textColorDark,
                    buttonTitle: UiUtils.translate(
                      context,
                      'clearfilter',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: UiUtils.buildButton(
                    context,
                    buttonTitle: UiUtils.translate(context, 'applyFilter'),
                    onPressed: () {
                      //this will set name of previous screen app bar

                      if (widget.showPropertyType ?? false) {
                        if (selectedCategory == null ||
                            selectedCategory == '') {
                          selectedcategoryName = '';
                        } else {
                          selectedcategoryName =
                              (selectedCategory as Category).category ?? '';
                        }
                      }

                      filter
                        ..addOrUpdate(
                          MinMaxBudget(
                            min: minController.text,
                            max: maxController.text,
                          ),
                        )
                        ..addOrUpdate(
                          FacilitiesFilter(
                            selectedFacilities,
                          ),
                        );
                      Navigator.pop(context, filter);
                    },
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            physics: Constant.scrollPhysics,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  const SizedBox(height: 8),
                  sellRentOption(),
                  const SizedBox(height: 16),
                  if (widget.showPropertyType ?? true) ...[
                    CustomText(
                      UiUtils.translate(context, 'proeprtyType'),
                      fontSize: context.font.sm,
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
                      builder: (context, state) {
                        if (state is FetchCategorySuccess) {
                          final categoriesList =
                              List<Category>.from(state.categories)
                                ..insert(0, Category(id: 0));
                          return SizedBox(
                            height: 32.rh(context),
                            child: ListView(
                              physics: Constant.scrollPhysics,
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              children: List.generate(
                                categoriesList.length,
                                (int index) {
                                  if (index == 0) {
                                    return allCategoriesFilterButton(context);
                                  }
                                  return GestureDetector(
                                    onTap: () {
                                      selectedCategory = categoriesList[index];
                                      filter.addOrUpdate(
                                        CategoryFilter(
                                          categoriesList[index].id.toString(),
                                        ),
                                      );

                                      setState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      margin: const EdgeInsetsDirectional.only(
                                          end: 12),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selectedCategory ==
                                                categoriesList[index]
                                            ? context.color.tertiaryColor
                                            : context.color.secondaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: context.color.borderColor,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          CustomImage(
                                            imageUrl:
                                                categoriesList[index].image!,
                                            height: 18.rh(context),
                                            width: 18.rw(context),
                                            color: selectedCategory ==
                                                    categoriesList[index]
                                                ? context.color.buttonColor
                                                : context.color.tertiaryColor,
                                          ),
                                          SizedBox(
                                            width: 8.rw(context),
                                          ),
                                          CustomText(
                                            categoriesList[index]
                                                .category
                                                .toString(),
                                            color: selectedCategory ==
                                                    categoriesList[index]
                                                ? context.color.buttonColor
                                                : context.color.textColorDark,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        return Container();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  CustomText(
                    UiUtils.translate(context, 'budgetLbl'),
                    fontSize: context.font.sm,
                  ),
                  const SizedBox(height: 8),
                  budgetOption(),
                  const SizedBox(height: 12),
                  postedSinceOption(),
                  const SizedBox(height: 12),
                  CustomText(
                    UiUtils.translate(context, 'locationLbl'),
                    fontSize: context.font.sm,
                  ),
                  const SizedBox(height: 8),
                  locationWidget(context),
                  const SizedBox(height: 12),
                  facilitiesCheckBox(context),
                  const SizedBox(height: 12),
                  const Center(
                    child: BannerAdWidget(
                      bannerSize: AdSize.banner,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget locationWidget(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48.rh(context),
            padding: const EdgeInsetsDirectional.only(start: 8, end: 8),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.color.borderColor),
            ),
            child: Row(
              children: [
                if (city != '' && city != null)
                  Expanded(
                    child: CustomText('$city,$_state,$country'),
                  )
                else
                  Expanded(
                    child: CustomText(
                      UiUtils.translate(context, 'selectLocationOptional'),
                      maxLines: 1,
                    ),
                  ),
                if (city != '' && city != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: GestureDetector(
                      onTap: _onTapChooseLocation,
                      child: Icon(
                        Icons.close,
                        color: context.color.textColorDark,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _onTapChooseLocation,
          child: Container(
            height: 48.rh(context),
            width: 48.rh(context),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.color.borderColor),
            ),
            child: CustomImage(
              imageUrl: AppIcons.location,
              height: 24.rh(context),
              width: 24.rw(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget allCategoriesFilterButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        selectedCategory = null;
        filter.addOrUpdate(CategoryFilter(null));

        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsetsDirectional.only(end: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selectedCategory == null
              ? context.color.tertiaryColor
              : context.color.secondaryColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.color.borderColor),
        ),
        child: CustomText(
          UiUtils.translate(context, 'lblall'),
          color: selectedCategory == null
              ? context.color.buttonColor
              : context.color.textColorDark,
        ),
      ),
    );
  }

  Widget sellRentOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: context.color.tertiaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: context.color.borderColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  //buttonSale
                  Expanded(
                    child: UiUtils.buildButton(
                      context,
                      height: 48.rh(context),
                      onPressed: () {
                        if (filter.check<PropertyTypeFilter>().type ==
                            Constant.valSellBuy) {
                          filter.addOrUpdate(
                            PropertyTypeFilter(''),
                          );
                          setState(() {});
                        } else {
                          filter.addOrUpdate(
                            PropertyTypeFilter(Constant.valSellBuy),
                          );
                          setState(() {});
                        }
                      },
                      showElevation: false,
                      textColor: filter.check<PropertyTypeFilter>().type ==
                              Constant.valSellBuy
                          ? context.color.buttonColor
                          : context.color.textColorDark,
                      buttonColor: filter.check<PropertyTypeFilter>().type ==
                              Constant.valSellBuy
                          ? context.color.tertiaryColor
                          : context.color.textColorDark.withValues(alpha: 0),
                      fontSize: context.font.md,
                      buttonTitle: UiUtils.translate(
                        context,
                        UiUtils.translate(context, 'forSell'),
                      ),
                    ),
                  ),
                  //buttonRent
                  Expanded(
                    child: UiUtils.buildButton(
                      context,
                      height: 48.rh(context),
                      onPressed: () {
                        if (filter.check<PropertyTypeFilter>().type ==
                            Constant.valRent) {
                          filter.addOrUpdate(
                            PropertyTypeFilter(''),
                          );
                          setState(() {});
                        } else {
                          filter.addOrUpdate(
                            PropertyTypeFilter(Constant.valRent),
                          );
                          setState(() {});
                        }
                      },
                      showElevation: false,
                      textColor: filter.check<PropertyTypeFilter>().type ==
                              Constant.valRent
                          ? context.color.buttonColor
                          : context.color.textColorDark,
                      buttonColor: filter.check<PropertyTypeFilter>().type ==
                              Constant.valRent
                          ? context.color.tertiaryColor
                          : context.color.textColorDark.withValues(alpha: 0),
                      fontSize: context.font.md,
                      buttonTitle: UiUtils.translate(
                        context,
                        UiUtils.translate(context, 'forRent'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void setPropertyType(String val) {
    searchbody[Api.propertyType] = val;

    setState(() {
      propertyType = val;
    });
  }

  Widget budgetOption() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: Container(
            height: 40.rh(context),
            margin: const EdgeInsetsDirectional.only(end: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              color: context.color.secondaryColor,
            ),
            child: TextFormField(
              controller: minController,
              autovalidateMode: AutovalidateMode.always,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value.toString().isEmpty || maxController.text.isEmpty) {
                  return null;
                }
                if (num.parse(value!) >= num.parse(maxController.text)) {
                  return '${'enterSmallerThan'.translate(context)} ${maxController.text}';
                }
                return null;
              },
              decoration: InputDecoration(
                isDense: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: context.color.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: context.color.borderColor),
                ),
                labelStyle: TextStyle(color: context.color.textColorDark),
                hintText: '00',
                label: CustomText(
                  'minLbl'.translate(context),
                ),
                prefixText: '${Constant.currencySymbol} ',
                prefixStyle: TextStyle(
                  color: context.color.textColorDark,
                ),
                fillColor: context.color.secondaryColor,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: context.color.textColorDark,
              ),
              /* onSubmitted: () */
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsetsDirectional.only(start: 8),
            height: 40.rh(context),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              color: context.color.secondaryColor,
            ),
            child: TextFormField(
              autovalidateMode: AutovalidateMode.always,
              validator: (value) {
                if (value.toString().isEmpty || minController.text.isEmpty) {
                  return null;
                }
                if (num.parse(value!) <= num.parse(minController.text)) {
                  return '${'enterBiggerThan'.translate(context)} ${minController.text}';
                }
                return null;
              },
              controller: maxController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                isDense: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: context.color.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: context.color.borderColor),
                ),
                labelStyle: TextStyle(color: context.color.textColorDark),
                hintText: '00',
                label: CustomText(
                  'maxLbl'.translate(context),
                ),
                prefixText: '${Constant.currencySymbol} ',
                prefixStyle: TextStyle(
                  color: context.color.textColorDark,
                ),
                fillColor: Theme.of(context).colorScheme.secondaryColor,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: context.color.textColorDark,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ),
      ],
    );
  }

  Widget minMaxTFF(String minMax) {
    return Container(
      padding: EdgeInsetsDirectional.only(
        end: minMax == UiUtils.translate(context, 'minLbl') ? 5 : 0,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        color: Theme.of(context).colorScheme.backgroundColor,
      ),
      child: TextFormField(
        controller: (minMax == UiUtils.translate(context, 'minLbl'))
            ? minController
            : maxController,
        onChanged: (value) {
          final isEmpty = value.trim().isEmpty;
          if (minMax == UiUtils.translate(context, 'minLbl')) {
            if (isEmpty && searchbody.containsKey(Api.minPrice)) {
              searchbody.remove(Api.minPrice);
            } else {
              searchbody[Api.minPrice] = value;
            }
          } else {
            if (isEmpty && searchbody.containsKey(Api.maxPrice)) {
              searchbody.remove(Api.maxPrice);
            } else {
              searchbody[Api.maxPrice] = value;
            }
          }
        },
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          isDense: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: context.color.tertiaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: context.color.tertiaryColor),
          ),
          labelStyle: TextStyle(color: context.color.tertiaryColor),
          hintText: '00',
          label: CustomText(
            minMax,
          ),
          prefixText: '${Constant.currencySymbol} ',
          prefixStyle: TextStyle(
            color: Theme.of(context).colorScheme.tertiaryColor,
          ),
          fillColor: Theme.of(context).colorScheme.secondaryColor,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        style: TextStyle(color: Theme.of(context).colorScheme.tertiaryColor),
        /* onSubmitted: () */
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );
  }

  Widget postedSinceOption() {
    // 1. Get the current filter value once to avoid repeated calls.
    final currentFilter = filter.check<PostedSince>().since.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CustomText(
          UiUtils.translate(context, 'postedSinceLbl'),
          fontSize: context.font.sm,
        ),
        const SizedBox(height: 8), // Use 'const' for performance
        SizedBox(
          height: 32.rh(context),
          // 2. Use ListView.separated for a cleaner implementation.
          child: ListView.separated(
            itemCount: _postedSinceOptions.length,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final option = _postedSinceOptions[index];
              final isSelected = currentFilter == option.filterValue;

              // 3. Build each button from the list of options.
              return UiUtils.buildButton(
                context,
                fontSize: context.font.sm,
                showElevation: false,
                autoWidth: true,
                border: BorderSide(color: context.color.borderColor),
                buttonColor: isSelected
                    ? context.color.tertiaryColor
                    : context.color.secondaryColor,
                textColor: isSelected
                    ? context.color.secondaryColor
                    : context.color.textColorDark,
                buttonTitle: UiUtils.translate(context, option.labelKey),
                onPressed: () {
                  filter.addOrUpdate(PostedSince(option.duration));
                  onClickPosted(option.filterValue);
                  setState(() {});
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void onClickPosted(String val) {
    if (val == filterAll && searchbody.containsKey(Api.postedSince)) {
      searchbody[Api.postedSince] = '';
    } else {
      searchbody[Api.postedSince] = val;
    }

    postedOn = val;

    setState(() {});
  }

  Widget facilitiesCheckBox(BuildContext context) {
    return BlocBuilder<FetchFacilitiesCubit, FetchFacilitiesState>(
      builder: (context, state) {
        if (state is FetchFacilitiesSuccess) {
          final facilities = state.facilities;
          if (facilities.isEmpty) {
            return const SizedBox.shrink();
          }
          return ExpansionTile(
            shape: const Border(),
            title: CustomText('facilities'.translate(context)),
            textColor: context.color.tertiaryColor,
            iconColor: context.color.tertiaryColor,
            backgroundColor: Colors.transparent,
            clipBehavior: Clip.none,
            initiallyExpanded: true,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                crossAxisCount: ResponsiveHelper.isLargeTablet(context) ? 4 : 3,
                crossAxisSpacing: 4,
                childAspectRatio: MediaQuery.of(context).size.width /
                    (MediaQuery.of(context).size.height / 4),
                children: List.generate(
                  facilities.length,
                  (int index) {
                    final isSelected =
                        selectedFacilities.contains(facilities[index].id) ||
                            (Constant.filterFacilities
                                    ?.contains(facilities[index].id) ??
                                false);
                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          selectedFacilities.remove(facilities[index].id);
                        } else {
                          selectedFacilities.add(facilities[index].id!);
                        }
                        Constant.filterFacilities = selectedFacilities;
                        setState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.color.tertiaryColor
                              : context.color.secondaryColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: context.color.borderColor,
                          ),
                        ),
                        child: CustomText(
                          facilities[index].translatedName ??
                              facilities[index].name ??
                              '',
                          maxLines: 2,
                          color: isSelected
                              ? context.color.buttonColor
                              : context.color.textColorDark,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _PostedSinceOption {
  const _PostedSinceOption({
    required this.labelKey,
    required this.filterValue,
    required this.duration,
  });
  final String labelKey;
  final String filterValue;
  final PostedSinceDuration duration;
}
