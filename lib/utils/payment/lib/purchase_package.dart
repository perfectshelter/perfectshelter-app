import 'package:perfectshelter/data/cubits/subscription/fetch_subscription_packages_cubit.dart';
import 'package:perfectshelter/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:perfectshelter/utils/helper_utils.dart';
import 'package:perfectshelter/utils/ui_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PurchasePackage {
  Future<void> purchase(BuildContext context) async {
    try {
      // Capture what you need from the context before any navigation occurs
      final fetchSettingsCubit = context.read<FetchSystemSettingsCubit>();
      final fetchPackagesCubit = context.read<FetchSubscriptionPackagesCubit>();

      // Perform the operations
      await fetchSettingsCubit.fetchSettings(
        isAnonymous: false,
        forceRefresh: true,
      );
      await fetchPackagesCubit.fetchPackages();

      // Show success message
      await HelperUtils.showSnackBarMessage(
        context,
        UiUtils.translate(context, 'success'),
        type: MessageType.success,
        messageDuration: 5,
      );

      // Navigate after completing the operations
      Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
    } on Exception catch (_) {
      // Show error message if context is still valid
      await HelperUtils.showSnackBarMessage(
        context,
        UiUtils.translate(context, 'purchaseFailed'),
        type: MessageType.error,
      );
      rethrow;
    }
  }
}
