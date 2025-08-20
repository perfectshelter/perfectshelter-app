import 'package:country_picker/country_picker.dart';
import 'package:ebroker/data/model/system_settings_model.dart';
import 'package:ebroker/data/repositories/auth_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/auth/country_picker.dart';
import 'package:ebroker/ui/screens/home/home_screen.dart';
import 'package:ebroker/utils/login/apple_login/apple_login.dart';
import 'package:ebroker/utils/login/google_login/google_login.dart';
import 'package:ebroker/utils/login/lib/login_status.dart';
import 'package:ebroker/utils/login/lib/login_system.dart';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

// UI Constants
class UIConstants {
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 10;
  static const double spacingL = 14;
  static const double spacingXL = 20;
}

// Form validator to encapsulate form validation logic
class FormValidator {
  static bool validateEmailForm(
    GlobalKey<FormState> formKey,
    BuildContext context,
  ) {
    if (!formKey.currentState!.validate()) {
      HelperUtils.showSnackBarMessage(
        context,
        'enterValidEmailPassword'.translate(context),
        messageDuration: 1,
        type: MessageType.error,
        isFloating: true,
      );
      return false;
    }
    return true;
  }

  static bool validatePhoneForm(
    GlobalKey<FormState> formKey,
    BuildContext context,
    String phoneNumber,
  ) {
    if (!formKey.currentState!.validate() || phoneNumber.isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'enterValidNumber'.translate(context),
        messageDuration: 1,
        type: MessageType.error,
        isFloating: true,
      );
      return false;
    }
    return true;
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.isDeleteAccount, this.popToCurrent});

  final bool? isDeleteAccount;
  final bool? popToCurrent;

  @override
  State<LoginScreen> createState() => LoginScreenState();

  static CupertinoPageRoute<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => SendOtpCubit()),
          BlocProvider(create: (context) => VerifyOtpCubit()),
        ],
        child: LoginScreen(
          isDeleteAccount: args?['isDeleteAccount'] as bool? ?? false,
          popToCurrent: args?['popToCurrent'] as bool? ?? false,
        ),
      ),
    );
  }
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileNumController = TextEditingController(
    text: Constant.isDemoModeOn ? Constant.demoMobileNumber : '',
  );

  final TextEditingController emailAddressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  List<Widget> list = [];
  String otpVerificationId = '';
  final _formKey = GlobalKey<FormState>();
  bool isOtpSent = false; //to swap between login & OTP screen
  String? otp;
  String? countryCode;
  String? countryName;
  String? flagEmoji;
  late bool isTablet = MediaQuery.sizeOf(context).width > 600;

  int backPressedTimes = 0;
  late Size size;

  TextEditingController otpController = TextEditingController();
  bool isLoginButtonDisabled = false;
  String otpIs = '';
  bool isPhoneLoginEnabled = false;
  bool isSocialLoginEnabled = false;
  bool isEmailSelected = false;
  bool isResendOtpButtonVisible = false;
  bool isForgotPasswordVisible = false;
  bool isPasswordVisible = false;

  MMultiAuthentication loginSystem = MMultiAuthentication({
    'google': GoogleLogin(),
    'apple': AppleLogin(),
  });

  // Text change listener

  @override
  void initState() {
    super.initState();

    loginSystem
      ..init()
      ..setContext(context)
      ..listen((MLoginState state) {
        if (state is MProgress) {
          unawaited(Widgets.showLoader(context));
        }

        if (state is MSuccess) {
          Widgets.hideLoder(context);
          if (widget.isDeleteAccount ?? false) {
            context.read<DeleteAccountCubit>().deleteUserAccount(
                  context,
                );
          } else {
            context.read<LoginCubit>().login(
                  type: LoginType.values
                      .firstWhere((element) => element.name == state.type),
                  name: state.credentials.user?.displayName ??
                      state.credentials.user?.providerData.first.displayName,
                  email: state.credentials.user?.providerData.first.email,
                  phoneNumber:
                      state.credentials.user?.providerData.first.phoneNumber ??
                          '',
                  uniqueId: state.credentials.user!.uid,
                  countryCode: countryCode ?? '',
                );
          }
        }

        if (state is MFail) {
          Widgets.hideLoder(context);
          if (state.error.toString() != 'google-terminated') {
            HelperUtils.showSnackBarMessage(
              context,
              state.error.toString(),
              type: MessageType.error,
            );
            Widgets.hideLoder(context);
          }
        }
      });
    context.read<FetchSystemSettingsCubit>();
    isPhoneLoginEnabled = context
            .read<FetchSystemSettingsCubit>()
            .getSetting(SystemSetting.numberWithOtpLogin)
            ?.toString() ==
        '1';
    isSocialLoginEnabled = context
            .read<FetchSystemSettingsCubit>()
            .getSetting(SystemSetting.socialLogin)
            ?.toString() ==
        '1';
    mobileNumController.addListener(
      () {
        if (mobileNumController.text.isEmpty &&
            Constant.isDemoModeOn == true &&
            Constant.demoMobileNumber.isNotEmpty) {
          isLoginButtonDisabled = true;
          setState(() {});
        } else {
          isLoginButtonDisabled = false;
          setState(() {});
        }
      },
    );

    HelperUtils.getSimCountry().then((value) {
      countryCode = value.phoneCode;
      flagEmoji = value.flagEmoji;
      setState(() {});
    });
  }

  @override
  void dispose() {
    isResendOtpButtonVisible = false;

    mobileNumController.dispose();
    if (isOtpSent) {
      SmsAutoFill().unregisterListener();
    }
    super.dispose();
  }

  Future<void> _onGoogleTap() async {
    try {
      // No loader is shown here to prevent app crashes
      await loginSystem.setActive('google');
      await loginSystem.login();
    } on Exception catch (_) {
      await HelperUtils.showSnackBarMessage(
        context,
        'googleLoginFailed'.translate(context),
        type: MessageType.error,
      );
    }
  }

  Future<void> _onTapAppleLogin() async {
    try {
      // No loader is shown here to prevent app crashes
      await loginSystem.setActive('apple');
      await loginSystem.login();
    } on Exception catch (_) {
      await HelperUtils.showSnackBarMessage(
        context,
        'appleLoginFailed'.translate(context),
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    if (context.watch<FetchSystemSettingsCubit>().state
        is FetchSystemSettingsSuccess) {
      Constant.isDemoModeOn = context
              .watch<FetchSystemSettingsCubit>()
              .getSetting(SystemSetting.demoMode) as bool? ??
          false;
    }

    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context),
      child: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: _handleBackPress,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: context.color.backgroundColor,
          appBar: _buildAppBar(),
          body: buildLoginFields(context),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      isTransparent: true,
      showBackButton: false,
      actions: [_buildSkipButton()],
    );
  }

  Widget _buildSkipButton() {
    return MaterialButton(
      color: context.color.secondaryColor.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: context.color.borderColor,
        ),
      ),
      elevation: 0,
      onPressed: () {
        GuestChecker.set('login_screen', isGuest: true);
        HiveUtils.setIsGuest();
        APICallTrigger.trigger();
        HiveUtils.setUserIsNotNew();
        HiveUtils.setUserIsNotAuthenticated();
        Navigator.pushReplacementNamed(
          context,
          Routes.main,
          arguments: {
            'from': 'login',
            'isSkipped': true,
          },
        );
      },
      child: CustomText('skip'.translate(context)),
    );
  }

  Future<bool> _handleBackPress(bool didPop, _) async {
    if (didPop) return false;
    if (widget.isDeleteAccount ?? false) {
      Navigator.pop(context);
    } else if (isOtpSent == true) {
      setState(() {
        isOtpSent = false;
      });
    } else {
      Future.delayed(Duration.zero, () {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      });
    }
    return Future.value(false);
  }

  Widget buildLoginFields(BuildContext context) {
    return BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
      listener: _handleDeleteAccountState,
      builder: (context, state) {
        return BlocListener<LoginCubit, LoginState>(
          listener: _handleLoginState,
          child: BlocListener<DeleteAccountCubit, DeleteAccountState>(
            listener: _handleDeleteAccountProgress,
            child: BlocListener<SendOtpCubit, SendOtpState>(
              listener: _handleSendOtpState,
              child: Form(
                key: _formKey,
                onChanged: () {
                  setState(() {});
                },
                child: buildLoginScreen(context),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleDeleteAccountState(
    BuildContext context,
    DeleteAccountState state,
  ) {
    if (state is AccountDeleted) {
      context.read<UserDetailsCubit>().clear();
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacementNamed(context, Routes.login);
      });
    }
  }

  Future<void> _handleLoginState(BuildContext context, LoginState state) async {
    if (state is LoginInProgress) {
      unawaited(Widgets.showLoader(context));
    } else {
      if (widget.isDeleteAccount ?? false) {
      } else {
        Widgets.hideLoder(context);
      }
    }
    if (state is LoginFailure) {
      await HelperUtils.showSnackBarMessage(
        context,
        state.errorMessage,
        type: MessageType.error,
      );
    }
    if (state is LoginSuccess) {
      await _handleLoginSuccess(context, state);
    }
  }

  Future<void> _handleLoginSuccess(
    BuildContext context,
    LoginSuccess state,
  ) async {
    try {
      unawaited(Widgets.showLoader(context));
      GuestChecker.set('login_screen', isGuest: false);
      HiveUtils.setIsNotGuest();
      await LoadAppSettings().load(initBox: true);
      context.read<UserDetailsCubit>().fill(HiveUtils.getUserDetails());

      APICallTrigger.trigger();

      await context.read<FetchSystemSettingsCubit>().fetchSettings(
            isAnonymous: false,
            forceRefresh: true,
          );
      final settings = context.read<FetchSystemSettingsCubit>();

      if (!const bool.fromEnvironment(
        'force-disable-demo-mode',
      )) {
        Constant.isDemoModeOn =
            settings.getSetting(SystemSetting.demoMode) as bool? ?? false;
      }
      if (state.isProfileCompleted) {
        await _handleCompletedProfile(context);
      }
    } on Exception catch (_) {
      Widgets.hideLoder(context);
      await HelperUtils.showSnackBarMessage(
        context,
        'somethingWentWrong'.translate(context),
        type: MessageType.error,
      );
    }
  }

  Future<void> _handleCompletedProfile(BuildContext context) async {
    HiveUtils.setUserIsAuthenticated();
    await HiveUtils.setUserIsNotNew();

    await Navigator.pushReplacementNamed(
      context,
      Routes.main,
      arguments: {'from': 'login'},
    );
    Widgets.hideLoder(context);
  }

  void _handleDeleteAccountProgress(
    BuildContext context,
    DeleteAccountState state,
  ) {
    if (state is DeleteAccountProgress) {
      Widgets.hideLoder(context);
      Widgets.showLoader(context);
    }
    if (state is AccountDeleted) {
      Widgets.hideLoder(context);
    }
  }

  void _handleSendOtpState(BuildContext context, SendOtpState state) {
    {
      if (widget.isDeleteAccount ?? false) {
        // Skip hiding loader for delete account flow
      } else {
        Widgets.hideLoder(context);
      }
    }
    if (state is SendOtpInProgress) {
      unawaited(Widgets.showLoader(context));
    }

    if (state is SendOtpSuccess) {
      Widgets.hideLoder(context);
      _handleSendOtpSuccess(context, state);
    }
    if (state is SendOtpFailure) {
      Widgets.hideLoder(context);
      HelperUtils.showSnackBarMessage(
        context,
        state.errorMessage,
        type: MessageType.error,
      );
    }
  }

  void _handleSendOtpSuccess(BuildContext context, SendOtpSuccess state) {
    isOtpSent = true;
    if (isForgotPasswordVisible) {
      HelperUtils.showSnackBarMessage(
        context,
        state.message ?? 'forgotPasswordSuccess'.translate(context),
        type: MessageType.success,
      );
    } else {
      HelperUtils.showSnackBarMessage(
        context,
        UiUtils.translate(
          context,
          'optsentsuccessflly',
        ),
        type: MessageType.success,
      );
    }
    otpVerificationId = state.verificationId ?? '';
    setState(() {});

    if (!isForgotPasswordVisible) {
      Navigator.pushNamed(
        context,
        Routes.otpScreen,
        arguments: {
          'isDeleteAccount': widget.isDeleteAccount ?? false,
          'phoneNumber': mobileNumController.text,
          'email': emailAddressController.text,
          'otpVerificationId': otpVerificationId,
          'countryCode': countryCode ?? '',
          'otpIs': otpIs,
          'isEmailSelected': isEmailSelected,
        },
      );
    }
  }

  String demoOTP() {
    if (Constant.isDemoModeOn &&
        Constant.demoMobileNumber == mobileNumController.text) {
      return Constant.demoModeOTP; // If true, return the demo mode OTP.
    } else {
      return ''; // If false, return an empty string.
    }
  }

  Widget buildLoginScreen(BuildContext context) {
    return BlocConsumer<FetchSystemSettingsCubit, FetchSystemSettingsState>(
      listener: (context, state) {
        if (state is FetchSystemSettingsInProgress) {
          unawaited(Widgets.showLoader(context));
        }
        if (state is FetchSystemSettingsSuccess) {
          Widgets.hideLoder(context);
        }
      },
      builder: (context, state) {
        if (state is FetchSystemSettingsSuccess) {
          return Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: _buildLoginImageContainer(),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildLoginContent(),
              ),
            ],
          );
        } else if (state is FetchSystemSettingsFailure) {
          return const Center(child: SomethingWentWrong());
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildLoginImageContainer() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          child: CustomImage(
            imageUrl: 'assets/login_background.png',
            height: isTablet ? context.screenHeight : 485,
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.fill,
            color: context.color.tertiaryColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginContent() {
    final height = isEmailSelected ? 595 : 437;
    return SafeArea(
      child: AnimatedContainer(
        curve: Curves.easeOutBack,
        duration: const Duration(milliseconds: 300),
        alignment: Alignment.center,
        width: isTablet ? context.screenWidth * 0.7 : context.screenWidth,
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.rw(context)),
            topRight: Radius.circular(16.rw(context)),
          ),
        ),
        height: height.rh(context),
        padding: EdgeInsets.symmetric(horizontal: sidePadding.rw(context)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildTitle(),
              if (!isSocialLoginEnabled) ...[
                buildMobileEmailField(),
              ],
              if (isSocialLoginEnabled) _buildSocialLoginSection(),
              const SizedBox(height: 16),
              buildTermsAndPrivacyWidget(
                context: context,
                isTablet: isTablet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() => Center(
        child: Column(
          children: [
            CustomText(
              UiUtils.translate(context, 'loginNow'),
              fontWeight: FontWeight.w700,
              fontSize: context.font.xxl,
              color: context.color.textColorDark,
            ),
            SizedBox(height: 8.rh(context)),
            CustomText(
              UiUtils.translate(context, 'loginToYourAccount'),
              fontWeight: FontWeight.w500,
              fontSize: context.font.sm,
              color: context.color.textColorDark,
            ),
            SizedBox(height: 20.rh(context)),
          ],
        ),
      );

  Widget _buildSocialLoginSection() {
    if (!isPhoneLoginEnabled) {
      return Column(
        children: [
          buildEmailOnly(),
          if (Platform.isIOS) ...[
            _buildSocialButton(
              text: 'signInWithApple'.translate(context),
              icon: AppIcons.apple,
              onTap: _onTapAppleLogin,
            ),
            SizedBox(width: UIConstants.spacingM.rw(context)),
          ],
          _buildSocialButton(
            text: 'signInWithGoogle'.translate(context),
            icon: AppIcons.google,
            onTap: _onGoogleTap,
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildMobileEmailField(),
          SizedBox(height: UIConstants.spacingS.rh(context)),
          Row(
            children: [
              Expanded(
                child: UiUtils.getDivider(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.spacingM,
                ),
                child: CustomText('or'.translate(context)),
              ),
              Expanded(
                child: UiUtils.getDivider(context),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacingM.rh(context)),
          _buildSocialButton(
            text: isEmailSelected
                ? 'signInWithPhone'.translate(context)
                : 'signInWithEmail'.translate(context),
            icon: isEmailSelected ? AppIcons.phone : AppIcons.email,
            iconColor: context.color.textColorDark,
            onTap: () {
              setState(() {
                isEmailSelected = !isEmailSelected;
                isForgotPasswordVisible = false;
                isResendOtpButtonVisible = false;
              });
            },
          ),
          SizedBox(width: UIConstants.spacingM.rw(context)),
          if (Platform.isIOS) ...[
            _buildSocialButton(
              text: 'signInWithApple'.translate(context),
              icon: AppIcons.apple,
              onTap: _onTapAppleLogin,
            ),
            SizedBox(width: UIConstants.spacingM.rw(context)),
          ],
          _buildSocialButton(
            text: 'signInWithGoogle'.translate(context),
            icon: AppIcons.google,
            onTap: _onGoogleTap,
          ),
        ],
      );
    }
  }

  Widget _buildSocialButton({
    required String icon,
    required VoidCallback onTap,
    required String text,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        HelperUtils.unfocus();
        onTap();
      },
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.only(bottom: 12.rh(context)),
        height: 48.rh(context),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.color.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              child: CustomImage(
                imageUrl: icon,
                color: iconColor,
                height: 24.rh(context),
                width: 24.rw(context),
              ),
            ),
            SizedBox(width: 8.rw(context)),
            CustomText(text),
          ],
        ),
      ),
    );
  }

// Optimized version with shared components

// Shared email field widget
  Widget _buildEmailField() {
    return CustomTextFormField(
      dense: true,
      controller: emailAddressController,
      validator: CustomTextFieldValidator.email,
      hintText: 'email'.translate(context),
      textDirection: TextDirection.ltr,
      keyboard: TextInputType.emailAddress,
      formaters: [FilteringTextInputFormatter.singleLineFormatter],
      prefix: Padding(
        padding: EdgeInsetsDirectional.only(
          start: 12.rw(context),
          end: 4.rw(context),
          top: 12.rh(context),
          bottom: 12.rh(context),
        ),
        child: CustomImage(
          imageUrl: AppIcons.email,
          color: context.color.textColorDark.withValues(alpha: 0.5),
          fit: BoxFit.none,
        ),
      ),
      onChange: (value) {
        setState(() {});
        isResendOtpButtonVisible = false;
      },
    );
  }

// Shared password field widget
  Widget _buildPasswordField() {
    return CustomTextFormField(
      dense: true,
      controller: passwordController,
      validator: CustomTextFieldValidator.nullCheck,
      hintText: 'password'.translate(context),
      isPassword: !isPasswordVisible,
      textDirection: TextDirection.ltr,
      keyboard: TextInputType.visiblePassword,
      formaters: [FilteringTextInputFormatter.singleLineFormatter],
      prefix: Padding(
        padding: EdgeInsetsDirectional.only(
          start: 12.rw(context),
          end: 4.rw(context),
          top: 12.rh(context),
          bottom: 12.rh(context),
        ),
        child: CustomImage(
          imageUrl: AppIcons.lock,
          color: context.color.textColorDark.withValues(alpha: 0.5),
          fit: BoxFit.none,
        ),
      ),
      suffix: Padding(
        padding: EdgeInsetsDirectional.only(end: 12.rw(context)),
        child: GestureDetector(
          onTap: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
          child: CustomImage(
            imageUrl: isPasswordVisible ? AppIcons.eyeSlash : AppIcons.eye,
            color: context.color.textColorDark.withValues(alpha: 0.5),
            fit: BoxFit.none,
          ),
        ),
      ),
      onChange: (value) {
        setState(() {});
      },
    );
  }

// Shared mobile field widget
  Widget _buildMobileField() {
    return CustomTextFormField(
      dense: true,
      borderColor: context.color.tertiaryColor,
      controller: mobileNumController,
      validator: CustomTextFieldValidator.phoneNumber,
      maxLine: 1,
      hintText: ' +${countryCode ?? ''} 0000000000',
      keyboard: TextInputType.phone,
      formaters: [FilteringTextInputFormatter.digitsOnly],
      prefix: CountryPickerWidget(
        flagEmoji: flagEmoji,
        onTap: showCountryCode,
      ),
      suffix: GestureDetector(
        onTap: sendPhoneVerificationCode,
        child: Container(
          margin: EdgeInsetsDirectional.only(
            end: 12.rw(context),
            top: 8.rh(context),
            bottom: 8.rh(context),
          ),
          height: 40.rh(context),
          width: 40.rw(context),
          decoration: BoxDecoration(
            color: context.color.tertiaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.arrow_forward,
            color: context.color.buttonColor,
          ),
        ),
      ),
      onChange: (value) {},
    );
  }

// Shared forgot password toggle widget
  Widget _buildForgotPasswordToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isForgotPasswordVisible = !isForgotPasswordVisible;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.rh(context)),
        alignment: AlignmentDirectional.centerEnd,
        child: CustomText(
          isForgotPasswordVisible
              ? 'goBackToLogin'.translate(context)
              : 'forgotPassword'.translate(context), // Assuming this exists
          fontSize: context.font.sm,
          color: context.color.tertiaryColor,
        ),
      ),
    );
  }

// Shared sign up section widget
  Widget _buildSignUpSection() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runAlignment: WrapAlignment.center,
      children: [
        CustomText(
          'registerWith'.translate(context),
          fontSize: context.font.sm,
        ),
        SizedBox(width: 4.rw(context)),
        CustomText(
          'appName'.translate(context),
          fontSize: context.font.sm,
        ),
        SizedBox(width: 4.rw(context)),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              Routes.emailRegistrationForm,
              arguments: {
                'email': emailAddressController.text,
              },
            );
          },
          child: CustomText(
            'signUp'.translate(context),
            fontWeight: FontWeight.w600,
            fontSize: context.font.sm,
            color: context.color.tertiaryColor,
          ),
        ),
      ],
    );
  }

// Shared action button widget
  Widget _buildActionButton() {
    if (isForgotPasswordVisible) {
      return buildSubmitButton();
    } else if (isResendOtpButtonVisible) {
      return buildResendOtpButton();
    } else {
      return buildNextButton();
    }
  }

// Optimized buildMobileEmailField
  Widget buildMobileEmailField() {
    return Column(
      children: [
        // Input fields section
        if (isEmailSelected)
          Column(
            children: [
              _buildEmailField(),
              if (!isForgotPasswordVisible) ...[
                const SizedBox(height: 8),
                _buildPasswordField(),
              ],
            ],
          )
        else
          _buildMobileField(),

        // Forgot password section
        if (isEmailSelected) _buildForgotPasswordToggle(),

        // Action button
        _buildActionButton(),

        SizedBox(height: 8.rh(context)),

        // Sign up section (only for email)
        if (isEmailSelected) _buildSignUpSection(),
      ],
    );
  }

// Optimized buildEmailOnly
  Widget buildEmailOnly() {
    return Column(
      children: [
        // Input fields section
        Column(
          children: [
            _buildEmailField(),
            if (!isForgotPasswordVisible) ...[
              SizedBox(height: 8.rh(context)),
              _buildPasswordField(),
            ],
          ],
        ),

        SizedBox(height: 8.rh(context)),

        // Forgot password section
        _buildForgotPasswordToggle(),

        SizedBox(height: 8.rh(context)),

        // Action button
        _buildActionButton(),

        SizedBox(height: 8.rh(context)),

        // Sign up section
        _buildSignUpSection(),

        SizedBox(height: 8.rh(context)),
        Row(
          children: [
            Expanded(
              child: UiUtils.getDivider(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingM,
              ),
              child: CustomText('or'.translate(context)),
            ),
            Expanded(
              child: UiUtils.getDivider(context),
            ),
          ],
        ),
        SizedBox(height: 8.rh(context)),
      ],
    );
  }

  void showCountryCode() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(8),
        backgroundColor: context.color.backgroundColor,
        textStyle: TextStyle(color: context.color.textColorDark),
        inputDecoration: InputDecoration(
          hintStyle: TextStyle(color: context.color.textColorDark),
          helperStyle: TextStyle(color: context.color.textColorDark),
          prefixIcon: const Icon(Icons.search),
          iconColor: context.color.tertiaryColor,
          prefixIconColor: context.color.tertiaryColor,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.color.tertiaryColor),
          ),
          floatingLabelStyle: TextStyle(color: context.color.tertiaryColor),
          labelText: 'search'.translate(context),
          border: const OutlineInputBorder(),
          labelStyle: TextStyle(color: context.color.textColorDark),
        ),
      ),
      onSelect: (Country value) {
        flagEmoji = value.flagEmoji;
        countryCode = value.phoneCode;
        setState(() {});
      },
    );
  }

  Widget buildForgotPasswordText() {
    return GestureDetector(
      onTap: () {
        isForgotPasswordVisible = true;
        setState(() {});
      },
      child: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: sidePadding, bottom: 10),
        child: CustomText(
          'forgotPassword'.translate(context),
          fontSize: context.font.sm,
          color: context.color.tertiaryColor,
        ),
      ),
    );
  }

  Widget buildSubmitButton() {
    return UiUtils.buildButton(
      context,
      onPressed: () async {
        await context.read<SendOtpCubit>().sendForgotPasswordEmail(
              email: emailAddressController.text.trim(),
            );
      },
      disabled: emailAddressController.text.trim().isEmpty,
      disabledColor: Colors.grey,
      height: 50,
      radius: 10,
      border: BorderSide(
        color: context.color.borderColor,
      ),
      buttonTitle: 'submit'.translate(context),
    );
  }

  Widget buildResendOtpButton() {
    return UiUtils.buildButton(
      context,
      onPressed: () async {
        await context.read<SendOtpCubit>().resendEmailOTP(
              email: emailAddressController.text.trim(),
              password: passwordController.text.trim(),
            );
      },
      buttonTitle: UiUtils.translate(context, 'resendOtpBtnLbl'),
    );
  }

  Widget buildNextButton() {
    if (!isEmailSelected && isPhoneLoginEnabled) return const SizedBox.shrink();
    return UiUtils.buildButton(
      context,
      disabled: emailAddressController.text.isEmpty,
      disabledColor: Colors.grey,
      height: 48.rh(context),
      onPressed: sendEmailVerificationCode,
      buttonTitle: 'continue'.translate(context),
      border: BorderSide(
        color: context.color.borderColor,
      ),
      radius: 4,
    );
  }

  Future<void> sendEmailVerificationCode() async {
    if (FormValidator.validateEmailForm(_formKey, context)) {
      unawaited(Widgets.showLoader(context));
      await context.read<LoginCubit>().loginWithEmail(
            email: emailAddressController.text.trim(),
            password: passwordController.text.trim(),
            type: LoginType.email,
          );

      final state = context.read<LoginCubit>().state;
      if (state is LoginFailure && state.key == 'emailNotVerified') {
        Widgets.hideLoder(context);
        isResendOtpButtonVisible = true;
        setState(() {});
      } else if (state is LoginSuccess) {
        Widgets.hideLoder(context);
      } else {
        Widgets.hideLoder(context);
      }
    }
  }

  Future<void> sendPhoneVerificationCode() async {
    if (!FormValidator.validatePhoneForm(
      _formKey,
      context,
      mobileNumController.text,
    )) {
      return;
    }

    final form = _formKey.currentState;
    if (form == null) return;
    form.save();

    try {
      if (form.validate()) {
        if (widget.isDeleteAccount ?? false) {
          if (AppSettings.otpServiceProvider == 'twilio') {
            await context.read<SendOtpCubit>().sendTwilioOTP(
                  phoneNumber: mobileNumController.text,
                  countryCode: countryCode!,
                );
          } else if (AppSettings.otpServiceProvider == 'firebase') {
            await context.read<SendOtpCubit>().sendFirebaseOTP(
                  phoneNumber: mobileNumController.text,
                  countryCode: countryCode!,
                );
          }
        } else if (AppSettings.otpServiceProvider == 'firebase') {
          await context.read<SendOtpCubit>().sendFirebaseOTP(
                phoneNumber: mobileNumController.text,
                countryCode: countryCode!,
              );
        } else if (AppSettings.otpServiceProvider == 'twilio') {
          await context.read<SendOtpCubit>().sendTwilioOTP(
                phoneNumber: mobileNumController.text,
                countryCode: countryCode!,
              );
        }
      }
    } on Exception catch (_) {
      Widgets.hideLoder(context);
      await HelperUtils.showSnackBarMessage(
        context,
        'enterValidPhoneNumber'.translate(context),
        type: MessageType.error,
      );
    }
  }

// This function builds the UI but requires the parent to manage recognizers.
  Widget buildTermsAndPrivacyWidget({
    required BuildContext context,
    required bool isTablet, // Pass `isTablet` as a parameter
  }) {
    // Define styles once to avoid repetition and improve readability.
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final baseStyle = textTheme.bodyLarge?.copyWith(
      color: colorScheme.textColorDark,
    );
    final linkStyle = baseStyle?.copyWith(
      color: colorScheme.tertiaryColor,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    // Using Text.rich, a concise way to create RichText.
    // The redundant wrapping Row has been removed.
    return Container(
      width: isTablet ? context.screenWidth * 0.7 : context.screenWidth,
      color: context.color.secondaryColor,
      padding:
          const EdgeInsets.symmetric(vertical: 8), // Added for better spacing
      margin: EdgeInsets.only(bottom: 8.rh(context)),
      child: Text.rich(
        TextSpan(
          style: baseStyle, // Base style applied to all children
          children: <TextSpan>[
            TextSpan(
              text:
                  "${UiUtils.translate(context, "policyAggreementStatement")}\n",
            ),
            TextSpan(
              text: UiUtils.translate(context, 'termsConditions'),
              style: linkStyle,
            ),
            TextSpan(
              text: " ${UiUtils.translate(context, "and")} ",
            ),
            TextSpan(
              text: UiUtils.translate(context, 'privacyPolicy'),
              style: linkStyle,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
