import 'package:perfectshelter/utils/Extensions/extensions.dart';
import 'package:perfectshelter/utils/app_icons.dart';
import 'package:perfectshelter/utils/custom_image.dart';
import 'package:perfectshelter/utils/extensions/lib/custom_text.dart';
import 'package:perfectshelter/utils/responsive_size.dart';
import 'package:perfectshelter/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class PromotedCard extends StatelessWidget {
  const PromotedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.color.inverseThemeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          CustomImage(
            imageUrl: AppIcons.featuredBolt,
            color: context.color.buttonColor,
            width: 16.rw(context),
            height: 16.rh(context),
          ),
          const SizedBox(width: 4),
          CustomText(
            UiUtils.translate(context, 'featured'),
            fontWeight: FontWeight.bold,
            color: context.color.buttonColor,
            fontSize: context.font.xs,
          ),
        ],
      ),
    );
  }
}
