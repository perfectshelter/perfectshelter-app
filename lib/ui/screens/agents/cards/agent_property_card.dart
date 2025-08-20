import 'package:perfectshelter/data/model/agent/agents_properties_models/properties_data.dart';
import 'package:perfectshelter/data/repositories/check_package.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/home/widgets/sell_rent_label.dart';
import 'package:perfectshelter/ui/screens/widgets/like_button_widget.dart';
import 'package:perfectshelter/ui/screens/widgets/promoted_widget.dart';
import 'package:perfectshelter/utils/price_format.dart';
import 'package:flutter/material.dart';

class AgentPropertyCard extends StatelessWidget {
  const AgentPropertyCard({
    required this.agentPropertiesData,
    super.key,
    this.useRow,
    this.addBottom,
    this.additionalHeight,
    this.statusButton,
    this.onDeleteTap,
    this.showLikeButton,
    this.additionalImageWidth,
  });

  final PropertiesData agentPropertiesData;
  final List<Widget>? addBottom;
  final double? additionalHeight;
  final StatusButton? statusButton;
  final bool? useRow;
  final VoidCallback? onDeleteTap;
  final double? additionalImageWidth;
  final bool? showLikeButton;

  @override
  Widget build(BuildContext context) {
    final price = agentPropertiesData.price.priceFormat(
      enabled: Constant.isNumberWithSuffix == true,
      context: context,
    );

    final isPremium = agentPropertiesData.isPremium == '1';
    final isPromoted = agentPropertiesData.promoted;
    final isAddedByMe = agentPropertiesData.addedBy == HiveUtils.getUserId();
    final isRent = agentPropertiesData.propertyType.toLowerCase() == 'rent';
    return BlocProvider(
      create: (context) => AddToFavoriteCubitCubit(),
      child: GestureDetector(
        onLongPress: () {
          HelperUtils.share(
            context,
            agentPropertiesData.slugId,
          );
        },
        onTap: () async {
          try {
            if (isPremium) {
              await GuestChecker.check(
                onNotGuest: () async {
                  unawaited(Widgets.showLoader(context));

                  if (isAddedByMe) {
                    await _navigateToPropertyDetails(
                      context,
                      agentPropertiesData.id,
                      isAddedByMe,
                    );
                  } else {
                    final checkPackage = CheckPackage();
                    final packageAvailable =
                        await checkPackage.checkPackageAvailable(
                      packageType: PackageType.premiumProperties,
                    );
                    if (packageAvailable) {
                      await _navigateToPropertyDetails(
                        context,
                        agentPropertiesData.id,
                        isAddedByMe,
                      );
                    } else {
                      Widgets.hideLoder(context);

                      await UiUtils.showBlurredDialoge(
                        context,
                        dialog: const BlurredSubscriptionDialogBox(
                          packageType:
                              SubscriptionPackageType.premiumProperties,
                          isAcceptContainesPush: true,
                        ),
                      );
                    }
                  }
                },
              );
            } else {
              unawaited(Widgets.showLoader(context));

              await _navigateToPropertyDetails(
                context,
                agentPropertiesData.id,
                isAddedByMe,
              );
            }
          } on Exception catch (_) {
            // Error handled in the finally block
          } finally {
            Widgets.hideLoder(context);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 8),
          height: 122.rh(context),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.color.borderColor,
            ),
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CustomImage(
                      imageUrl: agentPropertiesData.titleImage,
                      height: double.infinity,
                      width: 124.rw(context),
                    ),
                  ),
                  if (isPremium)
                    PositionedDirectional(
                      start: 4.rw(context),
                      top: 4.rh(context),
                      child: CustomImage(
                        imageUrl: AppIcons.premium,
                        height: 24.rh(context),
                        width: 24.rw(context),
                      ),
                    ),
                  if (isPromoted)
                    PositionedDirectional(
                      start: 4.rw(context),
                      bottom: 4.rh(context),
                      child: const PromotedCard(),
                    ),
                ],
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Row(
                      children: [
                        CustomImage(
                          imageUrl: agentPropertiesData.category.image ?? '',
                          width: 18.rw(context),
                          height: 18.rh(context),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: CustomText(
                            agentPropertiesData.category.translatedName ??
                                agentPropertiesData.category.category ??
                                '',
                            maxLines: 1,
                            fontWeight: FontWeight.w500,
                            fontSize: context.font.xs,
                            color: context.color.textLightColor,
                          ),
                        ),
                        // Like Button
                        if (showLikeButton ?? true)
                          LikeButtonWidget(
                            propertyId: agentPropertiesData.id,
                            isFavourite: agentPropertiesData.isFavourite == '1',
                          ),
                        if (showLikeButton == false && statusButton == null)
                          const SizedBox(width: 24),
                        if (statusButton != null)
                          Container(
                            decoration: BoxDecoration(
                              color: statusButton!.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(
                                  child: CustomText(
                                    statusButton!.lable,
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.font.xs,
                                    color: statusButton?.textColor ??
                                        context.color.textColorDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    // Title
                    CustomText(
                      agentPropertiesData.title.firstUpperCase(),
                      maxLines: 1,
                      fontSize: context.font.sm,
                      color: context.color.textColorDark,
                    ),
                    // City
                    if (agentPropertiesData.city != '')
                      Row(
                        children: [
                          CustomImage(
                            imageUrl: AppIcons.location,
                            width: 18.rw(context),
                            height: 18.rh(context),
                            color: context.color.textLightColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: CustomText(
                              agentPropertiesData.city.trim(),
                              maxLines: 1,
                              fontSize: context.font.xs,
                              fontWeight: FontWeight.w500,
                              color: context.color.textLightColor,
                            ),
                          ),
                        ],
                      ),
                    // Divider
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      endIndent: 0,
                      indent: 0,
                      color: context.color.borderColor,
                    ),
                    // Price & Type
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPrice(context, price, isRent),
                        SellRentLabel(
                          propertyType: isRent ? 'rent' : 'sell',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrice(BuildContext context, String price, bool isRent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomText(
          price + (isRent ? ' /' : ''),
          fontWeight: FontWeight.w600,
          fontSize: context.font.md,
          color: context.color.tertiaryColor,
        ),
        if (isRent) ...[
          const SizedBox(width: 4),
          CustomText(
            agentPropertiesData.rentduration.translate(context),
            fontWeight: FontWeight.w600,
            fontSize: context.font.xs,
            color: context.color.tertiaryColor,
          ),
        ],
      ],
    );
  }

  Future<void> _navigateToPropertyDetails(
    BuildContext context,
    int propertyId,
    bool isMyProperty,
  ) async {
    final fetch = PropertyRepository();
    final dataOutput = await fetch.fetchPropertyFromPropertyId(
      id: propertyId,
      isMyProperty: isMyProperty,
    );

    Widgets.hideLoder(context);

    Future.delayed(
      Duration.zero,
      () {
        HelperUtils.goToNextPage(
          Routes.propertyDetails,
          context,
          false,
          args: {
            'propertyData': dataOutput,
          },
        );
      },
    );
  }
}

class StatusButton {
  StatusButton({
    required this.lable,
    required this.color,
    this.textColor,
  });

  final String lable;
  final Color color;
  final Color? textColor;
}
