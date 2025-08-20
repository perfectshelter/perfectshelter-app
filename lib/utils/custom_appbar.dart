import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.bottom,
    this.bottomHeight = 52,
    this.actions,
    this.isTransparent = false,
    this.onTapBackButton,
    this.showBackButton = true,
    this.backgroundColor,
    this.showShadow = true,
  });

  final Widget? title;
  final Widget? bottom;
  final VoidCallback? onTapBackButton;
  final List<Widget>? actions;
  final bool showShadow;
  final bool isTransparent;
  final double bottomHeight;
  final bool showBackButton;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: UiUtils.getSystemUiOverlayStyle(context: context),
      scrolledUnderElevation: 1.5,
      leadingWidth: showBackButton ? 56.rw(context) : context.screenWidth,
      forceMaterialTransparency: isTransparent,
      shadowColor: showShadow
          ? context.color.inverseSurface.withValues(alpha: .8)
          : null,
      automaticallyImplyLeading: false,
      surfaceTintColor: Colors.transparent,
      elevation: isTransparent ? 0 : 1.5,
      centerTitle: false,
      backgroundColor: backgroundColor ??
          (isTransparent ? null : context.color.secondaryColor),
      leading: showBackButton ? _buildBackButton(context) : null,
      titleSpacing: showBackButton ? 0 : 16.rw(context),
      titleTextStyle: TextStyle(
        color: context.color.textColorDark,
        fontWeight: FontWeight.w400,
        fontSize: 22,
      ),
      title: title,
      actions: actions,
      actionsPadding: EdgeInsetsDirectional.only(end: 16.rw(context)),
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: Size.fromHeight(bottomHeight),
              child: Container(
                child: bottom,
              ),
            )
          : null,
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTapBackButton?.call();
        Navigator.pop(context);
      },
      child: Container(
        alignment: Alignment.center,
        child: Transform.flip(
          flipX: Directionality.of(context) == TextDirection.rtl,
          child: CustomImage(
            imageUrl: AppIcons.arrowLeft,
            width: 24.rh(context),
            height: 24.rh(context),
            color: context.color.textColorDark,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => bottom == null
      ? const Size.fromHeight(kToolbarHeight)
      : Size.fromHeight(kToolbarHeight + bottomHeight);
}
