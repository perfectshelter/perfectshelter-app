import 'package:ebroker/data/cubits/fetch_single_article_cubit.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:flutter/material.dart';

class ArticleDetails extends StatefulWidget {
  const ArticleDetails({super.key});

  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) {
        return const ArticleDetails();
      },
    );
  }

  @override
  State<ArticleDetails> createState() => _ArticleDetailsState();
}

class _ArticleDetailsState extends State<ArticleDetails> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.read<FetchArticlesCubit>().fetchArticles();
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: CustomAppBar(
          onTapBackButton: () {
            context.read<FetchArticlesCubit>().fetchArticles();
          },
        ),
        body: BlocBuilder<FetchSingleArticleCubit, FetchSingleArticleState>(
          builder: (context, state) {
            if (state is FetchSingleArticleFailure) {
              return const SomethingWentWrong();
            }
            if (state is FetchSingleArticleInProgress) {
              return Center(
                child: UiUtils.progress(),
              );
            }
            if (state is FetchSingleArticleSuccess) {
              return SingleChildScrollView(
                physics: Constant.scrollPhysics,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: context.screenWidth,
                          height: 211.rh(context),
                          child:
                              CustomImage(imageUrl: state.articlemodel.image!),
                        ),
                      ),
                      SizedBox(height: 8.rh(context)),
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
                            state.articlemodel.date == null
                                ? ''
                                : state.articlemodel.date
                                    .toString()
                                    .formatDate(),
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
                            state.articlemodel.viewCount ?? '',
                            color: context.color.textLightColor,
                            fontWeight: FontWeight.w400,
                            fontSize: context.font.xxs,
                          ),
                        ],
                      ),
                      SizedBox(height: 8.rh(context)),
                      CustomText(
                        (state.articlemodel.translatedTitle ??
                                state.articlemodel.title ??
                                '')
                            .firstUpperCase(),
                        fontWeight: FontWeight.w500,
                        fontSize: context.font.md,
                        color: context.color.textColorDark,
                      ),
                      SizedBox(height: 8.rh(context)),
                      CustomText(
                        stripHtmlTags(
                                state.articlemodel.translatedDescription ??
                                    state.articlemodel.description ??
                                    '')
                            .trim(),
                        fontSize: context.font.xs,
                        maxLines: 999999999,
                        fontWeight: FontWeight.w400,
                        color: context.color.textLightColor,
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  String stripHtmlTags(String htmlString) {
    final exp = RegExp('<[^>]*>', multiLine: true);
    final strippedString = htmlString.replaceAll(exp, '');
    return strippedString;
  }
}
