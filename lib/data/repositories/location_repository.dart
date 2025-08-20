import 'package:dio/dio.dart';
import 'package:perfectshelter/data/model/google_place_model.dart';
import 'package:perfectshelter/utils/api.dart';
import 'package:perfectshelter/utils/constant.dart';

final String demoPlaceApiKey = Constant.googlePlaceAPIkey;

class GooglePlaceRepository {
  //This will search places from google place api
  //We use this to search location while adding new property
  Future<List<GooglePlaceModel>> serchCities(String text) async {
    try {
      ///
      ///************************ */
      final queryParameters = <String, dynamic>{
        Api.placeApiKey: demoPlaceApiKey,
        Api.input: text,
        'language': 'en',
      };

      ///************************ */

      final apiResponse = await Api.get(
        url: Api.placeAPI,
        useAuthToken: false,
        useBaseUrl: false,
        queryParameters: queryParameters,
      );
      return _buildPlaceModelList(apiResponse);
    } on Exception catch (e) {
      if (e is DioException) {}
      throw ApiException(e.toString());
    }
  }

  ///this will convert normal response to List of models
  ///so we can use it easily in code
  List<GooglePlaceModel> _buildPlaceModelList(
    Map<String, dynamic> apiResponse,
  ) {
    ///loop throuh predictions list,
    ///this will create List of GooglePlaceModel
    try {
      final predictions = apiResponse['predictions'] as List<dynamic>;
      final filteredResult = predictions.map((prediction) {
        final description = prediction['description']?.toString() ?? '';
        final placeId = prediction['place_id']?.toString() ?? '';

        final terms = prediction['terms'] as List<dynamic>;
        final city = terms
                .firstWhere(
                  (term) => term['value'] != null,
                  orElse: () => <dynamic, dynamic>{},
                )['value']
                ?.toString() ??
            '';
        final state =
            terms.length > 1 ? terms[1]['value']?.toString() ?? '' : '';
        final country =
            terms.length > 2 ? terms[2]['value']?.toString() ?? '' : '';

        return GooglePlaceModel(
          city: city,
          description: description,
          placeId: placeId,
          state: state,
          country: country,
          latitude: '',
          longitude: '',
        );
      }).toList();

      return filteredResult;
    } on Exception catch (_) {
      rethrow;
    }
  }

  String getLocationComponent(Map<dynamic, dynamic> details, String component) {
    final index = (details['types'] as List).indexWhere(
      (element) => element == component,
    );
    if ((details['terms'] as List).length > index) {
      return (details['terms'] as List).elementAt(index)['value']?.toString() ??
          '';
    } else {
      return '';
    }
  }

  ///Google Place Autocomplete api will give us Place Id.
  ///We will use this place id to get Place Details
  Future<dynamic> getPlaceDetailsFromPlaceId(String placeId) async {
    final queryParameters = <String, dynamic>{
      Api.placeApiKey: demoPlaceApiKey,
      Api.placeid: placeId,
      'language': 'en',
    };
    final response = await Api.get(
      url: Api.placeApiDetails,
      queryParameters: queryParameters,
      useBaseUrl: false,
      useAuthToken: false,
    );

    return response['result']['geometry']['location'];
  }
}
