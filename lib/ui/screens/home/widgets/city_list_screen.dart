import 'package:ebroker/data/cubits/property/fetch_city_property_list.dart';
import 'package:ebroker/data/model/city_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/city_properties_screen.dart';
import 'package:ebroker/ui/screens/home/home_screen.dart';
import 'package:ebroker/utils/sliver_grid_delegate_with_fixed_cross_axis_count_and_fixed_height.dart';
import 'package:flutter/material.dart';

class CityListScreen extends StatefulWidget {
  const CityListScreen({super.key, this.from, this.title});

  final String? from;
  final String? title;

  @override
  State<CityListScreen> createState() => _CityListScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>?;
    return CupertinoPageRoute(
      builder: (_) => CityListScreen(
        from: args?['from'] as String? ?? '',
        title: args?['title'] as String? ?? '',
      ),
    );
  }
}

class _CityListScreenState extends State<CityListScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    context.read<FetchCityCategoryCubit>().fetchCityCategory(
          forceRefresh: false,
        );
    addPageScrollListener();
    super.initState();
  }

  void addPageScrollListener() {
    cityScreenController.addListener(pageScrollListener);
  }

  void pageScrollListener() {
    ///This will load data on page end
    if (cityScreenController.isEndReached()) {
      if (mounted) {
        if (context.read<FetchCityCategoryCubit>().hasMoreData()) {
          context.read<FetchCityCategoryCubit>().fetchMore();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title:
            CustomText(widget.title ?? UiUtils.translate(context, 'allCities')),
      ),
      body: SingleChildScrollView(
        controller: cityScreenController,
        physics: Constant.scrollPhysics,
        child: Column(
          children: <Widget>[
            BlocBuilder<FetchCityCategoryCubit, FetchCityCategoryState>(
              builder: (context, state) {
                if (state is FetchCityCategoryFail) {
                  return const SomethingWentWrong();
                }
                if (state is FetchCityCategoryInProgress) {
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                      left: sidePadding,
                      right: sidePadding,
                      top: 8,
                      bottom: 25,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 10,
                      crossAxisCount: 2,
                      height: 260,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return const CustomShimmer(
                        height: 155,
                        width: 200,
                      );
                    },
                  );
                }
                if (state is FetchCityCategorySuccess && state.cities.isEmpty) {
                  return NoDataFound(
                    onTap: () {
                      Navigator.pushNamed(context, Routes.cityListScreen);
                    },
                  );
                }
                if (state is FetchCityCategorySuccess &&
                    state.cities.isNotEmpty) {
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                      left: sidePadding,
                      right: sidePadding,
                      top: 8,
                      bottom: 25,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 10,
                      crossAxisCount: 2,
                      height: 260,
                    ),
                    itemCount: state.cities.length,
                    itemBuilder: (context, index) {
                      final city = state.cities[index];
                      return CityCard(
                        count: city.count,
                        name: city.name,
                        city: city,
                      );
                    },
                  );
                }
                return Container();
              },
            ),
            if (context.watch<FetchCityCategoryCubit>().isLoadingMore()) ...[
              Center(child: UiUtils.progress()),
            ],
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class CityCard extends StatelessWidget {
  const CityCard({
    required this.city,
    required this.name,
    required this.count,
    super.key,
    this.isFirst,
    this.showEndPadding,
  });

  final City city;
  final String count;
  final bool? isFirst;
  final bool? showEndPadding;
  final String name;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<FetchCityPropertyList>().fetch(
              cityName: city.name,
              forceRefresh: true,
            );
        Navigator.push(
          context,
          CupertinoPageRoute<dynamic>(
            builder: (context) {
              return CityPropertiesScreen(
                cityName: city.name,
              );
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: context.color.secondaryColor,
        ),
        clipBehavior: Clip.antiAlias,
        height: MediaQuery.of(context).size.height * 0.35,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomImage(
                  imageUrl: city.image,
                  height: 100,
                  width: 100,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    CustomText(
                      city.name.firstUpperCase(),
                      fontWeight: FontWeight.bold,
                      fontSize: context.font.md,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    CustomText(
                      '${'properties'.translate(context)} (${city.count})',
                      fontSize: context.font.sm,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
