import 'package:country_picker/country_picker.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/auth/country_picker.dart';
import 'package:perfectshelter/utils/validator.dart';
import 'package:flutter/material.dart';

class EmailRegistrationForm extends StatefulWidget {
  const EmailRegistrationForm({required this.email, super.key});

  final String email;

  @override
  State<EmailRegistrationForm> createState() => _EmailRegistrationFormState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments! as Map;
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => SendOtpCubit()),
          BlocProvider(create: (context) => VerifyOtpCubit()),
        ],
        child:
            EmailRegistrationForm(email: arguments['email']?.toString() ?? ''),
      ),
    );
  }
}

class _EmailRegistrationFormState extends State<EmailRegistrationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Timer? timer;
  final ValueNotifier<int> otpResendTime = ValueNotifier<int>(
    Constant.otpResendSecond,
  );

  String countryCode = '';
  String flagEmoji = '';
  bool isFirstPasswordVisible = true;
  bool isSecondPasswordVisible = true;

  @override
  void initState() {
    super.initState();
    HelperUtils.getSimCountry().then((value) {
      countryCode = value.phoneCode;
      flagEmoji = value.flagEmoji;
      setState(() {});
    });

    startTimer();
    emailController.text = widget.email;
  }

  @override
  void dispose() {
    timer?.cancel();
    if (mounted) otpResendTime.dispose();
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SendOtpCubit, SendOtpState>(
      listener: _handleOtpState,
      child: Scaffold(
        extendBody: true,
        backgroundColor: context.color.primaryColor,
        appBar: CustomAppBar(
          title: CustomText('registerEmail'.translate(context)),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: Constant.scrollPhysics,
            child: _buildEmailRegistrationForm(context),
          ),
        ),
      ),
    );
  }

  void _handleOtpState(BuildContext context, SendOtpState state) {
    if (state is SendOtpInProgress) {
      Widgets.showLoader(context);
    } else if (state is SendOtpFailure) {
      Widgets.hideLoder(context);
      HelperUtils.showSnackBarMessage(
        context,
        state.errorMessage,
        type: MessageType.error,
      );
    } else if (state is SendOtpSuccess) {
      Widgets.hideLoder(context);
      Navigator.pushReplacementNamed(
        context,
        Routes.otpScreen,
        arguments: {
          'isDeleteAccount': false,
          'phoneNumber': mobileController.text,
          'email': emailController.text,
          'otpVerificationId': state.verificationId,
          'countryCode': countryCode,
          'otpIs': state.verificationId,
          'isEmailSelected': true,
        },
      );
    }
  }

  Widget _buildEmailRegistrationForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(
              context,
              title: 'fullName'.translate(context),
              controller: nameController,
              validator: CustomTextFieldValidator.nullCheck,
              isPhoneNumber: false,
              hintText: 'fullName'.translate(context),
            ),
            _buildTextField(
              context,
              title: 'email'.translate(context),
              hintText: 'example@email.com',
              validator: CustomTextFieldValidator.email,
              controller: emailController,
              isPhoneNumber: false,
            ),
            _buildTextField(
              context,
              title: 'phoneNumber'.translate(context),
              hintText: '0000000000',
              validator: CustomTextFieldValidator.phoneNumber,
              controller: mobileController,
              keyboard: TextInputType.phone,
              isPhoneNumber: true,
            ),
            _buildPasswordField(
              context,
              title: 'password'.translate(context),
              hintText: 'password'.translate(context),
              validator: (value) => Validator.validatePassword(
                context,
                value?.toString() ?? '',
                secondFieldValue: passwordController.text,
              ),
              controller: passwordController,
              isPasswordVisible: isFirstPasswordVisible,
              onToggleVisibility: () {
                setState(
                    () => isFirstPasswordVisible = !isFirstPasswordVisible);
              },
            ),
            _buildPasswordField(
              context,
              title: 'confirmPassword'.translate(context),
              hintText: 'confirmPassword'.translate(context),
              controller: confirmPasswordController,
              validator: (value) => Validator.validatePassword(
                context,
                value?.toString() ?? '',
                secondFieldValue: passwordController.text,
              ),
              isPasswordVisible: isSecondPasswordVisible,
              onToggleVisibility: () {
                setState(
                    () => isSecondPasswordVisible = !isSecondPasswordVisible);
              },
            ),
            const SizedBox(height: 16),
            UiUtils.buildButton(
              context,
              buttonTitle: 'register'.translate(context),
              onPressed: _handleRegister,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    final checkMobile = mobileController.text.isNotEmpty;
    if (_formKey.currentState!.validate()) {
      await context.read<SendOtpCubit>().sendEmailOTP(
            email: emailController.text,
            name: nameController.text,
            phoneNumber: checkMobile ? mobileController.text : '',
            countryCode: countryCode,
            password: passwordController.text,
            confirmPassword: confirmPasswordController.text,
          );
    } else {
      await HelperUtils.showSnackBarMessage(
        context,
        'pleaseFillAllFields'.translate(context),
      );
    }
  }

  Widget _buildTextField(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required bool isPhoneNumber,
    required String hintText,
    List<TextInputFormatter>? formaters,
    TextInputType? keyboard,
    CustomTextFieldValidator? validator,
    bool? readOnly,
    TextDirection? textDirection,
  }) {
    final requiredSymbol = CustomText(
      '*',
      color: context.color.error,
      fontWeight: FontWeight.w400,
      fontSize: context.font.md,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.rh(context)),
        Row(
          children: [
            CustomText(UiUtils.translate(context, title)),
            const SizedBox(width: 3),
            if (!isPhoneNumber) requiredSymbol,
          ],
        ),
        SizedBox(height: 10.rh(context)),
        CustomTextFormField(
          hintText: hintText,
          textDirection: textDirection,
          controller: controller,
          keyboard: keyboard,
          isReadOnly: readOnly,
          validator: isPhoneNumber ? null : validator,
          prefix: isPhoneNumber
              ? CountryPickerWidget(
                  flagEmoji: flagEmoji,
                  onTap: showCountryCode,
                )
              : null,
          formaters: formaters,
          fillColor: context.color.textLightColor.withValues(alpha: 00.01),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required String hintText,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
    List<TextInputFormatter>? formaters,
    TextInputType? keyboard,
    Widget? prefix,
    FormFieldValidator<dynamic>? validator,
    TextDirection? textDirection,
  }) {
    final requiredSymbol = CustomText(
      '*',
      color: context.color.error,
      fontWeight: FontWeight.w400,
      fontSize: context.font.md,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.rh(context)),
        Row(
          children: [
            CustomText(UiUtils.translate(context, title)),
            const SizedBox(width: 3),
            requiredSymbol,
          ],
        ),
        SizedBox(height: 10.rh(context)),
        TextFormField(
          textDirection: textDirection,
          controller: controller,
          obscureText: isPasswordVisible,
          inputFormatters: formaters,
          keyboardAppearance: Brightness.light,
          style: TextStyle(
            fontSize: context.font.md,
            color: context.color.textColorDark,
          ),
          validator: validator,
          keyboardType: keyboard,
          decoration: InputDecoration(
            prefix: prefix,
            hintText: hintText,
            suffixIcon: GestureDetector(
              onTap: onToggleVisibility,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CustomImage(
                  imageUrl:
                      isPasswordVisible ? AppIcons.eye : AppIcons.eyeSlash,
                  color: context.color.textColorDark.withValues(alpha: 0.5),
                  width: 24.rw(context),
                  height: 24.rh(context),
                ),
              ),
            ),
            hintStyle: TextStyle(
              color: context.color.textColorDark.withValues(alpha: 0.7),
              fontSize: context.font.md,
            ),
            filled: true,
            fillColor: context.color.primaryColor,
            focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(width: 1.5, color: context.color.tertiaryColor),
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(width: 1.5, color: context.color.borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            border: OutlineInputBorder(
              borderSide:
                  BorderSide(width: 1.5, color: context.color.borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  void showCountryCode() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        searchTextStyle: TextStyle(
          color: context.color.textColorDark,
        ),
        textStyle: TextStyle(
          color: context.color.textColorDark,
        ),
        borderRadius: BorderRadius.circular(8),
        backgroundColor: context.color.backgroundColor,
        inputDecoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          iconColor: context.color.tertiaryColor,
          prefixIconColor: context.color.tertiaryColor,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.color.tertiaryColor),
          ),
          floatingLabelStyle: TextStyle(color: context.color.tertiaryColor),
          labelText: 'search'.translate(context),
          border: const OutlineInputBorder(),
        ),
      ),
      onSelect: (value) {
        setState(() {
          flagEmoji = value.flagEmoji;
          countryCode = value.phoneCode;
        });
      },
    );
  }

  Widget resendOtpTimerWidget() {
    return ValueListenableBuilder(
      valueListenable: otpResendTime,
      builder: (context, value, _) {
        if (!(timer?.isActive ?? false)) {
          return const SizedBox.shrink();
        }

        String formatSecondsToMinutes(int seconds) {
          final minutes = seconds ~/ 60;
          final remainingSeconds = seconds % 60;
          return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
        }

        final textColor = Theme.of(context).colorScheme.textColorDark;
        final tertiaryColor = Theme.of(context).colorScheme.tertiaryColor;

        return SizedBox(
          height: 70,
          child: Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                text: "${UiUtils.translate(context, "resendMessage")} ",
                style: TextStyle(
                  color: textColor,
                  letterSpacing: 0.5,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: formatSecondsToMinutes(value),
                    style: TextStyle(
                      color: tertiaryColor,
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
                      color: tertiaryColor,
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
    context.read<SendOtpCubit>().sendEmailOTP(
          email: emailController.text.trim(),
          name: nameController.text.trim(),
          phoneNumber: mobileController.text.trim(),
          countryCode: countryCode,
          password: passwordController.text.trim(),
          confirmPassword: confirmPasswordController.text.trim(),
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
        } else if (mounted) {
          otpResendTime.value--;
        }
      },
    );
  }
}
