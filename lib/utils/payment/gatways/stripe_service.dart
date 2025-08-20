import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:perfectshelter/settings.dart';
import 'package:perfectshelter/utils/api.dart';
import 'package:perfectshelter/utils/payment/lib/payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  static String apiBase = 'https://api.stripe.com/v1';
  static String paymentApiUrl = '${StripeService.apiBase}/payment_intents';
  static String? secret;
  static String? paymentTransactionID;

  static Map<String, String> headers = {
    'Authorization': 'Bearer ${StripeService.secret}',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  static Map<String, String> getHeaders() => {
        'Authorization': 'Bearer ${StripeService.secret}',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

  static void init({String? stripePublishable, String? stripeSecrate}) {
    Stripe.publishableKey = stripePublishable ?? '';
    StripeService.secret = stripeSecrate;

    Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
    if (Stripe.publishableKey == '') {
      log('Please add stripe publishable key');
    } else if (StripeService.secret == null) {
      log('Please add stripe secret key');
    }
  }

  static Future<StripeTransactionResponse> payWithPaymentSheet({
    required num amount,
    required bool isTestEnvironment,
    required String awaitedOrderId,
    String? currency,
    String? from,
    BuildContext? context,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      //create Payment intent
      isPaymentGatewayOpen = true;
      final createPaymentIntent = await StripeService.createPaymentIntent(
        amount: amount,
        currency: currency,
        from: from,
        context: context,
        metadata: metadata,
        awaitedOrderID: awaitedOrderId,
      );

      if (createPaymentIntent == null) {
        isPaymentGatewayOpen = false;
        return StripeTransactionResponse(
          message: 'Failed to create payment intent',
          success: false,
          status: 'failed',
        );
      }

      // Extract the client secret correctly
      final paymentIntent =
          createPaymentIntent['payment_intent'] as Map<String, dynamic>? ?? {};
      final paymentGatewayResponse =
          paymentIntent['payment_gateway_response'] as Map<String, dynamic>? ??
              {};
      final clientSecret =
          paymentGatewayResponse['client_secret']?.toString() ?? '';
      final paymentIntentId = paymentIntent['id']?.toString() ?? '';
      paymentTransactionID =
          paymentIntent['payment_transaction_id']?.toString() ?? '';

      if (clientSecret.isEmpty) {
        isPaymentGatewayOpen = false;
        return StripeTransactionResponse(
          message: 'Invalid client secret from server',
          success: false,
          status: 'failed',
        );
      }

      //setting up Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          allowsDelayedPaymentMethods: true,
          billingDetailsCollectionConfiguration:
              const BillingDetailsCollectionConfiguration(
            address: AddressCollectionMode.full,
            email: CollectionMode.always,
            name: CollectionMode.always,
            phone: CollectionMode.always,
          ),
          style: ThemeMode.light,
          merchantDisplayName: AppSettings.applicationName,
        ),
      );

      //open payment sheet
      await Stripe.instance.presentPaymentSheet();

      // After successful presentation, retrieve the payment intent status
      final response = await Dio().get<dynamic>(
        '${StripeService.paymentApiUrl}/$paymentIntentId',
        options: Options(headers: getHeaders()),
      );

      final getdata = Map<String, dynamic>.from(
        response.data as Map<String, dynamic>? ?? {},
      );
      final statusOfTransaction = getdata['status'];
      log('--stripe response $getdata');

      if (statusOfTransaction == 'succeeded') {
        isPaymentGatewayOpen = false;
        return StripeTransactionResponse(
          message: 'Transaction successful',
          success: true,
          status: statusOfTransaction?.toString() ?? '',
        );
      } else if (statusOfTransaction == 'pending' ||
          statusOfTransaction == 'captured') {
        isPaymentGatewayOpen = false;
        return StripeTransactionResponse(
          message: 'Transaction pending',
          success: true,
          status: statusOfTransaction?.toString() ?? '',
        );
      } else {
        isPaymentGatewayOpen = false;
        await paymentTransactionFail(
          paymentTransactionID: paymentTransactionID ?? '',
        );
        return StripeTransactionResponse(
          message: 'Transaction failed: $statusOfTransaction',
          success: false,
          status: statusOfTransaction?.toString() ?? '',
        );
      }
    } on PlatformException catch (err) {
      log('Platform issue: ${err.message}, code: ${err.code}, details: ${err.details}');
      isPaymentGatewayOpen = false;
      await paymentTransactionFail(
        paymentTransactionID: paymentTransactionID ?? '',
      );
      return StripeService.getPlatformExceptionErrorResult(err);
    } on Exception catch (error) {
      log('Other issue: $error');
      isPaymentGatewayOpen = false;
      await paymentTransactionFail(
        paymentTransactionID: paymentTransactionID ?? '',
      );

      return StripeTransactionResponse(
        message: 'Transaction failed: $error',
        success: false,
        status: 'fail',
      );
    }
  }

  static StripeTransactionResponse getPlatformExceptionErrorResult(
    dynamic err,
  ) {
    var message = 'Something went wrong';
    if (err.code == 'cancelled') {
      message = 'Transaction cancelled';
    }

    return StripeTransactionResponse(
      message: message,
      success: false,
      status: 'cancelled',
    );
  }

  static Future<void> paymentTransactionFail({
    required String paymentTransactionID,
  }) async {
    try {
      await Api.post(
        url: Api.paymentTransactionFail,
        parameter: {
          'payment_transaction_id': paymentTransactionID,
        },
      );
    } on Exception catch (e) {
      log('Failed to cancel payment transaction: $e');
    }
  }

  static Future<Map<String, dynamic>?> createPaymentIntent({
    required num amount,
    required String awaitedOrderID,
    String? currency,
    String? from,
    BuildContext? context,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final parameter = <String, dynamic>{
        'amount': amount,
        'currency': currency,
        'description': metadata?['packageName'],
        'metadata': metadata,
      };

      log('Creating payment intent with parameters: $parameter');

      final response = await Api.post(
        url: Api.createPaymentIntent,
        parameter: {
          'platform_type': 'app',
          'package_id': awaitedOrderID,
        },
      );

      log('Payment intent response: $response');

      // Return the entire data object that contains payment_intent
      return response['data'] as Map<String, dynamic>?;
    } on Exception catch (e) {
      isPaymentGatewayOpen = false;
      if (e is DioException) {
        if (e.response != null && e.response!.data != null) {
          log('Stripe API Error: ${e.response!.data}');
          log('Stripe API Status: ${e.response!.statusCode}');
        } else {
          log('Dio Error: ${e.message}');
        }
      } else {
        log('Error creating payment intent: $e');
      }
      return null;
    }
  }
}

class StripeTransactionResponse {
  StripeTransactionResponse({this.message, this.success, this.status});
  final String? message;
  final String? status;
  bool? success;
}

Future<void> openStripePaymentGateway({
  required double amount,
  required String awaitedOrderID,
  required Map<String, dynamic> metadata,
  required VoidCallback onSuccess,
  required dynamic Function(dynamic message) onError,
}) async {
  try {
    StripeService.init(
      stripePublishable: AppSettings.stripePublishableKey,
      stripeSecrate: AppSettings.stripeSecrateKey,
    );

    final response = await StripeService.payWithPaymentSheet(
      amount: amount * 100,
      currency: AppSettings.stripeCurrency,
      isTestEnvironment: true,
      metadata: metadata,
      awaitedOrderId: awaitedOrderID,
    );

    if (response.status == 'succeeded') {
      onSuccess.call();
    } else {
      onError.call(response.message);
    }
  } on Exception catch (e) {
    log('ERROR IS $e');
    onError.call('Payment failed: $e');
  }
}
