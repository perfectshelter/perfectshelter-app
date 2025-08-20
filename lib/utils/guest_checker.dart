import 'dart:developer';

import 'package:perfectshelter/app/routes.dart';
import 'package:perfectshelter/utils/Extensions/extensions.dart';
import 'package:perfectshelter/utils/extensions/lib/custom_text.dart';
import 'package:perfectshelter/utils/hive_utils.dart';
import 'package:flutter/material.dart';

class GuestChecker {
  static final ValueNotifier<bool?> _isGuest =
      ValueNotifier(HiveUtils.isGuest());
  static BuildContext? _context;

  static void set(String from, {required bool isGuest}) {
    _isGuest.value = isGuest;
  }

  static void setContext(BuildContext context) {
    _context = context;
  }

  static Future<void> check({required dynamic Function() onNotGuest}) async {
    if (_context == null) {
      log('please set context');
    }

    if (_isGuest.value ?? false) {
      _loginBox();
    } else {
      await onNotGuest.call();
    }
  }

  static bool get value {
    return _isGuest.value ?? false;
  }

  static ValueNotifier<bool?> listen() {
    return _isGuest;
  }

  static Widget updateUI({
    required dynamic Function({bool? isGuest}) onChangeStatus,
  }) {
    return ValueListenableBuilder<bool?>(
      valueListenable: _isGuest,
      builder: (context, value, c) {
        return onChangeStatus.call(isGuest: value) as Widget? ??
            const SizedBox.shrink();
      },
    );
  }

  static void _loginBox() {
    showModalBottomSheet<dynamic>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      context: _context!,
      backgroundColor: _context?.color.secondaryColor,
      enableDrag: false,
      builder: (context) {
        return Container(
          width: context.screenWidth,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'loginIsRequired'.translate(context),
                fontSize: context.font.lg,
              ),
              const SizedBox(
                height: 5,
              ),
              CustomText(
                'tapOnLogin'.translate(context),
                fontSize: context.font.xs,
              ),
              const SizedBox(
                height: 10,
              ),
              MaterialButton(
                elevation: 0,
                color: _context?.color.tertiaryColor,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    Routes.login,
                    arguments: {'popToCurrent': true},
                  );
                },
                child: CustomText(
                  'loginNow'.translate(context),
                  color: _context?.color.buttonColor ?? Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
