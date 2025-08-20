import 'package:perfectshelter/data/repositories/subscription_repository.dart';
import 'package:perfectshelter/exports/main_export.dart';

abstract class AssignInAppPackageState {}

class AssignInAppPackageInitial extends AssignInAppPackageState {}

class AssignInAppPackageInProgress extends AssignInAppPackageState {}

class AssignInAppPackageSuccess extends AssignInAppPackageState {}

class AssignInAppPackageFail extends AssignInAppPackageState {
  AssignInAppPackageFail(this.error);
  final dynamic error;
}

class AssignInAppPackageCubit extends Cubit<AssignInAppPackageState> {
  AssignInAppPackageCubit() : super(AssignInAppPackageInitial());
  final SubscriptionRepository _subscriptionRepository =
      SubscriptionRepository();

  ///
  ///This will assign in app product
  Future<void> assign({
    required String packageId,
    required String productId,
  }) async {
    try {
      emit(AssignInAppPackageInProgress());
      await _subscriptionRepository.assignPackage(
        packageId: packageId,
        productId: productId,
      );
      emit(AssignInAppPackageSuccess());
    } on Exception catch (e) {
      emit(AssignInAppPackageFail(e));
    }
  }
}
