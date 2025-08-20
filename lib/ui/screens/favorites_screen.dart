import 'package:ebroker/exports/main_export.dart';
import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
  });

  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) => BlocProvider(
        create: (context) => FetchFavoritesCubit(),
        child: const FavoritesScreen(),
      ),
    );
  }

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ScrollController _pageScrollController = ScrollController();
  @override
  void initState() {
    _pageScrollController.addListener(_pageScrollListen);
    context.read<FetchFavoritesCubit>().fetchFavorites(
          forceRefresh: true,
        );
    super.initState();
  }

  void _pageScrollListen() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchFavoritesCubit>().hasMoreData()) {
        context.read<FetchFavoritesCubit>().fetchFavoritesMore();
      }
    }
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryColor,
      appBar: CustomAppBar(
        title: CustomText(UiUtils.translate(context, 'favorites')),
      ),
      body: BlocBuilder<FetchFavoritesCubit, FetchFavoritesState>(
        builder: (context, state) {
          if (state is FetchFavoritesInProgress) {
            return UiUtils.buildHorizontalShimmer(context);
          }
          if (state is FetchFavoritesFailure) {
            if (state.errorMessage is NoInternetConnectionError) {
              return NoInternet(
                onRetry: () {
                  context.read<FetchFavoritesCubit>().fetchFavorites(
                        forceRefresh: true,
                      );
                },
              );
            }

            return const SomethingWentWrong();
          }
          if (state is FetchFavoritesSuccess) {
            if (state.propertymodel.isEmpty) {
              return SingleChildScrollView(
                physics: Constant.scrollPhysics,
                child: SizedBox(
                  height: context.screenHeight - 100.rh(context),
                  child: Center(
                    child: NoDataFound(
                      onTap: () {
                        context.read<FetchFavoritesCubit>().fetchFavorites(
                              forceRefresh: true,
                            );
                      },
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    controller: _pageScrollController,
                    physics: Constant.scrollPhysics,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.propertymodel.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final property = state.propertymodel[index];
                      return PropertyHorizontalCard(
                        property: property,
                      );
                    },
                  ),
                ),
                if (state.isLoadingMore)
                  UiUtils.progress(
                    height: 30.rh(context),
                    width: 30.rw(context),
                  ),
              ],
            );
          }

          return Container();
        },
      ),
    );
  }
}
