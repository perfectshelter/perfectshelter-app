import 'package:perfectshelter/data/model/agent/agent_model.dart';
import 'package:perfectshelter/data/model/article_model.dart';
import 'package:perfectshelter/data/model/category.dart';
import 'package:perfectshelter/data/model/city_model.dart';
import 'package:perfectshelter/data/model/home_slider.dart';
import 'package:perfectshelter/data/model/project_model.dart';
import 'package:perfectshelter/data/model/property_model.dart';
import 'package:perfectshelter/utils/admob/native_ad_manager.dart';

class HomePageDataModel implements NativeAdWidgetContainer {
  const HomePageDataModel({
    this.featuredSection,
    this.mostLikedProperties,
    this.mostViewedProperties,
    this.projectSection,
    this.sliderSection,
    this.categoriesSection,
    this.articleSection,
    this.agentsList,
    this.nearByProperties,
    this.featuredProjectSection,
    this.personalizedProperties,
    this.originalSections,
    this.premiumProperties,
    this.propertiesByCities,
    this.homePageLocationDataAvailable,
  });

  HomePageDataModel.fromJson(Map<String, dynamic> json)
      : sliderSection = (json['slider_section'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(HomeSlider.fromJson)
            .toList(),
        featuredSection =
            _extractPropertyModels(json, 'featured_properties_section'),
        mostLikedProperties =
            _extractPropertyModels(json, 'most_liked_properties_section'),
        mostViewedProperties =
            _extractPropertyModels(json, 'most_viewed_properties_section'),
        projectSection = _extractProjectModels(json, 'projects_section'),
        categoriesSection = _extractCategories(json, 'categories_section'),
        articleSection = _extractArticles(json, 'articles_section'),
        agentsList = _extractAgents(json, 'agents_list_section'),
        premiumProperties =
            _extractPropertyModels(json, 'premium_properties_section'),
        nearByProperties =
            _extractPropertyModels(json, 'nearby_properties_section'),
        featuredProjectSection =
            _extractProjectModels(json, 'featured_projects_section'),
        personalizedProperties =
            _extractPropertyModels(json, 'user_recommendations_section'),
        propertiesByCities =
            _extractCityModels(json, 'properties_by_cities_section'),
        originalSections = ((json['sections'] as List?) ?? [])
            .map(
              (section) =>
                  HomePageSection.fromJson(section as Map<String, dynamic>),
            )
            .toList(),
        homePageLocationDataAvailable =
            json['homepage_location_data_available'] as bool? ?? false;

  static List<PropertyModel> _extractPropertyModels(
    Map<String, dynamic> json,
    String sectionType,
  ) {
    final sections = json['sections'] as List? ?? [];
    final sectionTypeIsNotNull = sections.any(
      (section) => section['type'] == sectionType,
    );
    if (sectionTypeIsNotNull == false) return [];
    final section = sections.firstWhere(
      (section) => section['type'] == sectionType,
    );
    return ((section['data']) as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(PropertyModel.fromMap)
        .toList();
  }

  static List<City> _extractCityModels(
    Map<String, dynamic> json,
    String sectionType,
  ) {
    final sections = json['sections'] as List? ?? [];
    final sectionTypeIsNotNull = sections.any(
      (section) => section['type'] == sectionType,
    );
    if (sectionTypeIsNotNull == false) return [];
    final section = sections.firstWhere(
      (section) => section['type'] == sectionType,
    );
    return ((section['data']) as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(City.fromMap)
        .toList();
  }

  static List<ProjectModel> _extractProjectModels(
    Map<String, dynamic> json,
    String sectionType,
  ) {
    final sections = json['sections'] as List? ?? [];
    final sectionTypeIsNotNull = sections.any(
      (section) => section['type'] == sectionType,
    );
    if (sectionTypeIsNotNull == false) return [];
    final section = sections.firstWhere(
      (section) => section['type'] == sectionType,
    );
    return ((section['data']) as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ProjectModel.fromMap)
        .toList();
  }

  static List<Category> _extractCategories(
    Map<String, dynamic> json,
    String sectionType,
  ) {
    final sections = json['sections'] as List? ?? [];
    final sectionTypeIsNotNull = sections.any(
      (section) => section['type'] == sectionType,
    );
    if (sectionTypeIsNotNull == false) return [];
    final section = sections.firstWhere(
      (section) => section['type'] == sectionType,
    );
    return ((section['data']) as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }

  static List<ArticleModel> _extractArticles(
    Map<String, dynamic> json,
    String sectionType,
  ) {
    final sections = json['sections'] as List? ?? [];
    final sectionTypeIsNotNull = sections.any(
      (section) => section['type'] == sectionType,
    );
    if (sectionTypeIsNotNull == false) return [];
    final section = sections.firstWhere(
      (section) => section['type'] == sectionType,
    );
    return ((section['data']) as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ArticleModel.fromJson)
        .toList();
  }

  static List<AgentModel> _extractAgents(
    Map<String, dynamic> json,
    String sectionType,
  ) {
    final sections = json['sections'] as List? ?? [];
    final sectionTypeIsNotNull = sections.any(
      (section) => section['type'] == sectionType,
    );
    if (sectionTypeIsNotNull == false) return [];
    final section = sections.firstWhere(
      (section) => section['type'] == sectionType,
    );
    return ((section['data']) as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(AgentModel.fromJson)
        .toList();
  }

  final List<PropertyModel>? featuredSection;
  final List<PropertyModel>? mostLikedProperties;
  final List<PropertyModel>? mostViewedProperties;
  final List<ProjectModel>? projectSection;
  final List<HomeSlider>? sliderSection;
  final List<Category>? categoriesSection;
  final List<ArticleModel>? articleSection;
  final List<AgentModel>? agentsList;
  final List<PropertyModel>? nearByProperties;
  final List<ProjectModel>? featuredProjectSection;
  final List<PropertyModel>? personalizedProperties;
  final List<PropertyModel>? premiumProperties;
  final List<HomePageSection>? originalSections;
  final List<City>? propertiesByCities;
  final bool? homePageLocationDataAvailable;

  HomePageDataModel copyWith({
    List<PropertyModel>? featuredSection,
    List<PropertyModel>? mostLikedProperties,
    List<PropertyModel>? mostViewedProperties,
    List<ProjectModel>? projectSection,
    List<HomeSlider>? sliderSection,
    List<Category>? categoriesSection,
    List<ArticleModel>? articleSection,
    List<AgentModel>? agentsList,
    List<PropertyModel>? nearByProperties,
    List<ProjectModel>? featuredProjectSection,
    List<PropertyModel>? personalizedProperties,
    List<HomePageSection>? originalSections,
    List<PropertyModel>? premiumProperties,
    List<City>? propertiesByCities,
    bool? homePageLocationDataAvailable,
  }) {
    return HomePageDataModel(
      projectSection: projectSection ?? this.projectSection,
      mostLikedProperties: mostLikedProperties ?? this.mostLikedProperties,
      featuredSection: featuredSection ?? this.featuredSection,
      mostViewedProperties: mostViewedProperties ?? this.mostViewedProperties,
      sliderSection: sliderSection ?? this.sliderSection,
      categoriesSection: categoriesSection ?? this.categoriesSection,
      articleSection: articleSection ?? this.articleSection,
      agentsList: agentsList ?? this.agentsList,
      nearByProperties: nearByProperties ?? this.nearByProperties,
      featuredProjectSection:
          featuredProjectSection ?? this.featuredProjectSection,
      personalizedProperties:
          personalizedProperties ?? this.personalizedProperties,
      originalSections: originalSections ?? this.originalSections,
      premiumProperties: premiumProperties ?? this.premiumProperties,
      propertiesByCities: propertiesByCities ?? this.propertiesByCities,
      homePageLocationDataAvailable:
          homePageLocationDataAvailable ?? this.homePageLocationDataAvailable,
    );
  }
}

class HomePageSection {
  HomePageSection({
    this.type,
    this.title,
    this.translatedTitle,
    this.data,
  });

  factory HomePageSection.fromJson(Map<String, dynamic> json) {
    return HomePageSection(
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      translatedTitle: json['translated_title']?.toString(),
      data: json['data'] as List<dynamic>? ?? [],
    );
  }
  final String? type;
  final String? title;
  final String? translatedTitle;
  final List<dynamic>? data;
}
