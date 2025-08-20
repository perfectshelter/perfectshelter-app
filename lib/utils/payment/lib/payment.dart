import 'package:perfectshelter/data/model/subscription_pacakage_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

///THIS IS MAIN ABSTRACTION FOR [Payment].
///Inherit Payment to add new payment gateway , like class GooglePay extends Payment{}
///
///This payment gateway code is written by Muzammil Sumra
abstract class Payment {
  ///This will open paymentgatway
  void pay(BuildContext context);

  ///This is status listener for payment
  final ValueNotifier<PaymentStatus> _stateListener = ValueNotifier(INITIAL());

  ///This abstraction will call when status change
  void onEvent(BuildContext context, covariant PaymentStatus currentStatus);

  ///This will change payment status
  @protected
  void emit(PaymentStatus status) {
    _stateListener.value = status;
  }

  ///This is internal method to listen status for payment
  @nonVirtual
  void listen(void Function(PaymentStatus status) listener) {
    _stateListener.addListener(() {
      listener.call(_stateListener.value);
    });
  }

  ///This will set current subscription modal .
  Payment setPackage(SubscriptionPackageModel modal);
}

bool isPaymentGatewayOpen = false;

///THESE STATUS ARE PAYMENT STATUS
abstract class PaymentStatus {}

class Success extends PaymentStatus {
  Success({
    required this.message,
    this.extraData,
  });
  final String message;
  final Map<dynamic, dynamic>? extraData;
}

class Failure extends PaymentStatus {
  Failure({
    required this.message,
    this.extraData,
  });
  final String message;
  final Map<dynamic, dynamic>? extraData;
}

class INITIAL extends PaymentStatus {}
