//
// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';

import 'package:perfectshelter/data/model/subscription_pacakage_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class PaystackWidget extends StatefulWidget {
  const PaystackWidget({
    required this.pacakge,
    super.key,
    this.onSuccess,
    this.onFail,
  });
  final SubscriptionPackageModel pacakge;
  final dynamic Function(dynamic msg)? onSuccess;
  final dynamic Function(dynamic msg)? onFail;

  @override
  State<PaystackWidget> createState() => _PaystackWidgetState();
}

class _PaystackWidgetState extends State<PaystackWidget> {
  WebViewController? controllerGlobal;
  bool _isLoading = true;
  String paymentTransactionID = '';

  @override
  void initState() {
    super.initState();
    webViewInitiliased();
  }

  Future<void> webViewInitiliased() async {
    final webViewUrl = await createPaymentIntent(context);
    if (webViewUrl.isEmpty) {
      await HelperUtils.showSnackBarMessage(
        context,
        'Failed to create payment intent',
      );
      Navigator.pop(context);
      return;
    }

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);

    await controller.enableZoom(false);
    await controller.loadRequest(
      Uri.parse(webViewUrl),
      headers: {'Authorization': 'Bearer ${HiveUtils.getJWT()}'},
    );
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.addJavaScriptChannel(
      'Toaster',
      onMessageReceived: (message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: CustomText(message.message)));
      },
    );
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          log('onPageStarted $url');
          _updateBackButtonStatus(controller);
        },
        onPageFinished: (url) {
          log('onPageFinished $url');
          _updateBackButtonStatus(controller);
        },
        onWebResourceError: (error) {
          log('onWebResourceError $error');
        },
        onNavigationRequest: (request) {
          if (request.url.contains('paystack') ||
              request.url.contains('flutterwave')) {
            final url = request.url;
            if ((request.url.contains('flutterwave') &&
                    url.contains('status=successful')) ||
                (request.url.contains('paystack') && url.contains('success'))) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            } else if (url.contains('failure')) {
              paymentTransactionFail();

              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            } else if (url.contains('cancel')) {
              paymentTransactionFail();
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }
          }
          return NavigationDecision.navigate;
        },
        onHttpError: (httpError) {
          log('onHttpError $httpError');
        },
        onProgress: (progress) {
          log('onProgress $progress');
        },
        onUrlChange: (change) {
          final uri = Uri.parse(change.url ?? '');

          if (uri.host == Uri.parse(AppSettings.baseUrl).host) {
            try {
              if (uri.pathSegments.contains('success')) {
                widget.onSuccess?.call('Payment Successful');
                HelperUtils.showSnackBarMessage(context, 'Payment Successful');
                Navigator.pop(context);
              } else {
                Future.delayed(Duration.zero, () {
                  HelperUtils.showSnackBarMessage(context, 'Payment Failed');
                  Navigator.pop(context);
                });
              }
            } on Exception catch (_) {
              Navigator.pop(context);
            }
          } else {
            launchUrl(uri);
          }
        },
      ),
    );

    if (controller.platform is AndroidWebViewController) {
      await AndroidWebViewController.enableDebugging(true);
      await (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    setState(() {
      controllerGlobal = controller;
      _isLoading = false;
    });
  }

  // New method to update back button status
  Future<void> _updateBackButtonStatus(WebViewController controller) async {
    await controller.canGoBack();
    setState(() {});
  }

  Future<String> createPaymentIntent(BuildContext context) async {
    final response = await Api.post(
      url: Api.createPaymentIntent,
      parameter: {'platform_type': 'app', 'package_id': widget.pacakge.id},
    );

    if (response['error'] == false) {
      final paymentIntent = response['data']['payment_intent'];
      final authorizationUrl = paymentIntent['payment_gateway_response']['data']
              ['authorization_url']
          ?.toString();
      paymentTransactionID =
          paymentIntent['payment_transaction_id']?.toString() ?? '';

      // Redirect to Paystack's checkout page
      if (authorizationUrl != null) {
        return authorizationUrl;
      } else {
        await HelperUtils.showSnackBarMessage(
          context,
          'Authorization URL not found',
        );
      }
    } else {
      await HelperUtils.showSnackBarMessage(
        context,
        'Failed to create payment intent',
      );
      return '';
    }
    return '';
  }

  Future<void> paymentTransactionFail() async {
    try {
      await Api.post(
        url: Api.paymentTransactionFail,
        parameter: {'payment_transaction_id': paymentTransactionID},
      );
    } on Exception catch (e) {
      log('Failed to cancel payment transaction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.secondaryColor,
      appBar: CustomAppBar(
        onTapBackButton: () async {
          await HelperUtils.showSnackBarMessage(context, 'Payment Failed');
          await paymentTransactionFail();
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : controllerGlobal != null
                ? WebViewWidget(controller: controllerGlobal!)
                : const Center(child: Text('Failed to load payment page')),
      ),
    );
  }
}
