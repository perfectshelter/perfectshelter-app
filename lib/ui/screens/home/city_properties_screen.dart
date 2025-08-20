import 'package:ebroker/data/cubits/property/fetch_city_property_list.dart';
import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

class CityPropertiesScreen extends StatefulWidget {
  const CityPropertiesScreen({required this.cityName, super.key});

  final String cityName;

  @override
  State<CityPropertiesScreen> createState() => _CityPropertiesScreenState();
}

class _CityPropertiesScreenState extends State<CityPropertiesScreen> {
  FilterApply? selectedFilter;
  ScrollController cityPropertiesScreenController = ScrollController();

  @override
  void initState() {
    cityPropertiesScreenController.addListener(_onScroll);
    // Initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FetchCityPropertyList>().fetch(
            cityName: widget.cityName,
          );
    });
    super.initState();
  }

  void _onScroll() {
    // Check if we're near the bottom of the list
    if (cityPropertiesScreenController.position.pixels >=
        cityPropertiesScreenController.position.maxScrollExtent - 100) {
      final fetchCubit = context.read<FetchCityPropertyList>();

      // Only fetch more if not already loading and more data exists
      if (!fetchCubit.isLoadingMore() && fetchCubit.hasMoreData()) {
        fetchCubit.fetchMore();
      }
    }
  }

  @override
  void dispose() {
    // Always dispose of the ScrollController
    cityPropertiesScreenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: CustomText(widget.cityName),
      ),
      body: BlocBuilder<FetchCityPropertyList, FetchCityPropertyListState>(
        builder: (context, state) {
          return CustomRefreshIndicator(
            onRefresh: () async {
              await context.read<FetchCityPropertyList>().fetch(
                    cityName: widget.cityName,
                  );
            },
            child: Column(
              children: [
                if (state is FetchCityPropertyInProgress)
                  Expanded(child: UiUtils.buildHorizontalShimmer(context))
                else
                  state is FetchCityPropertyFail
                      ? const SomethingWentWrong()
                      : state is FetchCityPropertySuccess &&
                              state.properties.isNotEmpty
                          ? Expanded(
                              child: SizedBox(
                                height: MediaQuery.sizeOf(context).height,
                                width: MediaQuery.sizeOf(context).width,
                                child:
                                    ResponsiveHelper.isLargeTablet(context) ||
                                            ResponsiveHelper.isTablet(context)
                                        ? GridView.builder(
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              mainAxisSpacing: 8,
                                              crossAxisSpacing: 8,
                                            ),
                                            controller:
                                                cityPropertiesScreenController,
                                            padding: const EdgeInsets.all(16),
                                            itemCount: state.properties.length,
                                            shrinkWrap: true,
                                            itemBuilder: (context, index) {
                                              final property =
                                                  state.properties[index];
                                              return PropertyHorizontalCard(
                                                property: property,
                                                showLikeButton: true,
                                              );
                                            },
                                          )
                                        : ListView.separated(
                                            controller:
                                                cityPropertiesScreenController,
                                            padding: const EdgeInsets.all(16),
                                            itemCount: state.properties.length,
                                            shrinkWrap: true,
                                            separatorBuilder:
                                                (context, index) =>
                                                    const SizedBox(
                                              height: 8,
                                            ),
                                            itemBuilder: (context, index) {
                                              final property =
                                                  state.properties[index];
                                              return PropertyHorizontalCard(
                                                property: property,
                                                showLikeButton: true,
                                              );
                                            },
                                          ),
                              ),
                            )
                          : Center(
                              child: NoDataFound(
                                title: 'noPropertyAdded'.translate(context),
                              ),
                            ),
                if (context.watch<FetchCityPropertyList>().isLoadingMore())
                  Center(child: UiUtils.progress()),
              ],
            ),
          );
        },
      ),
    );
  }
}
