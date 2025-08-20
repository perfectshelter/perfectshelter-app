import 'dart:developer';

import 'package:ebroker/data/model/home_page_data_model.dart';
import 'package:ebroker/exports/main_export.dart';

class HomeScreenDataRepository {
  Future<({HomePageDataModel homepageDataModel})> fetchAllHomePageData() async {
    try {
      final parameters = {
        'latitude': HiveUtils.getLatitude(),
        'longitude': HiveUtils.getLongitude(),
        'radius': HiveUtils.getRadius().toString() == AppSettings.minRadius
            ? ''
            : HiveUtils.getRadius(),
      }..removeWhere((key, value) => value == '' || value == null);

      final result = await Api.get(
        url: Api.homePageData,
        queryParameters: parameters,
      );
      final data = result['data'] as Map<String, dynamic>;

      return (homepageDataModel: HomePageDataModel.fromJson(data));
    } on Exception catch (e, st) {
      log(
        e.toString(),
        stackTrace: st,
        name: 'HOME PAGE DATA ERROR:',
      );
      rethrow;
    }
  }
}
