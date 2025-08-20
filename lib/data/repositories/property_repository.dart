import 'dart:developer';

import 'package:perfectshelter/data/helper/filter.dart';
import 'package:perfectshelter/data/model/advertisement_model.dart';
import 'package:perfectshelter/data/model/compare_property_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PropertyRepository {
  Future<DataOutput<PropertyModel>> _fetchProperties(
      Map<String, dynamic> parameters) async {
    try {
      final response = await Api.get(
        url: Api.apiGetPropertyList,
        queryParameters: parameters..removeWhere((key, value) => value == null),
      );

      final modelList = (response['data'] as List)
          .cast<Map<String, dynamic>>()
          .map<PropertyModel>(PropertyModel.fromMap)
          .toList();

      return DataOutput(
        total: int.parse(response['total']?.toString() ?? '0'),
        modelList: modelList,
      );
    } on Exception catch (e, st) {
      log('Error fetching properties: $e \n $st');
      rethrow;
    }
  }

  ///This method will add property
  Future<dynamic> createProperty({
    required Map<String, dynamic> parameters,
  }) async {
    try {
      var api = Api.apiPostProperty;
      if (parameters['action_type'] == '0') {
        api = Api.apiUpdateProperty;
      }
      if (parameters.containsKey('gallery_images')) {
        if ((parameters['gallery_images'] as List).isEmpty) {
          parameters.remove('gallery_images');
        }
      }

      if (parameters.containsKey('documents')) {
        if ((parameters['documents'] as List).isEmpty) {
          parameters.remove('documents');
        }
      }
      if (parameters['title_image'] == null) {
        parameters.remove('title_image');
      }
      if (parameters['three_d_image'] == null ||
          parameters['three_d_image'] == '') {
        parameters.remove('three_d_image');
      }
      final response = await Api.post(url: api, parameter: parameters);

      return response;
    } on Exception catch (e, st) {
      log('createProperty error: $e \n $st');
    }
  }

  Future<PropertyModel> fetchPropertyFromPropertyId({
    required int id,
    required bool isMyProperty,
  }) async {
    try {
      final parameters = <String, dynamic>{
        Api.id: id,
        if (!isMyProperty) 'current_user': HiveUtils.getUserId(),
      };

      final response = await Api.get(
        url: isMyProperty ? Api.getAddedProperties : Api.apiGetPropertyDetails,
        queryParameters: parameters,
      );
      if (response['error'] == true) {
        throw ApiException(response['message'].toString());
      }

      final data = response['data'];

      // If data is a List, take the first item
      if (data is List && data.isNotEmpty) {
        return PropertyModel.fromMap(data.first as Map<String, dynamic>);
      }
      // If data is a Map
      else if (data is Map<String, dynamic>) {
        return PropertyModel.fromMap(data);
      }

      throw Exception('Invalid data format received from API');
    } on Exception catch (e) {
      log('Error is $e');
      await Fluttertoast.showToast(msg: e.toString());
    }
    return PropertyModel.fromMap({});
  }

  Future<void> deleteProperty(
    int id,
  ) async {
    try {
      await Api.post(
        url: Api.apiDeleteProperty,
        parameter: {Api.id: id},
      );
    } on Exception catch (e) {
      log('Error is $e');
    }
  }

  ///fetch most viewed properties
  Future<DataOutput<PropertyModel>> fetchMostViewedProperty({
    required int offset,
    required String latitude,
    required String longitude,
    required String radius,
  }) {
    return _fetchProperties({
      Api.mostViewed: '1',
      Api.offset: offset,
      Api.limit: Constant.loadLimit,
      Api.latitude: latitude,
      Api.longitude: longitude,
      Api.radius: radius,
    });
  }

  ///fetch advertised properties
  Future<DataOutput<PropertyModel>> fetchPromotedProperty({
    required int offset,
    required String latitude,
    required String longitude,
    required String radius,
    required bool sendCityName,
  }) {
    return _fetchProperties({
      Api.promoted: 1,
      Api.offset: offset,
      Api.limit: Constant.loadLimit,
      'current_user': HiveUtils.getUserId(),
      Api.latitude: latitude,
      Api.longitude: longitude,
      Api.radius: radius,
    });
  }

  Future<DataOutput<PropertyModel>> fetchNearByProperty({
    required int offset,
    required String latitude,
    required String longitude,
    required String radius,
  }) async {
    if (HiveUtils.getUserCityName() == null ||
        HiveUtils.getUserCityName().toString().isEmpty) {
      return Future.value(
        DataOutput(
          total: 0,
          modelList: [],
        ),
      );
    }
    return _fetchProperties({
      'id': HiveUtils.getUserId(),
      'city': HiveUtils.getUserCityName(),
      Api.offset: offset,
      'limit': Constant.loadLimit,
      'current_user': HiveUtils.getUserId(),
      Api.latitude: latitude,
      Api.longitude: longitude,
      Api.radius: radius,
    });
  }

  Future<DataOutput<PropertyModel>> fetchMostLikeProperty({
    required int offset,
    required String latitude,
    required String longitude,
    required String radius,
    required bool sendCityName,
  }) {
    return _fetchProperties({
      'most_liked': 1,
      'limit': Constant.loadLimit,
      'offset': offset,
      'current_user': HiveUtils.getUserId(),
      Api.latitude: latitude,
      Api.longitude: longitude,
      Api.radius: radius,
    });
  }

  Future<DataOutput<AdvertisementProperty>> fetchMyPromotedProeprties({
    required int offset,
  }) async {
    try {
      final parameters = <String, dynamic>{
        Api.offset: offset,
        Api.limit: Constant.loadLimit,
        Api.type: 'property',
        // "current_user": HiveUtils.getUserId()
      };

      final response = await Api.get(
        url: Api.getFeaturedData,
        queryParameters: parameters,
      );
      final modelList = (response['data'] as List)
          .cast<Map<String, dynamic>>()
          .map<AdvertisementProperty>(AdvertisementProperty.fromJson)
          .toList();

      return DataOutput(
        total: int.parse(response['total']?.toString() ?? '0'),
        modelList: modelList,
      );
    } on Exception catch (_) {
      rethrow;
    }
  }

  ///Search property
  Future<DataOutput<PropertyModel>> searchProperty(
    String searchQuery, {
    required int offset,
    FilterApply? filter,
  }) {
    return _fetchProperties({
      Api.search: searchQuery,
      Api.offset: offset,
      Api.limit: Constant.loadLimit,
      'current_user': HiveUtils.getUserId(),
      ...?filter?.getFilter().cast<String, dynamic>(),
    });
  }

  ///to get my properties which i had added to sell or rent
  Future<DataOutput<PropertyModel>> fetchMyProperties({
    required int offset,
    required String type,
    required String status,
  }) async {
    try {
      final propertyType = _findPropertyType(type.toLowerCase());

      final parameters = <String, dynamic>{
        Api.offset: offset,
        Api.limit: Constant.loadLimit,
        // Api.userid: HiveUtils.getUserId(),
        Api.propertyType: propertyType,
        'request_status': status,
        // "current_user": HiveUtils.getUserId()
      };

      if (status == 'all') {
        parameters.remove('request_status');
      }
      final response = await Api.get(
        url: Api.getAddedProperties,
        queryParameters: parameters,
      );
      final modelList = (response['data'] as List)
          .cast<Map<String, dynamic>>()
          .map<PropertyModel>(PropertyModel.fromMap)
          .toList();

      return DataOutput(
        total: int.parse(response['total']?.toString() ?? '0'),
        modelList: modelList,
      );
    } on Exception catch (e, st) {
      log('Error in my properties $e');
      log('$st');
    }
    return DataOutput(total: 0, modelList: []);
  }

  String? _findPropertyType(String type) {
    if (type.toLowerCase() == 'sell') {
      return '0';
    } else if (type.toLowerCase() == 'rent') {
      return '1';
    } else if (type.toLowerCase() == 'sold') {
      return '2';
    } else if (type.toLowerCase() == 'rented') {
      return '3';
    }
    return null;
  }

  Future<DataOutput<PropertyModel>> fetchPropertyFromCategoryId({
    required int id,
    required int offset,
    FilterApply? filter,
    bool? showPropertyType,
  }) {
    return _fetchProperties({
      Api.categoryId: id,
      Api.offset: offset,
      Api.limit: Constant.loadLimit,
      'current_user': HiveUtils.getUserId(),
      ...?filter?.getFilter().cast<String, dynamic>(),
    });
  }

  Future<dynamic> updatePropertyStatus({
    required dynamic propertyId,
    required dynamic status,
  }) async {
    await Api.post(
      url: Api.updatePropertyStatus,
      parameter: {'status': status, 'property_id': propertyId},
    );
  }

  Future<DataOutput<PropertyModel>> fetchPropertiesFromPlace({
    required int offset,
    String? placeId,
    String? city,
    String? state,
    String? country,
  }) {
    return _fetchProperties({
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (placeId != null) 'place_id': placeId,
      Api.limit: Constant.loadLimit,
      Api.offset: offset,
      'current_user': HiveUtils.getUserId(),
    });
  }

  Future<DataOutput<PropertyModel>> fetchAllProperties({
    required int offset,
    required String latitude,
    required String longitude,
    required String radius,
  }) {
    return _fetchProperties({
      Api.limit: Constant.loadLimit,
      Api.offset: offset,
      Api.latitude: latitude,
      Api.longitude: longitude,
      Api.radius: radius,
    });
  }

  Future<Map<String, dynamic>> changePropertyStatus({
    required int propertyId,
    required int status,
  }) async {
    final parameters = <String, dynamic>{
      Api.propertyId: propertyId,
      Api.status: status,
    };
    final response = await Api.post(
      url: Api.changePropertyStatus,
      parameter: parameters,
    );
    return response;
  }

  Future<PropertyModel> fetchBySlug(String slug) async {
    const apiUrl = Api.apiGetPropertyDetails;
    final result = await Api.get(
      url: apiUrl,
      queryParameters: {'slug_id': slug},
    );

    // Ensure 'data' is a List and safely extract the first item
    final data = result['data'];
    if (data is List && data.isNotEmpty) {
      final firstItem = data.first;
      if (firstItem is Map<String, dynamic>) {
        return PropertyModel.fromMap(firstItem);
      }
    }

    // Handle cases where data is null or in an unexpected format
    throw Exception('Invalid data format received');
  }

  Future<DataOutput<PropertyModel>> fetchSimilarProperty({
    required int propertyId,
  }) async {
    final parameters = <String, dynamic>{
      Api.propertyId: propertyId,
    };
    final response = await Api.get(
      url: Api.getAllSimilarProperties,
      queryParameters: parameters,
    );
    final modelList = (response['data'] as List)
        .cast<Map<String, dynamic>>()
        .map<PropertyModel>(PropertyModel.fromMap)
        .toList();
    return DataOutput(
      total: int.parse(response['total']?.toString() ?? '0'),
      modelList: modelList,
    );
  }

  Future<ComparePropertyModel> compareProperties({
    required int sourcePropertyId,
    required int targetPropertyId,
  }) async {
    try {
      final parameters = <String, dynamic>{
        'source_property_id': sourcePropertyId,
        'target_property_id': targetPropertyId,
      };
      final response = await Api.get(
        url: Api.compareProperties,
        queryParameters: parameters,
      );
      if (response['error'] == true) {
        throw ApiException(response['message']?.toString() ?? '');
      }
      final result = ComparePropertyModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );
      return result;
    } on Exception catch (e, st) {
      log('Error is $e $st');
      rethrow;
    }
  }

  Future<DataOutput<PropertyModel>> fetchPremiumProperty({
    required int offset,
    required String latitude,
    required String longitude,
    required String radius,
  }) {
    return _fetchProperties({
      'get_all_premium_properties': 1,
      Api.offset: offset,
      Api.limit: Constant.loadLimit,
      'current_user': HiveUtils.getUserId(),
      Api.latitude: latitude,
      Api.longitude: longitude,
      Api.radius: radius,
    });
  }
}
