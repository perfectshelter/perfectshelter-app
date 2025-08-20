import 'dart:developer';

import 'package:ebroker/data/cubits/subscription/assign_free_package.dart';
import 'package:ebroker/data/cubits/subscription/assign_package.dart';
import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/subscription/widget/bank_transfer.dart';
import 'package:ebroker/ui/screens/subscription/widget/my_packages_tile.dart';
import 'package:ebroker/ui/screens/subscription/widget/package_tile.dart';
import 'package:ebroker/utils/admob/banner_ad_load_widget.dart';
import 'package:ebroker/utils/admob/interstitial_ad_manager.dart';
import 'package:ebroker/utils/payment/in_app_purchase/in_app_purchase_manager.dart';
import 'package:ebroker/utils/payment/lib/payment.dart';
import 'package:ebroker/utils/payment/lib/payment_service.dart';
import 'package:flutter/material.dart';

class SubscriptionPackageListScreen extends StatefulWidget {
  const SubscriptionPackageListScreen({
    required this.isBankTransferEnabled,
    super.key,
    this.from,
  });
  final String? from;
  final bool isBankTransferEnabled;

  static Route<dynamic> route(RouteSettings settings) {
    final arguments = settings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => GetSubsctiptionPackageLimitsCubit(),
            ),
            BlocProvider(
              create: (context) => AssignFreePackageCubit(),
            ),
            BlocProvider(
              create: (context) => AssignInAppPackageCubit(),
            ),
          ],
          child: SubscriptionPackageListScreen(
            from: arguments?['from']?.toString() ?? '',
            isBankTransferEnabled:
                arguments?['isBankTransferEnabled'] as bool? ?? false,
          ),
        );
      },
    );
  }

  @override
  State<SubscriptionPackageListScreen> createState() =>
      SubscriptionPackageListScreenState();
}

class SubscriptionPackageListScreenState
    extends State<SubscriptionPackageListScreen>
    with SingleTickerProviderStateMixin {
  InterstitialAdManager interstitialAdManager = InterstitialAdManager();
  InAppPurchaseManager inAppPurchase = InAppPurchaseManager();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  String? _selectedPaymentMethod;
  bool? isBankTransferActive;
  bool? isOnlinePaymentActive;
  // Bank transfer related state variables have been moved to bank_transfer.dart

  @override
  void initState() {
    final state = context.read<GetApiKeysCubit>().state as GetApiKeysSuccess;
    isBankTransferActive = widget.isBankTransferEnabled;
    isOnlinePaymentActive = state.enabledPaymentGatway.isNotEmpty &&
        state.enabledPaymentGatway != '';
    _selectedPaymentMethod = 'online';
    // Initialize tab controller with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 1;
    context.read<FetchSubscriptionPackagesCubit>().fetchPackages();
    _scrollController.addListener(() {
      if (_scrollController.isEndReached()) {
        if (context.read<FetchSubscriptionPackagesCubit>().hasMore()) {
          context.read<FetchSubscriptionPackagesCubit>().fetchMorePackages();
        }
      }
    });
    interstitialAdManager.load();
    InAppPurchaseManager.getPendings();
    inAppPurchase.listenIAP(context);

    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  dynamic ifServiceUnlimited(dynamic text, {dynamic remining}) {
    if (text == 'unlimited') {
      return UiUtils.translate(context, 'unlimited');
    }
    if (text == 'not_available') {
      return '';
    }
    if (remining != null) {
      return '';
    }

    return text;
  }

  bool isUnlimited(int text, {dynamic remining}) {
    if (text == 0) {
      return true;
    }
    if (remining != null) {
      return false;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: CustomText(UiUtils.translate(context, 'subscriptionPlan')),
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: BannerAdWidget(bannerSize: AdSize.banner),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await interstitialAdManager.show();
          Future.delayed(
            Duration.zero,
            () {
              Navigator.pop(context);
            },
          );
        },
        child: MultiBlocListener(
          listeners: [
            BlocListener<AssignInAppPackageCubit, AssignInAppPackageState>(
              listener: (context, state) {
                if (state is AssignInAppPackageSuccess) {
                  context.read<FetchSystemSettingsCubit>().fetchSettings(
                        isAnonymous: false,
                        forceRefresh: true,
                      );
                  HelperUtils.showSnackBarMessage(
                    context,
                    'Package Assigned',
                  );
                }
              },
            ),
          ],
          child: Builder(
            builder: (context) {
              return BlocListener<AssignFreePackageCubit,
                  AssignFreePackageState>(
                listener: (context, state) {
                  if (state is AssignFreePackageInProgress) {
                    unawaited(Widgets.showLoader(context));
                  }

                  if (state is AssignFreePackageSuccess) {
                    Widgets.hideLoder(context);
                    context
                        .read<FetchSubscriptionPackagesCubit>()
                        .fetchPackages();
                    context.read<FetchSystemSettingsCubit>().fetchSettings(
                          isAnonymous: false,
                          forceRefresh: true,
                        );

                    HelperUtils.showSnackBarMessage(
                      context,
                      'freePackageAssigned'.translate(context),
                    );
                  }

                  if (state is AssignFreePackageFail) {
                    Widgets.hideLoder(context);

                    HelperUtils.showSnackBarMessage(
                      context,
                      'failedToAssignFreePackage'.translate(context),
                    );
                  }
                },
                child: BlocBuilder<FetchSubscriptionPackagesCubit,
                    FetchSubscriptionPackagesState>(
                  builder: (context, state) {
                    if (state is FetchSubscriptionPackagesInProgress) {
                      return buildSubscriptionShimmer();
                    }
                    if (state is FetchSubscriptionPackagesFailure) {
                      if (state.errorMessage is NoInternetConnectionError) {
                        return NoInternet(
                          onRetry: () {
                            context
                                .read<FetchSubscriptionPackagesCubit>()
                                .fetchPackages();
                          },
                        );
                      }

                      return const SomethingWentWrong();
                    }
                    if (state is FetchSubscriptionPackagesSuccess) {
                      return Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                              top: 20.rh(context),
                              left: 16.rh(context),
                              right: 16.rh(context),
                              bottom: 16.rh(context),
                            ),
                            height: 48.rh(context),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: context.color.secondaryColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: context.color.borderColor,
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorColor: context.color.tertiaryColor,
                              labelColor: context.color.buttonColor,
                              dividerColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color: context.color.tertiaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              unselectedLabelColor: context.color.textColorDark,
                              tabs: [
                                Tab(
                                  text: UiUtils.translate(context, 'myPlans'),
                                ),
                                Tab(
                                  text: UiUtils.translate(context, 'allPlans'),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Current Plan Tab
                                _buildCurrentPlanTab(state),

                                // Other Plans Tab
                                _buildOtherPlansTab(state),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return Container();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildSubscriptionShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomShimmer(
              borderRadius: 4,
              height: 48,
              width: MediaQuery.of(context).size.width,
            ),
          ),
          buildSubscriptionShimmerItem(),
          buildSubscriptionShimmerItem(),
        ],
      ),
    );
  }

  Widget buildSubscriptionShimmerItem() {
    return Container(
      margin: const EdgeInsetsDirectional.only(
        top: 10,
        start: 16,
        end: 16,
      ),
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          const CustomShimmer(
            borderRadius: 4,
            height: 50,
          ),
          ...List.generate(
            8,
            (index) => const Padding(
              padding: EdgeInsetsDirectional.only(
                start: 12,
                end: 12,
              ),
              child: Column(
                children: [
                  SizedBox(height: 16),
                  Row(
                    children: [
                      CustomShimmer(
                        borderRadius: 4,
                        height: 20,
                        width: 20,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: CustomShimmer(
                          borderRadius: 4,
                          height: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: MySeparator(
              color: context.color.tertiaryColor.withValues(alpha: 0.7),
              isShimmer: true,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(
              top: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: context.color.tertiaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomShimmer(
              borderRadius: 4,
              height: 60,
              width: MediaQuery.of(context).size.width,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanTab(FetchSubscriptionPackagesSuccess state) {
    // Find and display only the active package
    final currentPackage = state.packageResponseModel.activePackage;

    return currentPackage.isNotEmpty
        ? ListView.builder(
            itemCount: currentPackage.length,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return CurrentPackageTileCard(
                package: currentPackage[index],
                allFeatures: state.packageResponseModel.allFeature,
              );
            },
          )
        : const Center(
            heightFactor: double.infinity,
            child: NoDataFound(),
          );
  }

  Widget _buildOtherPlansTab(FetchSubscriptionPackagesSuccess state) {
    final otherPackages = state.packageResponseModel.subscriptionPackage;

    if (otherPackages.isEmpty) {
      return const Center(
        heightFactor: double.infinity,
        child: NoDataFound(),
      );
    }

    return ListView.builder(
      physics: Constant.scrollPhysics,
      itemCount: otherPackages.length + 2, // +2 for loading and error widgets
      itemBuilder: (context, index) {
        if (index < otherPackages.length) {
          final subscriptionPackage = otherPackages[index];
          return SubscriptionPackageTile(
            package: subscriptionPackage,
            packageFeatures: state.packageResponseModel.allFeature,
            onTap: () async {
              await onTapSubscriptionTile(
                subscriptionPackage: subscriptionPackage,
              );
            },
          );
        } else if (index == otherPackages.length && state.isLoadingMore) {
          return UiUtils.progress();
        } else if (index == otherPackages.length + 1 && state.hasError) {
          return const CustomText('Something went wrong');
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<void> onTapSubscriptionTile({
    required SubscriptionPackageModel subscriptionPackage,
  }) async {
    await GuestChecker.check(onNotGuest: () async {
      if (subscriptionPackage.packageStatus == 'review') {
        await showModalBottomSheet<dynamic>(
          context: context,
          backgroundColor: context.color.secondaryColor,
          builder: (context) => Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  UiUtils.translate(context, 'review'),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 16),
                CustomText(
                  UiUtils.translate(context, 'packageStatus'),
                  fontSize: 16,
                ),
                const SizedBox(height: 16),
                UiUtils.buildButton(
                  context,
                  onPressed: () {
                    Navigator.popAndPushNamed(
                      context,
                      Routes.transactionHistory,
                    );
                  },
                  buttonTitle: 'transactionHistory'.translate(context),
                ),
              ],
            ),
          ),
        );
        return;
      }

      if (subscriptionPackage.price == 0) {
        await onOnlineSubscribe(subscriptionPackage);
        return;
      }

      if ((isBankTransferActive ?? false) && (isOnlinePaymentActive ?? false)) {
        await showModalBottomSheet<dynamic>(
          context: context,
          isScrollControlled: true,
          elevation: 10,
          backgroundColor: context.color.secondaryColor,
          builder: (context) => buildPaymentMethodsBottomSheet(
            subscriptionPackage: subscriptionPackage,
          ),
        );
      } else if (!(isBankTransferActive ?? true) &&
          (isOnlinePaymentActive ?? false)) {
        await onOnlineSubscribe(subscriptionPackage);
      } else if ((isBankTransferActive ?? false) &&
          !(isOnlinePaymentActive ?? true)) {
        await onBankTransferSubscribe(subscriptionPackage);
      }
    });
  }

  Widget buildPaymentMethodsBottomSheet({
    required SubscriptionPackageModel subscriptionPackage,
  }) {
    final state = context.read<GetApiKeysCubit>().state as GetApiKeysSuccess;
    final enabledPaymentGatway = state.enabledPaymentGatway;
    final icon = _getPaymentGatewayIcon(enabledPaymentGatway);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: StatefulBuilder(
        // Add StatefulBuilder here
        builder: (context, setSheetState) {
          // This gives local setState for the bottom sheet
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 4,
                  margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.4,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                CustomText(
                  'selectPaymentMethod'.translate(context),
                  fontSize: context.font.lg,
                  fontWeight: FontWeight.w700,
                  color: context.color.textColorDark,
                ),
                const SizedBox(height: 16),
                _buildPaymentOptionForBottomSheet(
                  value: 'online',
                  title:
                      enabledPaymentGatway.translate(context).firstUpperCase(),
                  icon: icon,

                  setSheetState: setSheetState, // Pass the local setState
                ),
                const SizedBox(height: 12),
                _buildPaymentOptionForBottomSheet(
                  value: 'bank_transfer',
                  title: 'bankTransfer'.translate(context),
                  icon: AppIcons.bankTransfer,
                  iconColor: context.color.textColorDark,
                  setSheetState: setSheetState, // Pass the local setState
                ),
                const SizedBox(height: 18),
                UiUtils.buildButton(
                  context,
                  radius: 12,
                  buttonTitle: 'continue'.translate(context),
                  onPressed: () async {
                    if (_selectedPaymentMethod == 'online') {
                      Navigator.pop(context);
                      await onOnlineSubscribe(subscriptionPackage);
                    } else {
                      Navigator.pop(context);
                      await onBankTransferSubscribe(subscriptionPackage);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to determine payment gateway icon
  String _getPaymentGatewayIcon(String enabledPaymentGatway) {
    if (enabledPaymentGatway == 'flutterwave') {
      return AppIcons.flutterwave;
    } else if (enabledPaymentGatway == 'paystack') {
      return AppIcons.paystack;
    } else if (enabledPaymentGatway == 'razorpay') {
      return AppIcons.razorpay;
    } else if (enabledPaymentGatway == 'paypal') {
      return AppIcons.paypal;
    } else {
      return AppIcons.stripe;
    }
  }

  // PAYMENT METHODS

  // Method to handle online subscriptions
  Future<void> onOnlineSubscribe(
    SubscriptionPackageModel subscriptionPackage,
  ) async {
    log('######## ${AppSettings.enabledPaymentGatway}----${AppSettings.razorpayKey}');
    if (Constant.isDemoModeOn &&
        HiveUtils.getUserDetails().email == Constant.demoEmail) {
      await HelperUtils.showSnackBarMessage(
        context,
        'thisActionNotValidDemo'.translate(context),
      );
      return;
    }

    // Handle free packages
    if (subscriptionPackage.price == 0) {
      await UiUtils.showBlurredDialoge(
        context,
        dialog: BlurredDialogBox(
          title: 'areYouSure'.translate(context),
          content: CustomText(
            'areYourSureForFreePackage'.translate(context),
          ),
          onAccept: () async {
            await context.read<AssignFreePackageCubit>().assign(
                  subscriptionPackage.id,
                );
          },
        ),
      );
      return;
    }

    // Handle iOS in-app purchases
    if (Platform.isIOS) {
      await inAppPurchase.buy(
        subscriptionPackage.iosProductId,
        subscriptionPackage.id.toString(),
      );
      return;
    }

    // Handle other payment gateways
    if (isPaymentGatewayOpen == false) {
      final paymentService = PaymentService()
        ..targetGatwayKey = AppSettings.enabledPaymentGatway
        ..attachedGatways(gatways)
        ..setContext(context)
        ..setPackage(subscriptionPackage);
      await paymentService.pay();
    }
  }

  // Method to handle bank transfer subscriptions
  Future<void> onBankTransferSubscribe(
    SubscriptionPackageModel subscriptionPackage,
  ) async {
    log('######## onBankTransferSubscribe');
    await BankTransfer.show(
      context: context,
      subscriptionPackage: subscriptionPackage,
    );
  }

  // Bank transfer UI components have been moved to bank_transfer.dart

  // PAYMENT METHOD SELECTION UI

  // Payment option button for bottom sheet
  Widget _buildPaymentOptionForBottomSheet({
    required String value,
    required String title,
    required String icon,
    required dynamic Function(void Function()) setSheetState,
    Color? iconColor,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        // Update the parent state
        setState(() {
          _selectedPaymentMethod = value;
        });
        // Also update the bottom sheet UI
        setSheetState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? context.color.tertiaryColor
                : context.color.borderColor,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CustomImage(
              imageUrl: icon,
              color: iconColor,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 12),
            CustomText(
              title,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            const Spacer(),
            Center(
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.color.primaryColor,
                  border: Border.all(
                    color: context.color.tertiaryColor,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.color.tertiaryColor,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
