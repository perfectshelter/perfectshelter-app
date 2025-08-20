//
// ignore_for_file: depend_on_referenced_packages, unawaited_futures

import 'package:perfectshelter/data/cubits/subscription/flutterwave_cubit.dart';
import 'package:perfectshelter/data/model/subscription_pacakage_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/utils/payment/lib/payment.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class FlutterwaveWidget extends StatefulWidget {
  const FlutterwaveWidget({
    required this.pacakge,
    super.key,
    this.onSuccess,
    this.onFail,
  });
  final SubscriptionPackageModel pacakge;
  final dynamic Function(dynamic msg)? onSuccess;
  final dynamic Function(dynamic msg)? onFail;

  @override
  State<FlutterwaveWidget> createState() => _FlutterwaveWidgetState();
}

class _FlutterwaveWidgetState extends State<FlutterwaveWidget> {
  WebViewController? controllerGlobal;
  String flutterwaveLink = '';
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Move the initialization logic here
    if (isLoading) {
      initializePaymentLink();
    }
  }

  Future<void> initializePaymentLink() async {
    try {
      // Safely read the cubit
      final flutterwaveCubit = context.read<FlutterwaveCubit>();

      // Assign the package
      await flutterwaveCubit.assign(widget.pacakge.id);

      // Get the current state
      final state = flutterwaveCubit.state;

      if (state is FlutterwaveSuccess) {
        await _initializeWebView(state.flutterwaveLink);
      } else if (state is FlutterwaveFail) {
        _handleInitializationError('Purchase failed');
      }
    } on Exception catch (e) {
      _handleInitializationError(e.toString());
    }
  }

  void _handleInitializationError(String errorMessage) {
    setState(() {
      isLoading = false;
    });

    // Use ScaffoldMessenger from the current context
    HelperUtils.showSnackBarMessage(
      context,
      errorMessage.translate(context),
      type: MessageType.error,
    );

    // Optionally call onFail callback
    widget.onFail?.call(errorMessage);

    // Close the payment screen
    Navigator.of(context).pop();
  }

  Future<void> _initializeWebView(String link) async {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..enableZoom(false)
      ..loadRequest(
        Uri.parse(link),
        headers: {'Authorization': 'Bearer ${HiveUtils.getJWT()}'},
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: CustomText(message.message)),
          );
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: _handleUrlChange,
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    setState(() {
      controllerGlobal = controller;
      isLoading = false;
      flutterwaveLink = link;
    });
  }

  void _handleUrlChange(UrlChange change) {
    final uri = Uri.parse(change.url ?? '');

    if (uri.host == Uri.parse(AppSettings.baseUrl).host &&
        uri.pathSegments.contains('flutterwave-payment-status')) {
      final success = uri.toString().contains('status=successful');
      if (success) {
        widget.onSuccess?.call('Payment Successful');
        isPaymentGatewayOpen = false;
        HelperUtils.showSnackBarMessage(
          context,
          'Payment Successful',
          type: MessageType.success,
        );
        Navigator.of(context).pop();
      } else {
        widget.onFail?.call('Payment Failed');
        isPaymentGatewayOpen = false;
        HelperUtils.showSnackBarMessage(
          context,
          'Payment Failed',
          type: MessageType.error,
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: context.color.tertiaryColor,
          ),
        ),
      );
    }

    if (controllerGlobal == null) {
      return Scaffold(
        body: Center(
          child: CustomText(UiUtils.translate(context, 'errorLoadingPayment')),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await controllerGlobal!.canGoBack()) {
          await controllerGlobal!.goBack();
        } else {
          isPaymentGatewayOpen = false;
          Navigator.of(context).pop();
          HelperUtils.showSnackBarMessage(
            context,
            'Payment Failed',
            type: MessageType.error,
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: WebViewWidget(controller: controllerGlobal!),
        ),
      ),
    );
  }
}
