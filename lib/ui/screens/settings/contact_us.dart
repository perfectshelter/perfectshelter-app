import 'dart:developer';

import 'package:perfectshelter/exports/main_export.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUs extends StatefulWidget {
  const ContactUs({super.key});

  @override
  ContactUsState createState() => ContactUsState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const ContactUs());
  }
}

class ContactUsState extends State<ContactUs> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () {
        if (context.read<CompanyCubit>().state is CompanyInitial ||
            context.read<CompanyCubit>().state is CompanyFetchFailure) {
          context.read<CompanyCubit>().fetchCompany();
        } else {
          // print("companyData Fetched already !! ");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: CustomAppBar(
        title: CustomText(UiUtils.translate(context, 'contactUs')),
      ),
      body: BlocBuilder<CompanyCubit, CompanyState>(
        builder: (context, state) {
          if (state is CompanyFetchProgress) {
            return Center(
              child: UiUtils.progress(),
            );
          } else if (state is CompanyFetchSuccess) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    UiUtils.translate(context, 'howCanWeHelp'),
                    fontWeight: FontWeight.w500,
                    fontSize: context.font.md,
                    color: context.color.textColorDark,
                  ),
                  SizedBox(height: 8.rh(context)),
                  CustomText(
                    UiUtils.translate(context, 'itLooksLikeYouHasError'),
                    fontSize: context.font.sm,
                    fontWeight: FontWeight.w400,
                    color: context.color.textLightColor,
                  ),
                  SizedBox(height: 24.rh(context)),
                  customTile(
                    context,
                    title: UiUtils.translate(context, 'callBtnLbl'),
                    onTap: () async {
                      final number1 = state.companyData.companyTel1 ?? '';
                      final number2 = state.companyData.companyTel2 ?? '';

                      await UiUtils.showBlurredDialoge(
                        context,
                        dialog: BlurredDialogBox(
                          title: 'chooseNumber'.translate(context),
                          showCancleButton: false,
                          titleSize: context.font.lg,
                          titleWeight: FontWeight.w600,
                          barrierDismissable: true,
                          acceptTextColor: context.color.buttonColor,
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await launchUrl(Uri.parse('tel:$number1'));
                                },
                                child: Container(
                                  height: 32.rh(context),
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: context.color.secondaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: context.color.borderColor,
                                    ),
                                  ),
                                  child: CustomText(
                                    number1,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              if (number2.isNotEmpty) ...[
                                SizedBox(height: 16.rh(context)),
                                GestureDetector(
                                  onTap: () async {
                                    await launchUrl(Uri.parse('tel:$number2'));
                                  },
                                  child: Container(
                                    height: 32.rh(context),
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: context.color.secondaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: context.color.borderColor,
                                      ),
                                    ),
                                    child: CustomText(
                                      number2,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    svgImagePath: AppIcons.callFilled,
                  ),
                  SizedBox(height: 16.rh(context)),
                  customTile(
                    context,
                    title: UiUtils.translate(context, 'email'),
                    onTap: () {
                      final email = state.companyData.companyEmail;
                      showEmailDialoge(email);
                    },
                    svgImagePath: AppIcons.message,
                  ),
                ],
              ),
            );
          } else if (state is CompanyFetchFailure) {
            log('error iii ${state.error}');
            return Center(
              child: CustomText(state.error?.toString() ?? ''),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  void showEmailDialoge(dynamic email) {
    showDialog<dynamic>(
      context: context,
      builder: (context) => EmailSendWidget(email: email?.toString() ?? ''),
    );
  }

  Widget customTile(
    BuildContext context, {
    required String title,
    required String svgImagePath,
    required VoidCallback onTap,
    bool? isSwitchBox,
    dynamic Function(dynamic value)? onTapSwitch,
    dynamic switchValue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52.rh(context),
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.color.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36.rw(context),
              height: 36.rh(context),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.color.textColorDark.withValues(alpha: 0.1),
                border: Border.all(color: context.color.textColorDark),
                borderRadius: BorderRadius.circular(4),
              ),
              child: CustomImage(
                imageUrl: svgImagePath,
                color: context.color.textColorDark,
              ),
            ),
            SizedBox(
              width: 19.rw(context),
            ),
            CustomText(
              title,
              fontWeight: FontWeight.w400,
              fontSize: context.font.sm,
              color: context.color.textColorDark,
            ),
            const Spacer(),
            if (isSwitchBox != true)
              CustomImage(
                imageUrl: AppIcons.arrowRight,
                matchTextDirection: true,
                color: context.color.textColorDark,
              ),
            if (isSwitchBox ?? false)
              Switch(
                value: switchValue as bool? ?? false,
                onChanged: (value) {
                  onTapSwitch?.call(value);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> launchPathURL(dynamic isTel, String value) async {
    late Uri redirectUri;
    if (isTel as bool? ?? false) {
      redirectUri = Uri.parse('tel: $value');
    } else {
      redirectUri = Uri(
        scheme: 'mailto',
        path: value,
        query:
            'subject=${Constant.appName}&body=${UiUtils.translate(context, "mailMsgLbl")}',
      );
    }

    if (await canLaunchUrl(redirectUri)) {
      await launchUrl(redirectUri);
    } else {
      log('Could not launch $redirectUri');
    }
  }
}

class EmailSendWidget extends StatefulWidget {
  const EmailSendWidget({
    required this.email,
    super.key,
  });
  final String email;

  @override
  State<EmailSendWidget> createState() => _EmailSendWidgetState();
}

class _EmailSendWidgetState extends State<EmailSendWidget> {
  final TextEditingController _subject = TextEditingController();
  late final TextEditingController _email =
      TextEditingController(text: widget.email);
  final TextEditingController _text = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.secondaryColor.withValues(alpha: 0.1),
      body: Center(
        child: Container(
          clipBehavior: Clip.antiAlias,
          width: 277.rw(context),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              physics: Constant.scrollPhysics,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomText(
                        UiUtils.translate(context, 'sendEmail'),
                        fontSize: context.font.md,
                        fontWeight: FontWeight.w500,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(
                            context,
                          );
                        },
                        child: SizedBox(
                          width: 24.rw(context),
                          height: 24.rh(context),
                          child: CustomImage(
                            imageUrl: AppIcons.closeCircle,
                            matchTextDirection: true,
                            color: context.color.textColorDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.rh(context)),
                  CustomTextFormField(
                    controller: _subject,
                    hintText: UiUtils.translate(context, 'subject'),
                  ),
                  SizedBox(height: 16.rh(context)),
                  CustomTextFormField(
                    controller: _email,
                    isReadOnly: true,
                    hintText: UiUtils.translate(context, 'email'),
                  ),
                  SizedBox(height: 16.rh(context)),
                  CustomTextFormField(
                    controller: _text,
                    maxLine: 100,
                    hintText: UiUtils.translate(context, 'writeSomething'),
                    minLine: 5,
                  ),
                  SizedBox(height: 16.rh(context)),
                  UiUtils.buildButton(
                    context,
                    onPressed: () async {
                      final redirecturi = Uri(
                        scheme: 'mailto',
                        path: _email.text,
                        query: 'subject=${_subject.text}&body=${_text.text}',
                      );
                      await launchUrl(redirecturi);
                    },
                    height: 40.rh(context),
                    buttonTitle: UiUtils.translate(context, 'ok'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
