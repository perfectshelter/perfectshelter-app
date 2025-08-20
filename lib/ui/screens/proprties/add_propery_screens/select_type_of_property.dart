import 'package:ebroker/data/model/category.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:flutter/material.dart';

enum PropertyAddType { project, property }

class SelectPropertyType extends StatefulWidget {
  const SelectPropertyType({required this.type, super.key});

  final PropertyAddType type;

  static Route<dynamic> route(RouteSettings settings) {
    final arguments = settings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) {
        return SelectPropertyType(
          type: arguments?['type'] as PropertyAddType? ??
              PropertyAddType.property,
        );
      },
    );
  }

  @override
  State<SelectPropertyType> createState() => _SelectPropertyTypeState();
}

class _SelectPropertyTypeState extends State<SelectPropertyType> {
  int? selectedIndex;
  Category? selectedCategory;

  @override
  void initState() {
    super.initState();
    context.read<FetchOutdoorFacilityListCubit>().fetch();
  }

  void _openSubscriptionScreen() {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      Routes.subscriptionPackageListRoute,
      arguments: {
        'isBankTransferEnabled':
            (context.read<GetApiKeysCubit>().state as GetApiKeysSuccess)
                    .bankTransferStatus ==
                '1',
      },
    ).then((value) {
      context.read<GetSubsctiptionPackageLimitsCubit>().getLimits(
            packageType: 'property_list',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: CustomText(
          widget.type == PropertyAddType.property
              ? UiUtils.translate(context, 'ddPropertyLbl')
              : UiUtils.translate(context, 'projectType'),
        ),
        actions: [
          if (widget.type == PropertyAddType.property)
            CustomText(
              '1/4',
              fontSize: context.font.sm,
              fontWeight: FontWeight.w500,
              color: context.color.textColorDark,
            ),
        ],
      ),
      bottomNavigationBar: ColoredBox(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: UiUtils.buildButton(
            context,
            disabledColor: Colors.grey,
            onTapDisabledButton: () {
              HelperUtils.showSnackBarMessage(
                context,
                'pleaseSelectCategory'.translate(context),
                isFloating: true,
              );
            },
            disabled: selectedCategory == null,
            onPressed: () {
              final state =
                  context.read<GetSubsctiptionPackageLimitsCubit>().state;
              if (state is! GetSubscriptionPackageLimitsInProgress) {
                Constant.addProperty.addAll({'category': selectedCategory});

                if (selectedCategory != null) {
                  if (widget.type == PropertyAddType.property) {
                    Navigator.pushNamed(
                      context,
                      Routes.addPropertyDetailsScreen,
                    );
                  } else {
                    Navigator.pushNamed(context, Routes.addProjectDetails);
                  }
                }
              }
            },
            height: 48.rh(context),
            buttonTitle: UiUtils.translate(context, 'continue'),
          ),
        ),
      ),
      body: BlocListener<GetSubsctiptionPackageLimitsCubit,
          GetSubscriptionPackageLimitsState>(
        bloc: context.read<GetSubsctiptionPackageLimitsCubit>(),
        listener: (context, state) {
          if (state is GetSubscriptionPackageLimitsInProgress) {}
          if (state is GetSubsctiptionPackageLimitsFailure) {
            Widgets.hideLoder(context);
            HelperUtils.showSnackBarMessage(
              context,
              state.errorMessage,
              onClose: () {
                Navigator.pop(context);
              },
            );
          }
          if (state is GetSubscriptionPackageLimitsSuccess) {
            if (state.hasSubscription == false) {
              Widgets.hideLoder(context);
              UiUtils.showBlurredDialoge(
                context,
                sigmaX: 3,
                sigmaY: 3,
                dialog: BlurredDialogBox(
                  isAcceptContainesPush: true,
                  acceptButtonName: UiUtils.translate(context, 'subscribe'),
                  backAllowedButton: false,
                  title: UiUtils.translate(context, 'packageNotValid'),
                  content: CustomText(
                    UiUtils.translate(context, 'packageNotForProperty'),
                  ),
                  onCancel: () {
                    Navigator.pop(context);
                  },
                  onAccept: () async {
                    _openSubscriptionScreen();
                  },
                ),
              );
            } else {
              Widgets.hideLoder(context);
            }
          }
        },
        child: SingleChildScrollView(
          physics: Constant.scrollPhysics,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 16,
                  end: 16,
                  top: 16,
                ),
                child: CustomText(
                  UiUtils.translate(context, 'typeOfProperty'),
                  color: context.color.textColorDark,
                ),
              ),
              BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
                builder: (context, state) {
                  if (state is FetchCategoryInProgress) {}
                  if (state is FetchCategoryFailure) {
                    return Center(
                      child: CustomText(state.errorMessage),
                    );
                  }
                  if (state is FetchCategorySuccess) {
                    return GridView.builder(
                      itemCount: state.categories.length,
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        crossAxisCount: 3,
                      ),
                      itemBuilder: (context, index) {
                        return buildTypeCard(
                          index,
                          context,
                          state.categories[index],
                        );
                      },
                    );
                  }
                  return Container();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTypeCard(int index, BuildContext context, Category category) {
    return GestureDetector(
      onTap: () {
        selectedCategory = category;
        selectedIndex = index;
        setState(() {});
      },
      child: Container(
        decoration: BoxDecoration(
          color: selectedIndex == index
              ? context.color.tertiaryColor
              : context.color.secondaryColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: (selectedIndex == index)
              ? [
                  BoxShadow(
                    blurRadius: 4,
                    color: context.color.tertiaryColor,
                  ),
                ]
              : null,
          border: (selectedIndex == index)
              ? null
              : Border.all(color: context.color.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 25.rh(context),
              width: 25.rw(context),
              child: CustomImage(
                imageUrl: category.image ?? '',
                color: selectedIndex == index
                    ? context.color.buttonColor
                    : context.color.textColorDark,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: CustomText(
                category.translatedName ?? category.category ?? '',
                textAlign: TextAlign.center,
                maxLines: 3,
                color: selectedIndex == index
                    ? context.color.buttonColor
                    : context.color.textColorDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
