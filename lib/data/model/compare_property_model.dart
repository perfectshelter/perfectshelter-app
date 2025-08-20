class ComparePropertyModel {
  ComparePropertyModel({this.sourceProperty, this.targetProperty});

  ComparePropertyModel.fromJson(Map<String, dynamic> json) {
    sourceProperty = json['source_property'] != null
        ? SourceProperty.fromJson(
            json['source_property'] as Map<String, dynamic>? ?? {},
          )
        : null;
    targetProperty = json['target_property'] != null
        ? TargetProperty.fromJson(
            json['target_property'] as Map<String, dynamic>? ?? {},
          )
        : null;
  }
  SourceProperty? sourceProperty;
  TargetProperty? targetProperty;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (sourceProperty != null) {
      data['source_property'] = sourceProperty?.toJson();
    }
    if (targetProperty != null) {
      data['target_property'] = targetProperty?.toJson();
    }
    return data;
  }
}

class SourceProperty {
  SourceProperty({
    this.id,
    this.title,
    this.translatedTitle,
    this.titleImage,
    this.city,
    this.state,
    this.country,
    this.address,
    this.createdAt,
    this.price,
    this.rentduration,
    this.propertyType,
    this.totalLikes,
    this.totalViews,
    this.facilities,
    this.nearByPlaces,
  });

  SourceProperty.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int;
    title = json['title']?.toString() ?? '';
    translatedTitle = json['translated_title']?.toString() ?? '';
    titleImage = json['title_image']?.toString() ?? '';
    city = json['city']?.toString() ?? '';
    state = json['state']?.toString() ?? '';
    country = json['country']?.toString() ?? '';
    address = json['address']?.toString() ?? '';
    createdAt = json['created_at']?.toString() ?? '';
    price = json['price']?.toString() ?? '';
    rentduration = json['rentduration']?.toString() ?? '';
    propertyType = json['property_type']?.toString() ?? '';
    totalLikes = json['total_likes']?.toString() ?? '0';
    totalViews = json['total_views']?.toString() ?? '0';
    if (json['facilities'] != null) {
      facilities = <Facilities>[];
      json['facilities'].forEach((dynamic v) {
        facilities!.add(Facilities.fromJson(v as Map<String, dynamic>? ?? {}));
      });
    }
    if (json['near_by_places'] != null) {
      nearByPlaces = <NearByPlaces>[];
      json['near_by_places'].forEach((dynamic v) {
        nearByPlaces!
            .add(NearByPlaces.fromJson(v as Map<String, dynamic>? ?? {}));
      });
    }
  }
  int? id;
  String? title;
  String? translatedTitle;
  String? titleImage;
  String? city;
  String? state;
  String? country;
  String? address;
  String? createdAt;
  String? price;
  String? rentduration;
  String? propertyType;
  String? totalLikes;
  String? totalViews;
  List<Facilities>? facilities;
  List<NearByPlaces>? nearByPlaces;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['translated_title'] = translatedTitle;
    data['title_image'] = titleImage;
    data['city'] = city;
    data['state'] = state;
    data['country'] = country;
    data['address'] = address;
    data['created_at'] = createdAt;
    data['price'] = price;
    data['rentduration'] = rentduration;
    data['property_type'] = propertyType;
    data['total_likes'] = totalLikes;
    data['total_views'] = totalViews;
    if (facilities != null) {
      data['facilities'] = facilities!.map((v) => v.toJson()).toList();
    }
    if (nearByPlaces != null) {
      data['near_by_places'] = nearByPlaces!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Facilities {
  Facilities({
    this.id,
    this.name,
    this.translatedName,
    this.image,
    this.isRequired,
    this.typeOfParameter,
    this.typeValues,
    this.value,
  });

  Facilities.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int;
    name = json['name']?.toString() ?? '';
    translatedName = json['translated_name']?.toString() ?? '';
    image = json['image']?.toString() ?? '';
    isRequired = json['is_required']?.toString() ?? '0';
    typeOfParameter = json['type_of_parameter']?.toString() ?? '';
    typeValues = (json['type_values'] as List<dynamic>?)?.cast<String>() ?? [];
    value = json['value']?.toString() ?? '';
  }
  int? id;
  String? name;
  String? translatedName;
  String? image;
  String? isRequired;
  String? typeOfParameter;
  List<String>? typeValues;
  String? value;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['translated_name'] = translatedName;
    data['image'] = image;
    data['is_required'] = isRequired;
    data['type_of_parameter'] = typeOfParameter;
    data['type_values'] = typeValues;
    data['value'] = value;
    return data;
  }
}

class NearByPlaces {
  NearByPlaces({
    this.id,
    this.propertyId,
    this.facilityId,
    this.distance,
    this.createdAt,
    this.updatedAt,
    this.name,
    this.translatedName,
    this.image,
  });

  NearByPlaces.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int;
    propertyId = json['property_id']?.toString() ?? '';
    facilityId = json['facility_id']?.toString() ?? '';
    distance = json['distance']?.toString() ?? '';
    createdAt = json['created_at']?.toString() ?? '';
    updatedAt = json['updated_at']?.toString() ?? '';
    name = json['name']?.toString() ?? '';
    translatedName = json['translated_name']?.toString() ?? '';
    image = json['image']?.toString() ?? '';
  }
  int? id;
  String? propertyId;
  String? facilityId;
  String? distance;
  String? createdAt;
  String? updatedAt;
  String? name;
  String? translatedName;
  String? image;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['property_id'] = propertyId;
    data['facility_id'] = facilityId;
    data['distance'] = distance;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['name'] = name;
    data['translated_name'] = translatedName;
    data['image'] = image;
    return data;
  }
}

class TargetProperty {
  TargetProperty({
    this.id,
    this.title,
    this.translatedTitle,
    this.titleImage,
    this.city,
    this.state,
    this.country,
    this.address,
    this.createdAt,
    this.price,
    this.rentduration,
    this.propertyType,
    this.totalLikes,
    this.totalViews,
    this.facilities,
    this.nearByPlaces,
  });

  TargetProperty.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int;
    title = json['title']?.toString() ?? '';
    translatedTitle = json['translated_title']?.toString() ?? '';
    titleImage = json['title_image']?.toString() ?? '';
    city = json['city']?.toString() ?? '';
    state = json['state']?.toString() ?? '';
    country = json['country']?.toString() ?? '';
    address = json['address']?.toString() ?? '';
    createdAt = json['created_at']?.toString() ?? '';
    price = json['price']?.toString() ?? '';
    rentduration = json['rentduration']?.toString() ?? '';
    propertyType = json['property_type']?.toString() ?? '';
    totalLikes = json['total_likes']?.toString() ?? '0';
    totalViews = json['total_views']?.toString() ?? '0';
    if (json['facilities'] != null) {
      facilities = <Facilities>[];
      json['facilities'].forEach((dynamic v) {
        facilities!.add(Facilities.fromJson(v as Map<String, dynamic>? ?? {}));
      });
    }
    if (json['near_by_places'] != null) {
      nearByPlaces = <NearByPlaces>[];
      json['near_by_places'].forEach((dynamic v) {
        nearByPlaces!
            .add(NearByPlaces.fromJson(v as Map<String, dynamic>? ?? {}));
      });
    }
  }
  int? id;
  String? title;
  String? translatedTitle;
  String? titleImage;
  String? city;
  String? state;
  String? country;
  String? address;
  String? createdAt;
  String? price;
  String? rentduration;
  String? propertyType;
  String? totalLikes;
  String? totalViews;
  List<Facilities>? facilities;
  List<NearByPlaces>? nearByPlaces;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['translated_title'] = translatedTitle;
    data['title_image'] = titleImage;
    data['city'] = city;
    data['state'] = state;
    data['country'] = country;
    data['address'] = address;
    data['created_at'] = createdAt;
    data['price'] = price;
    data['rentduration'] = rentduration;
    data['property_type'] = propertyType;
    data['total_likes'] = totalLikes;
    data['total_views'] = totalViews;
    if (facilities != null) {
      data['facilities'] = facilities!.map((v) => v.toJson()).toList();
    }
    if (nearByPlaces != null) {
      data['near_by_places'] = nearByPlaces!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
