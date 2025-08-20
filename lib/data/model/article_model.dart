class ArticleModel {
  ArticleModel({this.id, this.image, this.title, this.description, this.date});

  ArticleModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int;
    image = json['image']?.toString() ?? '';
    title = json['title']?.toString() ?? '';
    translatedTitle = json['translated_title']?.toString() ?? '';
    translatedDescription = json['translated_description']?.toString() ?? '';
    description = json['description']?.toString() ?? '';
    date = json['created_at']?.toString() ?? '';
    viewCount = json['view_count']?.toString() ?? '';
  }
  int? id;
  String? image;
  String? title;
  String? translatedTitle;
  String? translatedDescription;
  String? description;
  String? date;
  String? viewCount;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['image'] = image;
    data['title'] = title;
    data['translated_title'] = translatedTitle;
    data['translated_description'] = translatedDescription;
    data['description'] = description;
    data['created_at'] = date;
    data['view_count '] = viewCount;
    return data;
  }
}
