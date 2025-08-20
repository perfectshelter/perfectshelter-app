import 'package:perfectshelter/data/cubits/fetch_single_article_cubit.dart';
import 'package:perfectshelter/data/model/article_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' show Html;

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) {
        return const ArticlesScreen();
      },
    );
  }

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final ScrollController _pageScrollController = ScrollController();

  @override
  void initState() {
    context.read<FetchArticlesCubit>().fetchArticles();
    _pageScrollController.addListener(pageScrollListen);
    super.initState();
  }

  void pageScrollListen() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchArticlesCubit>().hasMoreData()) {
        context.read<FetchArticlesCubit>().fetchArticlesMore();
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
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: CustomText(UiUtils.translate(context, 'articles')),
      ),
      body: CustomRefreshIndicator(
        onRefresh: () async {
          await context.read<FetchArticlesCubit>().fetchArticles();
        },
        child: BlocBuilder<FetchArticlesCubit, FetchArticlesState>(
          builder: (context, state) {
            if (state is FetchArticlesInProgress) {
              return buildArticlesShimmer();
            }
            if (state is FetchArticlesFailure) {
              if (state.errorMessage is NoInternetConnectionError) {
                return NoInternet(
                  onRetry: () {
                    context.read<FetchArticlesCubit>().fetchArticles();
                  },
                );
              }

              return const SomethingWentWrong();
            }
            if (state is FetchArticlesSuccess) {
              if (state.articlemodel.isEmpty) {
                return const NoDataFound();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (context, index) => const SizedBox(
                        height: 8,
                      ),
                      controller: _pageScrollController,
                      shrinkWrap: true,
                      physics: Constant.scrollPhysics,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.articlemodel.length,
                      itemBuilder: (context, index) {
                        final article = state.articlemodel[index];

                        return buildArticleCard(context, article);
                      },
                    ),
                  ),
                  if (state.isLoadingMore) const CircularProgressIndicator(),
                  if (state.loadingMoreError)
                    CustomText(UiUtils.translate(context, 'somethingWentWrng')),
                ],
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget buildArticleCard(BuildContext context, ArticleModel article) {
    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      height: 279.rh(context),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          context
              .read<FetchSingleArticleCubit>()
              .fetchArticlesById(article.id.toString());
          Navigator.pushNamed(
            context,
            Routes.articleDetailsScreenRoute,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CustomImage(
                imageUrl: article.image ?? '',
                width: double.infinity,
                height: 151.rh(context),
              ),
            ),
            const SizedBox(height: 8),
            CustomText(
              (article.translatedTitle ?? article.title ?? '').firstUpperCase(),
              maxLines: 2,
              color: context.color.textColorDark,
              fontWeight: FontWeight.w500,
              fontSize: context.font.sm,
            ),
            CustomText(
              stripHtmlTags(article.translatedDescription ??
                      article.description ??
                      '')
                  .trim(),
              maxLines: 2,
              color: context.color.textLightColor,
              fontWeight: FontWeight.w400,
              fontSize: context.font.xs,
            ),
            const Spacer(),
            UiUtils.getDivider(context),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  height: 16.rh(context),
                  width: 16.rw(context),
                  alignment: Alignment.center,
                  child: CustomImage(
                    imageUrl: AppIcons.calendar,
                    color: context.color.textLightColor,
                  ),
                ),
                const SizedBox(width: 4),
                CustomText(
                  article.date == null
                      ? ''
                      : article.date.toString().formatDate(),
                  color: context.color.textLightColor,
                  fontWeight: FontWeight.w400,
                  fontSize: context.font.xxs,
                ),
                const SizedBox(width: 8),
                Container(
                  height: 16.rh(context),
                  width: 16.rw(context),
                  alignment: Alignment.center,
                  child: CustomImage(
                    imageUrl: AppIcons.eye,
                    color: context.color.textLightColor,
                  ),
                ),
                const SizedBox(width: 4),
                CustomText(
                  article.viewCount ?? '',
                  color: context.color.textLightColor,
                  fontWeight: FontWeight.w400,
                  fontSize: context.font.xxs,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String stripHtmlTags(String htmlString) {
    final exp = RegExp('<[^>]*>', multiLine: true);
    final strippedString = htmlString.replaceAll(exp, '');
    return strippedString;
  }

  Widget buildArticlesShimmer() {
    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemCount: 10,
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Container(
          width: double.infinity,
          height: 279.rh(context),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: context.color.secondaryColor,
            border: Border.all(
              color: context.color.borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomShimmer(
                width: double.infinity,
                height: 160.rh(context),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(8),
                child: CustomShimmer(
                  width: 100.rw(context),
                  height: 10.rh(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: CustomShimmer(
                  width: 160.rw(context),
                  height: 10.rh(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: CustomShimmer(
                  width: 150.rw(context),
                  height: 10.rh(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: CustomShimmer(
                  width: 100.rw(context),
                  height: 10.rh(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Container article(FetchArticlesSuccess state, int index) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 50,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CustomText(
                state.articlemodel[index].title!,
                color: Colors.black,
              ),
              const Divider(),
              if (state.articlemodel[index].image != '') ...[
                Image.network(state.articlemodel[index].image!),
              ],
              const Divider(),
              Html(data: state.articlemodel[index].description),
            ],
          ),
        ),
      ),
    );
  }
}
