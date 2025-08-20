import 'package:ebroker/data/model/article_model.dart';
import 'package:ebroker/data/model/data_output.dart';
import 'package:ebroker/utils/api.dart';
import 'package:ebroker/utils/constant.dart';

class ArticlesRepository {
  Future<DataOutput<ArticleModel>> fetchArticles({
    required int offset,
  }) async {
    final parameters = <String, dynamic>{
      Api.offset: offset,
      Api.limit: Constant.loadLimit,
    };

    final result = await Api.get(
      url: Api.getArticles,
      queryParameters: parameters,
    );

    final modelList = (result['data'] as List)
        .cast<Map<String, dynamic>>()
        .map<ArticleModel>(ArticleModel.fromJson)
        .toList();

    return DataOutput<ArticleModel>(
      total: int.parse(result['total']?.toString() ?? '0'),
      modelList: modelList,
    );
  }

  Future<DataOutput<ArticleModel>> fetchArticlesById(
    String id,
  ) async {
    final parameters = <String, dynamic>{'id': id};

    final result = await Api.get(
      url: Api.getArticles,
      queryParameters: parameters,
    );
    final modelList = (result['data'] as List)
        .cast<Map<String, dynamic>>()
        .map<ArticleModel>(ArticleModel.fromJson)
        .toList();

    return DataOutput<ArticleModel>(
      total: int.parse(result['total']?.toString() ?? '0'),
      modelList: modelList,
    );
  }
}
