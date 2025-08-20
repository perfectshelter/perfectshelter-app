import 'package:perfectshelter/data/model/subscription_pacakage_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/subscription/widget/package_tile.dart';
import 'package:perfectshelter/utils/price_format.dart';
import 'package:flutter/material.dart';

class CurrentPackageTileCard extends StatelessWidget {
  const CurrentPackageTileCard({
    required this.package,
    required this.allFeatures, // Add this parameter
    super.key,
  });
  final ActivePackage package;
  final List<AllFeature> allFeatures; // Store all available features

  @override
  Widget build(BuildContext context) {
    final isListingNotAvailable =
        _getFeatureById(1) == null && _getFeatureById(2) == null;
    final isFeaturedAdNotAvailable =
        _getFeatureById(3) == null && _getFeatureById(4) == null;
    final isOtherFeaturesNotAvailable = _getFeatureById(5) == null &&
        _getFeatureById(6) == null &&
        _getFeatureById(7) == null;

    return Column(
      children: [
        // Header with package name and price
        _buildHeader(context),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            border: Border(
              bottom: BorderSide(
                color: context.color.borderColor,
              ),
              left: BorderSide(
                color: context.color.borderColor,
              ),
              right: BorderSide(
                color: context.color.borderColor,
              ),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            children: [
              // Feature categories
              if (isListingNotAvailable && isFeaturedAdNotAvailable) ...[
                buildPackageFeatures(
                  packageFeatures: package.features,
                  allPackageFeatures: allFeatures,
                  package: package,
                  showNotIncluded: false,
                ),
                _buildDateSection(context),
              ] else if (isOtherFeaturesNotAvailable) ...[
                _buildListingAndFeaturedAdSection(
                    context, isListingNotAvailable, isFeaturedAdNotAvailable),
                _buildDateSection(context),
              ] else ...[
                _buildListingAndFeaturedAdSection(
                    context, isListingNotAvailable, isFeaturedAdNotAvailable),
                _buildDateSection(context),
                _buildSeeMoreButton(context),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListingAndFeaturedAdSection(BuildContext context,
      bool isListingNotAvailable, bool isFeaturedAdNotAvailable) {
    return Column(
      children: [
        if (!isListingNotAvailable)
          _buildFeatureCategory(
            context,
            title: 'listing'.translate(context),
            icon: AppIcons.listingFeature,
            featureIds: [1, 2], // Property and Project Listing
          ),
        if (isListingNotAvailable || isFeaturedAdNotAvailable)
          ...[]
        else ...[
          UiUtils.getDivider(context),
          const SizedBox(height: 12),
        ],
        if (!isFeaturedAdNotAvailable)
          _buildFeatureCategory(
            context,
            title: 'featuredAd'.translate(context),
            icon: AppIcons.advertisementFeature,
            featureIds: [3, 4], // Property and Project Featured Ad
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 48.rh(context),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: context.color.tertiaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: CustomText(
              package.translatedName ?? package.name,
              fontSize: context.font.lg,
              maxLines: 7,
              fontWeight: FontWeight.w600,
              color: context.color.buttonColor,
            ),
          ),
          if (package.price != 0)
            CustomText(
              package.price.toString().priceFormat(context: context),
              fontSize: context.font.lg,
              fontWeight: FontWeight.w700,
              color: context.color.buttonColor,
            ),
          if (package.price == 0)
            CustomText(
              'free'.translate(context),
              fontSize: context.font.lg,
              fontWeight: FontWeight.w700,
              color: context.color.buttonColor,
            ),
          Container(
            height: 16,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: context.color.buttonColor.withValues(alpha: 0.5),
          ),
          CustomText(
            '${getDuration(duration: package.duration, context: context)} ${'days'.translate(context)}',
            fontSize: context.font.sm,
            fontWeight: FontWeight.w400,
            color: context.color.buttonColor.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }

  String getDuration({required int duration, required BuildContext context}) {
    final days = duration ~/ 24;
    return '$days';
  }

  // Modified method to find features by ID or create placeholder if not found
  ActivePackageFeature? _getFeatureById(int id) {
    try {
      return package.features.firstWhere((feature) => feature.id == id);
    } on Exception catch (_) {
      // Feature not included in active package
      return null;
    }
  }

  Widget _buildFeatureCategory(
    BuildContext context, {
    required String title,
    required String icon,
    required List<int> featureIds,
  }) {
    // Get property and project features (could be null if not available)
    final propertyFeature = _getFeatureById(featureIds[0]);
    final projectFeature = _getFeatureById(featureIds[1]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category title with icon
          Row(
            children: [
              CustomImage(
                imageUrl: icon,
              ),
              const SizedBox(width: 12),
              CustomText(
                title,
                fontSize: context.font.sm,
                fontWeight: FontWeight.w700,
                color: context.color.inverseSurface,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Properties and Projects in two columns
          Row(
            children: [
              // Properties column
              Expanded(
                child: _buildProgressItem(
                  context,
                  isIncluded: propertyFeature != null,
                  isUnlimited: propertyFeature?.limitType ==
                      AdvertisementLimit.unlimited,
                  label: 'properties'.translate(context),
                  usedLimit: propertyFeature?.usedLimit ?? 0,
                  totalLimit: propertyFeature?.totalLimit ?? 0,
                ),
              ),

              const SizedBox(width: 24),

              // Projects column
              Expanded(
                child: _buildProgressItem(
                  context,
                  isIncluded: projectFeature != null,
                  isUnlimited:
                      projectFeature?.limitType == AdvertisementLimit.unlimited,
                  label: 'projects'.translate(context),
                  usedLimit: projectFeature?.usedLimit ?? 0,
                  totalLimit: projectFeature?.totalLimit ?? 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context, {
    required bool isIncluded, // Add this parameter
    required bool isUnlimited,
    required String label,
    required int usedLimit,
    required int totalLimit,
  }) {
    // Calculate progress
    var progress = 0.0;
    if (isIncluded && totalLimit > 0) {
      progress = usedLimit / totalLimit;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: context.font.sm,
          fontWeight: FontWeight.w600,
          color: context.color.inverseSurface,
        ),
        const SizedBox(height: 8),
        if (!isIncluded) ...[
          // Feature not included
          CustomText(
            'notIncluded'.translate(context),
            fontSize: context.font.md,
            fontWeight: FontWeight.w700,
            color: context.color.tertiaryColor,
          ),
        ] else if (isUnlimited) ...[
          // Unlimited feature
          CustomText(
            'unlimited'.translate(context),
            fontSize: context.font.md,
            fontWeight: FontWeight.w700,
            color: context.color.tertiaryColor,
          ),
        ] else ...[
          // Limited feature with progress bar
          Row(
            children: [
              CustomText(
                '$usedLimit',
                fontSize: context.font.sm,
                fontWeight: FontWeight.w500,
                color: context.color.inverseSurface,
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.color.tertiaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              CustomText(
                '$totalLimit',
                fontSize: context.font.sm,
                fontWeight: FontWeight.w500,
                color: context.color.inverseSurface,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDateSection(BuildContext context) {
    // Parse dates
    final startDate = package.startDate;
    final endDate = package.endDate;

    final timeLeft = calculateRemainingTime(endDate, context);

    // Format dates
    final startDateFormatted = startDate.toString().formatDate();
    final endDateFormatted = endDate.toString().formatDate();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.color.tertiaryColor
            .withValues(alpha: 0.1), // Light gray background
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'startedOn'.translate(context),
                    fontSize: context.font.xs,
                    color: context.color.inverseSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    startDateFormatted,
                    fontSize: context.font.xs,
                    fontWeight: FontWeight.w600,
                    color: context.color.inverseSurface,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    'willEndOn'.translate(context),
                    fontSize: context.font.xs,
                    color: context.color.inverseSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    endDateFormatted,
                    fontSize: context.font.xs,
                    fontWeight: FontWeight.w600,
                    color: context.color.inverseSurface,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          MySeparator(
            color: context.color.tertiaryColor,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time_rounded,
                color: context.color.tertiaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              CustomText(
                timeLeft,
                fontSize: context.font.sm,
                underlineOrLineColor: context.color.tertiaryColor,
                fontWeight: FontWeight.w500,
                color: context.color.tertiaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeeMoreButton(BuildContext context) {
    return ExpansionTile(
      title: CustomText('seeMoreBenefits'.translate(context)),
      tilePadding: EdgeInsets.zero,
      dense: true,
      childrenPadding: EdgeInsets.zero,
      iconColor: context.color.tertiaryColor,
      textColor: context.color.inverseSurface,
      collapsedIconColor: context.color.tertiaryColor,
      collapsedTextColor: context.color.inverseSurface,
      shape: const Border(),
      children: [
        buildPackageFeatures(
          packageFeatures: package.features,
          allPackageFeatures: allFeatures, // Use the passed-in allFeatures
          package: package,
          showNotIncluded: true,
        ),
      ],
    );
  }

  Widget buildPackageFeatures({
    required List<AllFeature> allPackageFeatures,
    required List<ActivePackageFeature> packageFeatures,
    required ActivePackage package,
    required bool showNotIncluded,
  }) {
    final packageFeaturesIds = packageFeatures.map((e) => e.id).toList();

    // Filter to only include features with IDs 5, 6, and 7
    var filteredFeatures = allPackageFeatures
        .where(
          (feature) => [5, 6, 7].contains(feature.id),
        )
        .toList();

    // If showNotIncluded is false, only show included features
    if (!showNotIncluded) {
      filteredFeatures = filteredFeatures
          .where((feature) => packageFeaturesIds.contains(feature.id))
          .toList();
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 12),
      separatorBuilder: (context, index) {
        return const SizedBox(height: 8);
      },
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredFeatures.length,
      itemBuilder: (context, index) {
        final packageFeature = filteredFeatures[index];
        final isFeatured = packageFeaturesIds.contains(packageFeature.id);

        // Get the limit type for the current feature if it's included
        var limitText = 'notIncluded'.translate(context);
        if (isFeatured) {
          final feature = packageFeatures.firstWhere(
            (f) => f.id == packageFeature.id,
            orElse: () => packageFeatures.first, // Fallback in case not found
          );
          limitText = feature.limitType == AdvertisementLimit.unlimited
              ? AdvertisementLimit.unlimited.name.translate(context)
              : '${feature.usedLimit ?? 0}/${feature.totalLimit ?? 0}';
        }

        return Row(
          children: [
            CustomImage(
              imageUrl: isFeatured
                  ? AppIcons.featureAvailable
                  : AppIcons.featureNotAvailable,
              height: 20.rh(context),
              width: 20.rw(context),
            ),
            const SizedBox(
              width: 8,
            ),
            CustomText(
              '${packageFeature.translatedName ?? packageFeature.name}: $limitText',
              fontSize: context.font.xs,
              color: context.color.textColorDark,
              fontWeight: FontWeight.w500,
            ),
          ],
        );
      },
    );
  }

  String calculateRemainingTime(
    DateTime endDate,
    BuildContext context,
  ) {
    final now = DateTime.now();
    final end = endDate;
    final timeDiff = end.difference(now).inMilliseconds;

    if (timeDiff <= 0) {
      return "${"no".translate(context)} ${"timeLeft".translate(context)}";
    }
    //If duration is in minutes (less than 60 minutes)
    if (timeDiff < (1000 * 60 * 60)) {
      final remainingMinutes = (timeDiff / (1000 * 60)).ceil();
      return "$remainingMinutes ${"minutesLeft".translate(context)}";
    }
    // If duration is in hours (less than 24 hours)
    if (timeDiff < (1000 * 60 * 60 * 24)) {
      final remainingHours = (timeDiff / (1000 * 60 * 60)).ceil();
      return "$remainingHours ${"hoursLeft".translate(context)}";
    }

    // Otherwise, calculate remaining days
    final remainingDays = (timeDiff / (1000 * 60 * 60 * 24)).ceil();
    return "$remainingDays ${"daysLeft".translate(context)}";
  }
}
