import 'package:perfectshelter/app/routes.dart';
import 'package:perfectshelter/ui/screens/home/home_screen.dart';
import 'package:perfectshelter/utils/Extensions/extensions.dart';
import 'package:perfectshelter/utils/app_icons.dart';
import 'package:perfectshelter/utils/custom_image.dart';
import 'package:perfectshelter/utils/responsive_size.dart';
import 'package:perfectshelter/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 8, right: sidePadding, left: sidePadding),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routes.searchScreenRoute,
                  arguments: {'autoFocus': true},
                );
              },
              child: AbsorbPointer(
                child: Container(
                  width: MediaQuery.of(context).size.width -
                      (sidePadding * 2) -
                      50.rw(context) -
                      16,
                  height: 50.rh(context),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.color.borderColor,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    color: context.color.secondaryColor,
                  ),
                  child: TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: InputBorder.none, //OutlineInputBorder()
                      fillColor: Theme.of(context).colorScheme.secondaryColor,
                      hintText: UiUtils.translate(context, 'searchHintLbl'),
                      hintStyle: TextStyle(
                        color: context.color.textLightColor,
                        fontSize: context.font.sm,
                      ),
                      alignLabelWithHint: true,
                      prefixIcon: buildSearchIcon(context),
                      prefixIconConstraints: BoxConstraints(
                          minHeight: 24.rh(context), minWidth: 24.rw(context)),
                    ),
                    onEditingComplete: () {
                      FocusScope.of(context).unfocus();
                    },
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.rw(context)),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, Routes.propertyMapScreen);
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              width: 50.rw(context),
              height: 50.rh(context),
              decoration: BoxDecoration(
                border: Border.all(color: context.color.borderColor),
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomImage(
                imageUrl: AppIcons.propertyMap,
                color: context.color.tertiaryColor,
                width: 24.rw(context),
                height: 24.rh(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchIcon(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CustomImage(
        imageUrl: AppIcons.search,
        width: 24.rw(context),
        height: 24.rh(context),
        color: context.color.tertiaryColor,
      ),
    );
  }
}
