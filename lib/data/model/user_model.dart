class UserModel {
  UserModel({
    this.address,
    this.createdAt,
    this.customertotalpost,
    this.email,
    this.fcmId,
    this.authId,
    this.id,
    this.isActive,
    this.isProfileCompleted,
    this.logintype,
    this.countryCode,
    this.mobile,
    this.name,
    this.notification,
    this.profile,
    this.token,
    this.updatedAt,
    this.instagram,
    this.facebook,
    this.youtube,
    this.twitter,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    address = json['address']?.toString() ?? '';
    createdAt = json['created_at']?.toString() ?? '';
    customertotalpost = json['customertotalpost']?.toString();
    email = json['email']?.toString() ?? '';
    fcmId = json['fcm_id']?.toString() ?? '';
    authId = json['auth_id']?.toString() ?? '';

    isActive = json['isActive']?.toString() ?? '0';
    isProfileCompleted = json['isProfileCompleted'] as bool?;
    logintype = json['logintype']?.toString() ?? '';
    countryCode = json['country_code']?.toString() ?? '';
    mobile = json['mobile']?.toString() ?? '';
    name = json['name']?.toString() ?? '';
    notification = json['notification']?.toString() ?? '0';
    profile = json['profile']?.toString() ?? '';
    token = json['token']?.toString() ?? '';
    updatedAt = json['updated_at']?.toString() ?? '';
    instagram = json['instagram_id']?.toString() ?? '';
    facebook = json['facebook_id']?.toString() ?? '';
    youtube = json['youtube_id']?.toString() ?? '';
    twitter = json['twitter_id']?.toString() ?? '';
  }
  int? id;
  String? address;
  String? createdAt;
  String? customertotalpost;
  String? email;
  String? fcmId;
  String? authId;

  String? isActive;
  bool? isProfileCompleted;
  String? logintype;
  String? countryCode;
  String? mobile;
  String? name;
  String? notification;
  String? profile;
  String? token;
  String? updatedAt;
  String? instagram;
  String? facebook;
  String? youtube;
  String? twitter;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['address'] = address;
    data['created_at'] = createdAt;
    data['customertotalpost'] = customertotalpost;
    data['email'] = email;
    data['fcm_id'] = fcmId;
    data['auth_id'] = authId;
    data['id'] = id;
    data['isActive'] = isActive;
    data['isProfileCompleted'] = isProfileCompleted;
    data['logintype'] = logintype;
    data['country_code'] = countryCode;
    data['mobile'] = mobile;
    data['name'] = name;
    data['notification'] = notification;
    data['profile'] = profile;
    data['token'] = token;
    data['updated_at'] = updatedAt;
    data['instagram_id'] = instagram;
    data['facebook_id'] = facebook;
    data['youtube_id'] = youtube;
    data['twitter_id'] = twitter;
    return data;
  }

  @override
  String toString() {
    return '''UserModel(address: $address, createdAt: $createdAt, customertotalpost: $customertotalpost, email: $email, fcmId: $fcmId, authId: $authId, id: $id, isActive: $isActive, isProfileCompleted: $isProfileCompleted, logintype: $logintype, mobile: $mobile, name: $name, notification: $notification, profile: $profile, token: $token, updatedAt: $updatedAt, instagram: $instagram, facebook: $facebook, youtube: $youtube, twitter: $twitter)''';
  }
}
