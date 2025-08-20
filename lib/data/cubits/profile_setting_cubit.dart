import 'package:perfectshelter/data/helper/custom_exception.dart';
import 'package:perfectshelter/settings.dart';
import 'package:perfectshelter/utils/api.dart';
import 'package:perfectshelter/utils/constant.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ProfileSettingState {}

class ProfileSettingInitial extends ProfileSettingState {}

class ProfileSettingFetchProgress extends ProfileSettingState {}

class ProfileSettingFetchSuccess extends ProfileSettingState {
  ProfileSettingFetchSuccess({required this.data});

  String data;
}

class ProfileSettingFetchFailure extends ProfileSettingState {
  ProfileSettingFetchFailure(this.errmsg);
  final dynamic errmsg;
}

class ProfileSettingCubit extends Cubit<ProfileSettingState> {
  ProfileSettingCubit() : super(ProfileSettingInitial());

  Future<void> fetchProfileSetting(
    String title, {
    bool? forceRefresh,
  }) async {
    if (forceRefresh != true) {
      if (state is ProfileSettingFetchSuccess) {
        await Future<dynamic>.delayed(
          const Duration(seconds: AppSettings.hiddenAPIProcessDelay),
        );
      } else {
        emit(ProfileSettingFetchProgress());
      }
    } else {
      emit(ProfileSettingFetchProgress());
    }

    if (forceRefresh ?? false) {
      await fetchProfileSettingFromDb(title).then((value) {
        emit(ProfileSettingFetchSuccess(data: value ?? ''));
      }).catchError((dynamic e, stack) {
        emit(ProfileSettingFetchFailure(e));
      });
    } else {
      if (state is! ProfileSettingFetchSuccess) {
        await fetchProfileSettingFromDb(title).then((value) {
          emit(ProfileSettingFetchSuccess(data: value ?? ''));
        }).catchError((dynamic e, stack) {
          emit(ProfileSettingFetchFailure(e));
        });
      } else {
        emit(
          ProfileSettingFetchSuccess(
            data: (state as ProfileSettingFetchSuccess).data,
          ),
        );
      }
    }
  }

  Future<String?> fetchProfileSettingFromDb(
    String title,
  ) async {
    try {
      String? profileSettingData;
      final body = <String, String>{
        Api.type: title,
      };

      final response = await Api.get(
        url: Api.apiGetAppSettings,
        queryParameters: body,
        useAuthToken: false,
      );

      if (response[Api.error] as bool) {
        throw CustomException(response[Api.message]);
      }
      if (title == Api.currencySymbol) {
        // Constant.currencySymbol = getdata['data'].toString();
      } else if (title == Api.maintenanceMode) {
        Constant.maintenanceMode = response['data'].toString();
      } else {
        final data = response['data'] as Map<String, dynamic>;

        if (title == Api.termsAndConditions) {
          profileSettingData = data['terms_conditions'].toString();
          // .where((element) => element['type'] == "terms_conditions")
          // .first['data'];
        }

        if (title == Api.privacyPolicy) {
          profileSettingData = data['privacy_policy'].toString();
        }

        if (title == Api.aboutApp) {
          profileSettingData = data['about_us'].toString();
        }
      }

      return profileSettingData;
    } on Exception catch (_) {
      rethrow;
    }
  }
}
