import 'dart:developer';

import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/encryption/rsa.dart';

class GetApiKeysCubit extends Cubit<GetApiKeysState> {
  GetApiKeysCubit() : super(GetApiKeysInitial());

  Future<void> fetch() async {
    try {
      emit(GetApiKeysInProgress());

      final result = await Api.get(
        url: Api.getPaymentApiKeys,
        queryParameters: {},
      );

      if (result['error'] == true) {
        emit(GetApiKeysFail(result['message']));
        return;
      }

      final data = result['data'] as List? ?? [];
      if (data.isEmpty) {
        emit(GetApiKeysFail('No data found'));
        return;
      }
      final bankTransferStatus = _getDataFromKey(data, 'bank_transfer_status');
      final flutterwaveStatus = _getDataFromKey(data, 'flutterwave_status');
      final razorpayKey = _getDataFromKey(data, 'razor_key');
      final paystackPublicKey = _getDataFromKey(data, 'paystack_public_key');
      final paystackCurrency = _getDataFromKey(data, 'paystack_currency');
      final stripeCurrency = _getDataFromKey(data, 'stripe_currency');
      final stripePublishableKey =
          _getDataFromKey(data, 'stripe_publishable_key');
      final stripeSecretKey = _getDataFromKey(data, 'stripe_secret_key');
      var enabledGatway = '';
      if (_getDataFromKey(data, 'paypal_gateway') == '1') {
        enabledGatway = 'paypal';
      } else if (_getDataFromKey(data, 'razorpay_gateway') == '1') {
        enabledGatway = 'razorpay';
      } else if (_getDataFromKey(data, 'paystack_gateway') == '1') {
        enabledGatway = 'paystack';
      } else if (_getDataFromKey(data, 'stripe_gateway') == '1') {
        enabledGatway = 'stripe';
      } else if (flutterwaveStatus == '1') {
        enabledGatway = 'flutterwave';
      }

      emit(
        GetApiKeysSuccess(
          bankTransferStatus: bankTransferStatus?.toString() ?? '',
          razorPayKey: razorpayKey?.toString() ?? '',
          enabledPaymentGatway: enabledGatway,
          paystackPublicKey: paystackPublicKey?.toString() ?? '',
          paystackCurrency: paystackCurrency?.toString() ?? '',
          stripeCurrency: stripeCurrency?.toString() ?? '',
          stripePublishableKey: stripePublishableKey?.toString() ?? '',
          stripeSecretKey: stripeSecretKey?.toString() ?? '',
          flutterwaveStatus: flutterwaveStatus?.toString() ?? '',
        ),
      );
    } on Exception catch (e) {
      emit(GetApiKeysFail(e.toString()));
    }
  }

  void setAPIKeys() {
    //setKeys
    if (state is GetApiKeysSuccess) {
      final st = state as GetApiKeysSuccess;

      AppSettings.paystackKey = st.paystackPublicKey;
      AppSettings.razorpayKey = st.razorPayKey;
      AppSettings.enabledPaymentGatway = st.enabledPaymentGatway;
      AppSettings.paystackCurrency = st.paystackCurrency;
      AppSettings.stripeCurrency = st.stripeCurrency;
      AppSettings.stripePublishableKey = st.stripePublishableKey;
      AppSettings.stripeSecrateKey = RSAEncryption().decrypt(
        privateKey: Constant.keysDecryptionPasswordRSA,
        encryptedData: st.stripeSecretKey,
      );
    }
    if (state is GetApiKeysFail) {
      log((state as GetApiKeysFail).error.toString(), name: 'API KEY FAIL');
    }
  }

  dynamic _getDataFromKey(List<dynamic> data, String key) {
    final listData =
        data.where((element) => element['type'] == key).toList().first as Map;
    try {
      return listData['data'];
    } on Exception catch (e) {
      if (e.toString().contains('Bad state')) {
        log('The key>>> $key is not comming from API');
      }
    }
  }
}

abstract class GetApiKeysState {}

class GetApiKeysInitial extends GetApiKeysState {}

class GetApiKeysInProgress extends GetApiKeysState {}

class GetApiKeysSuccess extends GetApiKeysState {
  GetApiKeysSuccess({
    required this.bankTransferStatus,
    required this.razorPayKey,
    required this.paystackPublicKey,
    required this.paystackCurrency,
    required this.enabledPaymentGatway,
    required this.stripeCurrency,
    required this.stripePublishableKey,
    required this.stripeSecretKey,
    required this.flutterwaveStatus,
  });
  final String bankTransferStatus;
  final String razorPayKey;
  final String paystackPublicKey;
  final String paystackCurrency;
  final String enabledPaymentGatway;
  final String stripeCurrency;
  final String stripePublishableKey;
  final String stripeSecretKey;
  final String flutterwaveStatus;

  @override
  String toString() {
    return '''GetApiKeysSuccess(razorPayKey: $razorPayKey, paystackPublicKey: $paystackPublicKey, paystackCurrency: $paystackCurrency, enabledPaymentGatway: $enabledPaymentGatway, stripeCurrency: $stripeCurrency, stripePublishableKey: $stripePublishableKey, stripeSecretKey: $stripeSecretKey, flutterwaveStatus: $flutterwaveStatus)''';
  }
}

class GetApiKeysFail extends GetApiKeysState {
  GetApiKeysFail(this.error);
  final dynamic error;
}
