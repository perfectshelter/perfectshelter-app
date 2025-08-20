import 'package:perfectshelter/data/model/data_output.dart';
import 'package:perfectshelter/data/model/property_model.dart';
import 'package:perfectshelter/utils/api.dart';
import 'package:perfectshelter/utils/constant.dart';

class FavoriteRepository {
  Future<void> addToFavorite(int id, String type) async {
    final paramerters = <String, dynamic>{Api.propertyId: id, Api.type: type};

    await Api.post(
      url: Api.addFavourite,
      parameter: paramerters,
    );
  }

  Future<DataOutput<PropertyModel>> fechFavorites({
    required int offset,
  }) async {
    final parameters = <String, dynamic>{
      Api.offset: offset,
      Api.limit: Constant.loadLimit,
    };

    final response = await Api.get(
      url: Api.getFavoriteProperty,
      queryParameters: parameters,
    );

    final modelList = (response['data'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map<PropertyModel>(PropertyModel.fromMap)
        .toList();

    return DataOutput<PropertyModel>(
      total: response['total'] as int? ?? 0,
      modelList: modelList,
    );
  }
}
