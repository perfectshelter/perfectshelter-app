import 'package:ebroker/utils/Extensions/extensions.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/extensions/lib/custom_text.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter/material.dart';

class NoDataFound extends StatelessWidget {
  const NoDataFound({
    super.key,
    this.onTap,
    this.height,
    this.title,
    this.description,
  });

  final double? height;
  final VoidCallback? onTap;
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            child: CustomImage(
              imageUrl: AppIcons.noDataFound,
              height: height ?? MediaQuery.of(context).size.height * 0.35,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          CustomText(
            title ?? 'nodatafound'.translate(context),
            fontWeight: FontWeight.w600,
            fontSize: context.font.xl,
            textAlign: TextAlign.center,
            color: context.color.tertiaryColor,
          ),
          const SizedBox(
            height: 14,
          ),
          CustomText(
            description ?? 'sorryLookingFor'.translate(context),
            textAlign: TextAlign.center,
            fontSize: context.font.md,
          ),
          const SizedBox(
            height: 14,
          ),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: SizedBox(
                height: 50.rh(context),
                child: Center(
                  child: CustomText(
                    'retry'.translate(context),
                    fontWeight: FontWeight.bold,
                    fontSize: context.font.xs,
                    textAlign: TextAlign.center,
                    color: context.color.tertiaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
