import 'package:ebroker/utils/Extensions/extensions.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/extensions/lib/custom_text.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SomethingWentWrong extends StatelessWidget {
  const SomethingWentWrong({super.key, this.error});
  final FlutterErrorDetails? error;

  static void asGlobalErrorBuilder() {
    if (kReleaseMode) {
      ErrorWidget.builder =
          (FlutterErrorDetails flutterErrorDetails) => SomethingWentWrong(
                error: flutterErrorDetails,
              );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: CustomImage(
            imageUrl: AppIcons.somethingWentWrong,
            width: 280.rw(context),
          ),
        ),
        SizedBox(
          height: 12.rh(context),
        ),
        CustomText(
          '${'somethingWentWrng'.translate(context)} !',
          fontWeight: FontWeight.bold,
          fontSize: context.font.lg,
        ),
      ],
    );
  }
}
