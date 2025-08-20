import 'package:perfectshelter/data/helper/custom_exception.dart';
import 'package:perfectshelter/data/model/company.dart';
import 'package:perfectshelter/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CompanyState {}

class CompanyInitial extends CompanyState {}

class CompanyFetchProgress extends CompanyState {}

class CompanyFetchSuccess extends CompanyState {
  CompanyFetchSuccess(this.companyData);
  Company companyData;
}

class CompanyFetchFailure extends CompanyState {
  CompanyFetchFailure(this.error);
  final dynamic error;
}

class CompanyCubit extends Cubit<CompanyState> {
  CompanyCubit() : super(CompanyInitial());

  void fetchCompany() {
    emit(CompanyFetchProgress());
    fetchCompanyFromDb()
        .then((value) => emit(CompanyFetchSuccess(value)))
        .catchError((Object e) => emit(CompanyFetchFailure(e)));
  }

  Future<Company> fetchCompanyFromDb() async {
    try {
      final body = <String, String>{
        Api.type: Api.company,
      };

      final response = await Api.get(
        url: Api.apiGetAppSettings,
        queryParameters: body,
      );

      if (response[Api.error] as bool) {
        throw CustomException(response[Api.message]);
      }

      return Company.fromJson(response['data'] as Map<String, dynamic>);
    } on Exception catch (_) {
      rethrow;
    }
  }
}
