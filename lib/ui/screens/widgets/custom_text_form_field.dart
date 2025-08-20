import 'package:perfectshelter/utils/Extensions/extensions.dart';
import 'package:perfectshelter/utils/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CustomTextFieldValidator {
  nullCheck,
  phoneNumber,
  email,
  password,
  maxFifty,
  link,
  slugId
}

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    this.hintText,
    this.controller,
    this.minLine,
    this.maxLine,
    this.formaters,
    this.isReadOnly,
    this.validator,
    this.fillColor,
    this.onChange,
    this.prefix,
    this.keyboard,
    this.action,
    this.suffix,
    this.dense,
    this.autovalidate,
    this.textDirection,
    this.isPassword,
    this.borderColor,
  });

  final String? hintText;
  final TextEditingController? controller;
  final int? minLine;
  final int? maxLine;
  final AutovalidateMode? autovalidate;
  final bool? isReadOnly;
  final List<TextInputFormatter>? formaters;
  final CustomTextFieldValidator? validator;
  final Color? fillColor;
  final dynamic Function(dynamic value)? onChange;
  final Widget? prefix;
  final TextInputAction? action;
  final TextInputType? keyboard;
  final Widget? suffix;
  final bool? dense;
  final TextDirection? textDirection;
  final bool? isPassword;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      scrollPadding: EdgeInsets.zero,
      textDirection: textDirection,
      controller: controller,
      textAlign: Directionality.of(context) == TextDirection.rtl
          ? TextAlign.right
          : TextAlign.left,
      obscureText: isPassword ?? false,
      autovalidateMode: autovalidate,
      inputFormatters: formaters,
      textInputAction: action,
      keyboardAppearance: context.color.brightness,
      readOnly: isReadOnly ?? false,
      style: TextStyle(
        fontSize: context.font.md,
        color: context.color.textColorDark,
      ),
      minLines: minLine ?? 1,
      maxLines: maxLine ?? 1,
      onChanged: onChange,
      validator: (String? value) {
        if (validator == CustomTextFieldValidator.slugId) {
          return Validator.validateSlugId(context, value);
        }
        if (validator == CustomTextFieldValidator.nullCheck) {
          return Validator.nullCheckValidator(context, value);
        }
        if (validator == CustomTextFieldValidator.link) {
          if (value?.isNotEmpty ?? false) {
            return Validator.validateUrl(context, value!);
          } else {
            return null;
          }
        }
        if (validator == CustomTextFieldValidator.maxFifty) {
          if ((value ??= '').length > 50) {
            return 'You can enter 50 letters max';
          } else {
            return null;
          }
        }
        if (validator == CustomTextFieldValidator.email) {
          return Validator.validateEmail(context, value);
        }
        if (validator == CustomTextFieldValidator.phoneNumber) {
          return Validator.validatePhoneNumber(context, value);
        }
        if (validator == CustomTextFieldValidator.password) {
          return Validator.validatePassword(context, value);
        }
        return null;
      },
      keyboardType: keyboard,
      decoration: InputDecoration(
        prefixIcon: prefix,
        prefixIconConstraints: const BoxConstraints(minHeight: 5, minWidth: 5),
        suffixIconConstraints: const BoxConstraints(minHeight: 5, minWidth: 5),
        isDense: dense,
        suffixIcon: suffix,
        hintText: hintText,
        contentPadding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        hintStyle: TextStyle(
          color: context.color.textColorDark.withValues(alpha: 0.7),
          fontSize: context.font.sm,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: fillColor ?? context.color.secondaryColor,
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: borderColor ?? context.color.tertiaryColor),
          borderRadius: BorderRadius.circular(4),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: borderColor ?? context.color.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        border: OutlineInputBorder(
          borderSide:
              BorderSide(color: borderColor ?? context.color.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
