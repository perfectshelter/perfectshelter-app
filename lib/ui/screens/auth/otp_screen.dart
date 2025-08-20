import 'package:ebroker/data/repositories/auth_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    required this.isDeleteAccount,
    required this.isEmailSelected,
    super.key,
    this.phoneNumber,
    this.email,
    this.password,
    this.otpVerificationId,
    this.countryCode,
    this.otpIs,
  });

  final bool isDeleteAccount;

  final bool isEmailSelected;
  final String? phoneNumber;
  final String? email;
  final String? password;
  final String? otpVerificationId;
  final String? countryCode;
  final String? otpIs;

  @override
  State<OtpScreen> createState() => _OtpScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments! as Map;
    return CupertinoPageRoute(
      builder: (_) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => SendOtpCubit()),
            BlocProvider(create: (context) => VerifyOtpCubit()),
          ],
          child: OtpScreen(
            isDeleteAccount: arguments['isDeleteAccount'] as bool? ?? false,
            phoneNumber: arguments['phoneNumber']?.toString() ?? '',
            email: arguments['email']?.toString() ?? '',
            otpVerificationId: arguments['otpVerificationId']?.toString() ?? '',
            countryCode: arguments['countryCode']?.toString() ?? '',
            otpIs: arguments['otpIs']?.toString() ?? '',
            isEmailSelected: arguments['isEmailSelected'] as bool? ?? false,
          ),
        );
      },
    );
  }
}

class _OtpScreenState extends State<OtpScreen> {
  Timer? timer;
  ValueNotifier<int> otpResendTime = ValueNotifier<int>(
    Constant.otpResendSecond,
  );
  final TextEditingController phoneOtpController = TextEditingController();
  final TextEditingController emailOtpController = TextEditingController();
  int otpLength = 6;
  bool isOtpAutoFilled = false;
  final List<FocusNode> _focusNodes = [];
  int focusIndex = 0;
  String otpIs = '';

  @override
  void initState() {
    // otpResendTime = ValueNotifier<int>(
    //   widget.isEmailSelected
    //       ? Constant.otpResendSecondForEmail
    //       : Constant.otpResendSecond,
    // );
    otpIs = widget.otpIs ?? '';
    super.initState();
    if (timer != null) {
      timer!.cancel();
    }
    startTimer();
  }

  @override
  void dispose() {
    for (final fNode in _focusNodes) {
      fNode.dispose();
    }
    otpResendTime.dispose();
    phoneOtpController.dispose();
    emailOtpController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VerifyOtpCubit, VerifyOtpState>(
      listener: (context, state) {
        if (state is VerifyOtpInProgress) {
          Widgets.showLoader(context);
        } else {
          Widgets.hideLoder(context);
        }
        if (state is VerifyOtpFailure) {
          Widgets.hideLoder(context);
          HelperUtils.showSnackBarMessage(
            context,
            state.errorMessage,
            type: MessageType.error,
          );
        }

        if (state is VerifyOtpSuccess) {
          Widgets.hideLoder(context);
          if (widget.isEmailSelected) {
            Navigator.of(context).pushReplacementNamed(
              Routes.login,
              arguments: {
                'isDeleteAccount': widget.isDeleteAccount,
              },
            );
            HelperUtils.showSnackBarMessage(
              context,
              'otpVerifiedSuccessfully'.translate(context),
              type: MessageType.success,
            );
          }
          if (widget.isDeleteAccount) {
            context.read<DeleteAccountCubit>().deleteUserAccount(
                  context,
                );
          } else if (AppSettings.otpServiceProvider == 'firebase') {
            context.read<LoginCubit>().login(
                  type: LoginType.phone,
                  phoneNumber: widget.phoneNumber ??
                      state.credential!.user!.phoneNumber?.toString() ??
                      '',
                  uniqueId: state.credential!.user!.uid?.toString() ?? '',
                  countryCode: widget.countryCode ?? '',
                );
          } else if (AppSettings.otpServiceProvider == 'twilio') {
            context.read<LoginCubit>().login(
                  type: LoginType.phone,
                  phoneNumber: widget.phoneNumber ?? '',
                  uniqueId: state.authId!,
                  countryCode: widget.countryCode ?? '',
                );
          }
        }
      },
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: CustomAppBar(
          title: CustomText(UiUtils.translate(context, 'enterCodeSend')),
        ),
        body: otpScreenContainer(context),
      ),
    );
  }

  Widget otpScreenContainer(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Header message and contact info
          _buildHeaderSection(context),

          SizedBox(height: 20.rh(context)),

          // OTP input field
          _buildOtpField(context),

          // Login button
          loginButton(context),

          // Timer widget
          SizedBox(child: resendOtpTimerWidget()),

          // Resend button (only show when timer is not active)
          if (!(timer?.isActive ?? false)) _buildResendButton(context),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final isEmail = widget.isEmailSelected;
    final messageKey = isEmail ? 'weSentCodeOnEmail' : 'weSentCodeOnNumber';
    final contactInfo = _getContactInfo();

    return Column(
      children: [
        CustomText(
          UiUtils.translate(context, messageKey),
          fontSize: context.font.md,
          color: context.color.textColorDark.withValues(alpha: 0.8),
        ),
        CustomText(
          contactInfo,
          fontSize: context.font.md,
          color: context.color.textColorDark.withValues(alpha: 0.8),
        ),
      ],
    );
  }

  String _getContactInfo() {
    if (widget.isEmailSelected) {
      return widget.isDeleteAccount
          ? HiveUtils.getUserDetails().email ?? ''
          : widget.email ?? '';
    } else {
      final countryCode = widget.countryCode;
      final phoneNumber = widget.isDeleteAccount
          ? HiveUtils.getUserDetails().mobile
          : widget.phoneNumber;
      return '+$countryCode $phoneNumber';
    }
  }

  Widget _buildOtpField(BuildContext context) {
    final controller =
        widget.isEmailSelected ? emailOtpController : phoneOtpController;

    return PinFieldAutoFill(
      autoFocus: true,
      controller: controller,
      decoration: UnderlineDecoration(
        textStyle: TextStyle(
          color: context.color.textColorDark.withValues(alpha: 0.8),
          fontSize: context.font.xl,
        ),
        lineHeight: 1.5,
        colorBuilder: PinListenColorBuilder(
          context.color.tertiaryColor,
          Colors.grey,
        ),
      ),
      currentCode: demoOTP(),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      keyboardType: Platform.isIOS
          ? const TextInputType.numberWithOptions(signed: true)
          : TextInputType.number,
      onCodeSubmitted: (code) => _handleOtpSubmission(context, code),
      onCodeChanged: (code) {
        if (code?.length == 6) {
          otpIs = code!;
        }
      },
    );
  }

  void _handleOtpSubmission(BuildContext context, String code) {
    if (widget.isEmailSelected) {
      context.read<VerifyOtpCubit>().verifyEmailOTP(
            otp: code,
            email: widget.email ?? '',
          );
    } else {
      _handlePhoneOtpSubmission(context, code);
    }
  }

  void _handlePhoneOtpSubmission(BuildContext context, String code) {
    final cubit = context.read<VerifyOtpCubit>();

    switch (AppSettings.otpServiceProvider) {
      case 'firebase':
        final verificationId =
            widget.isDeleteAccount ? verificationID : widget.otpVerificationId;
        cubit.verifyOTP(verificationId: verificationId, otp: code);

      case 'twilio':
        cubit.verifyOTP(
          otp: widget.otpIs ?? '',
          number: widget.phoneNumber,
          countryCode: widget.countryCode,
        );
    }
  }

  Widget _buildResendButton(BuildContext context) {
    return SizedBox(
      height: 70,
      child: IgnorePointer(
        ignoring: timer?.isActive ?? false,
        child: TextButton(
          onPressed: resendOTP,
          child: CustomText(
            UiUtils.translate(context, 'resendCodeBtnLbl'),
            color: (timer?.isActive ?? false)
                ? context.color.textLightColor
                : context.color.tertiaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> startTimer() async {
    timer?.cancel();
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (otpResendTime.value == 0) {
          timer.cancel();
          otpResendTime.value = Constant.otpResendSecond;
          setState(() {});
        } else {
          if (mounted) otpResendTime.value--;
        }
      },
    );
    setState(() {});
  }

  String demoOTP() {
    if (Constant.isDemoModeOn &&
        Constant.demoMobileNumber == widget.phoneNumber) {
      return Constant.demoModeOTP; // If true, return the demo mode OTP.
    } else {
      return ''; // If false, return an empty string.
    }
  }

  Widget resendOtpTimerWidget() {
    return ValueListenableBuilder(
      valueListenable: otpResendTime,
      builder: (context, value, child) {
        if (!(timer?.isActive ?? false)) {
          return const SizedBox.shrink();
        }
        String formatSecondsToMinutes(int seconds) {
          final minutes = seconds ~/ 60;
          final remainingSeconds = seconds % 60;
          return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
        }

        return SizedBox(
          height: 70,
          child: Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                text: "${UiUtils.translate(context, "resendMessage")} ",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.textColorDark,
                  letterSpacing: 0.5,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: formatSecondsToMinutes(int.parse(value.toString())),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiaryColor,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextSpan(
                    text: UiUtils.translate(
                      context,
                      'resendMessageDuration',
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiaryColor,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void resendOTP() {
    if (widget.isEmailSelected) {
      context.read<SendOtpCubit>().resendEmailOTP(
            email: widget.email ?? '',
            password: widget.password ?? '',
          );
      return;
    }
    if (AppSettings.otpServiceProvider == 'firebase') {
      context.read<SendOtpCubit>().sendFirebaseOTP(
            countryCode: widget.countryCode ?? '',
            phoneNumber: widget.phoneNumber ?? '',
          );
    } else if (AppSettings.otpServiceProvider == 'twilio') {
      context.read<SendOtpCubit>().sendTwilioOTP(
            countryCode: widget.countryCode ?? '',
            phoneNumber: widget.phoneNumber ?? '',
          );
    }
  }

  Widget buildButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required String buttonTitle,
    required bool disabled,
    double? height,
    double? width,
  }) {
    return UiUtils.buildButton(
      context,
      height: height ?? 56.rh(context),
      outerPadding: EdgeInsets.only(top: 58.rh(context)),
      disabledColor: context.color.textLightColor,
      onPressed: (disabled != true)
          ? () {
              HelperUtils.unfocus();
              onPressed.call();
            }
          : () {},
      buttonTitle: buttonTitle,
    );
  }

  Widget loginButton(BuildContext context) {
    return buildButton(
      context,
      onPressed: onTapLogin,
      disabled: false,
      width: MediaQuery.of(context).size.width,
      buttonTitle: UiUtils.translate(
        context,
        'comfirmBtnLbl',
      ),
    );
  }

  Future<void> onTapLogin() async {
    if (widget.isEmailSelected) {
      try {
        await context.read<VerifyOtpCubit>().verifyEmailOTP(
              otp: emailOtpController.text,
              email: widget.email ?? '',
            );
        if (context.read<VerifyOtpCubit>().state is VerifyOtpSuccess) {
          await Navigator.pushReplacementNamed(
            context,
            Routes.main,
            arguments: {
              'from': 'login',
            },
          );
        }
        return;
      } on Exception catch (e) {
        await HelperUtils.showSnackBarMessage(
          context,
          e.toString(),
          messageDuration: 1,
        );
        return;
      }
    }
    try {
      if (phoneOtpController.text.isEmpty) {
        await HelperUtils.showSnackBarMessage(
          context,
          UiUtils.translate(context, 'lblEnterOtp'),
          messageDuration: 2,
        );
        return;
      }
      if (AppSettings.otpServiceProvider == 'firebase') {
        if (widget.isDeleteAccount) {
          await context.read<VerifyOtpCubit>().verifyOTP(
                verificationId: verificationID,
                otp: phoneOtpController.text,
              );
        } else {
          await context.read<VerifyOtpCubit>().verifyOTP(
                verificationId: widget.otpVerificationId,
                otp: phoneOtpController.text,
                number: widget.phoneNumber,
                countryCode: widget.countryCode,
              );
        }
      } else if (AppSettings.otpServiceProvider == 'twilio') {
        await context.read<VerifyOtpCubit>().verifyOTP(
              otp: phoneOtpController.text,
              number: widget.phoneNumber,
              countryCode: widget.countryCode,
            );
      }
    } on Exception catch (_) {
      Widgets.hideLoder(context);
      await HelperUtils.showSnackBarMessage(
        context,
        'invalidOtp'.translate(context),
      );
    }
  }
}
