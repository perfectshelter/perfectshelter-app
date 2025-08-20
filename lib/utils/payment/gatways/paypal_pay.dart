import 'dart:developer';

import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/payment/gatways/paypal.dart';
import 'package:ebroker/utils/payment/lib/payment.dart';
import 'package:ebroker/utils/payment/lib/purchase_package.dart';

class Paypal extends Payment {
  SubscriptionPackageModel? _modal;
  @override
  void pay(BuildContext context) {
    if (_modal == null) {
      log('Please set modal');
    }
    isPaymentGatewayOpen = true;
    Navigator.push<dynamic>(
      context,
      CupertinoPageRoute(
        builder: (context) {
          return PaypalWidget(
            pacakge: _modal!,
            onSuccess: (msg) {
              Navigator.pop(context, {
                'msg': msg,
                'type': 'success',
              });
            },
            onFail: (msg) {
              Navigator.pop(context, {'msg': msg, 'type': 'fail'});
            },
          );
        },
      ),
    ).then((value) {
      //push and show dialog box about paypal success or failed, after that we call purchase method it will refresh API and check if package is purchased or not
      isPaymentGatewayOpen = false;
      if (value != null) {
        Future.delayed(
          const Duration(milliseconds: 1000),
          () {
            if (value['type'] == 'success') {
              emit(Success(message: 'Success'));
              Navigator.pop(context);
            } else if (value['type'] == 'Failed') {
              emit(Failure(message: 'Failed'));
              Navigator.pop(context);
            }
          },
        );
      }
    });
  }

  @override
  Paypal setPackage(SubscriptionPackageModel modal) {
    _modal = modal;
    return this;
  }

  @override
  Future<void> onEvent(
    BuildContext context,
    covariant PaymentStatus currentStatus,
  ) async {
    if (currentStatus is Success) {
      await PurchasePackage().purchase(context);
    }
  }
}
