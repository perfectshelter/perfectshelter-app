import 'dart:developer';

import 'package:perfectshelter/data/model/subscription_pacakage_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/utils/payment/lib/payment.dart';
import 'package:perfectshelter/utils/payment/lib/purchase_package.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPay extends Payment {
  late SubscriptionPackageModel? _model;
  String? orderId;
  String? paymentTransactionID;

  @override
  Future<void> onEvent(
    BuildContext context,
    covariant PaymentStatus currentStatus,
  ) async {
    if (currentStatus is Success) {
      await PurchasePackage().purchase(context);
    }
  }

  Future<bool> createPaymentIntent(BuildContext context) async {
    try {
      final response = await Api.post(
        url: Api.createPaymentIntent,
        parameter: {
          'platform_type': 'app',
          'package_id': _model!.id,
        },
      );

      if (response['error'] == false) {
        // Extract the required data from the API response
        orderId = response['data']['payment_intent']['id']?.toString();
        paymentTransactionID = response['data']['payment_intent']
                ['payment_transaction_id']
            ?.toString();

        return true;
      } else {
        await HelperUtils.showSnackBarMessage(
          context,
          'Failed to create payment intent: ${response['message']}',
        );
        return false;
      }
    } on Exception catch (e) {
      await HelperUtils.showSnackBarMessage(
        context,
        'Failed to create payment intent: $e',
      );
      return false;
    }
  }

  Future<void> paymentTransactionFail() async {
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

  @override
  Future<void> pay(BuildContext context) async {
    // First create the payment intent and get the order ID
    final success = await createPaymentIntent(context);

    if (!success) return;

    final razorpay = Razorpay();

    // Use the data from the payment intent
    final options = {
      'key': Constant.razorpayKey,
      'amount': _model!.price, // Use the amount from API response
      'order_id': orderId, // Use the order ID from API response
      'name': _model!.name,
      'description': '',
      'prefill': {
        'contact': HiveUtils.getUserDetails().mobile,
        'email': HiveUtils.getUserDetails().email,
      },
      'notes': {
        'package_id': _model!.id,
        'user_id': HiveUtils.getUserId(),
        'payment_transaction_id': paymentTransactionID,
      },
    };

    if (Constant.razorpayKey != '') {
      isPaymentGatewayOpen = true;

      razorpay
        ..open(options)
        ..on(
          Razorpay.EVENT_PAYMENT_SUCCESS,
          (
            PaymentSuccessResponse response,
          ) async {
            isPaymentGatewayOpen = false;
            emit(Success(message: 'Success'));
          },
        )
        ..on(
          Razorpay.EVENT_PAYMENT_ERROR,
          (PaymentFailureResponse response) {
            isPaymentGatewayOpen = false;
            emit(Failure(message: 'failure'));
            HelperUtils.showSnackBarMessage(
              context,
              UiUtils.translate(context, 'purchaseFailed'),
            );
            paymentTransactionFail();
          },
        )
        ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse e) {
          isPaymentGatewayOpen = false;
          paymentTransactionFail();
          log('ISSUE IS ON RAZORPAY ITSELF $e');
        })
        ..on(
          Razorpay.EVENT_EXTERNAL_WALLET,
          (ExternalWalletResponse e) {
            log('External wallet response is $e');
          },
        );
    } else {
      await paymentTransactionFail();
      await HelperUtils.showSnackBarMessage(
        context,
        UiUtils.translate(context, 'setAPIkey'),
      );
    }
  }

  @override
  Payment setPackage(SubscriptionPackageModel modal) {
    _model = modal;
    return this;
  }
}
