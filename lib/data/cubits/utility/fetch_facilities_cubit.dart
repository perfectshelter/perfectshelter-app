import 'package:perfectshelter/data/model/facilities_model.dart';
import 'package:perfectshelter/data/repositories/facilities_repository.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class FetchFacilitiesState {}

class FetchFacilitiesInitial extends FetchFacilitiesState {}

class FetchFacilitiesLoading extends FetchFacilitiesState {}

class FetchFacilitiesSuccess extends FetchFacilitiesState {
  FetchFacilitiesSuccess({required this.facilities});
  final List<FacilitiesModel> facilities;
}

class FetchFacilitiesCubit extends Cubit<FetchFacilitiesState> {
  FetchFacilitiesCubit() : super(FetchFacilitiesInitial());
  final FacilitiesRepository _facilitiesRepository = FacilitiesRepository();

  Future<void> fetch() async {
    emit(FetchFacilitiesLoading());
    final facilities = await _facilitiesRepository.fetchFacilities();
    emit(FetchFacilitiesSuccess(facilities: facilities));
  }
}
