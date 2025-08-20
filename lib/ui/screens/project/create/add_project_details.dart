import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:ebroker/data/model/languages_model.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/model/translation_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:flutter/material.dart';

class AddProjectDetails extends StatefulWidget {
  const AddProjectDetails({super.key, this.editData});

  final Map<dynamic, dynamic>? editData;

  static CupertinoPageRoute<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) {
        return BlocProvider(
          create: (context) => ManageProjectCubit(),
          child: AddProjectDetails(
            editData: settings.arguments as Map?,
          ),
        );
      },
    );
  }

  @override
  CloudState<AddProjectDetails> createState() => _AddProjectDetailsState();
}

class _AddProjectDetailsState extends CloudState<AddProjectDetails>
    with TickerProviderStateMixin {
  late bool isEdit = widget.editData != null;
  String slug = '';
  String metaTitle = '';
  String metaDescription = '';
  String metaImageUrl = '';

  late ProjectModel? project = widget.editData?['project'] as ProjectModel?;

  // Multi-language support variables
  late TabController _tabController;
  List<Translations> translatedFields = [];
  final translationMap = <String, dynamic>{};
  List<LanguagesModel> languages = AppSettings.languages;

  late final List<TextEditingController> _titleControllers;
  late final List<TextEditingController> _descriptionControllers;
  late final TextEditingController _slugController =
      TextEditingController(text: project?.slugId ?? '');
  late final TextEditingController _videoLinkController =
      TextEditingController(text: project?.videoLink);
  String selectedLocation = '';
  GooglePlaceModel? suggestion;
  final GlobalKey<FormState> _formKey = GlobalKey();

  List<Document<dynamic>> documentFiles = [];
  List<int> removedDocumentId = [];
  List<int> removedGalleryImageId = [];

  GooglePlaceRepository googlePlaceRepository = GooglePlaceRepository();

  late final TextEditingController _cityNameController =
      TextEditingController(text: project?.city);

  late final TextEditingController _stateNameController =
      TextEditingController(text: project?.state);

  late final TextEditingController _countryNameController =
      TextEditingController(text: project?.country);

  late final TextEditingController _addressController =
      TextEditingController(text: project?.location);

  // final TextEditingController _main=TextEditingController();
  double? latitude;
  double? longitude;
  Map<dynamic, dynamic>? floorPlans = {};
  List<Map<dynamic, dynamic>> floorPlansRawData = [];
  ImagePickerValue<dynamic>? titleImage;
  ImagePickerValue<dynamic>? galleryImages;
  String projectType = 'upcoming';
  List<int> removedPlansId = [];

  String generateSlug(String input) {
    return input
        .replaceAll(' ', '-')
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w-]'), '');
  }

  @override
  void initState() {
    // Initialize tab controller for languages
    _tabController = TabController(length: languages.length, vsync: this);
    if (widget.editData?['translations'] != null &&
        widget.editData?['translations'] is List) {
      final wid = widget.editData?['translations'] as List<Translations>? ?? [];
      translatedFields = wid;
    }

    // Initialize title controllers for each language
    _titleControllers = List.generate(languages.length, (index) {
      final langId = languages[index].id;
      final titleTranslation = translatedFields.firstWhere(
        (element) => element.languageId == langId && element.key == 'title',
        orElse: Translations.new,
      );
      return TextEditingController(
        text: titleTranslation.value ?? '',
      );
    });

    // Initialize description controllers for each language
    _descriptionControllers = List.generate(languages.length, (index) {
      final langId = languages[index].id;
      final descTranslation = translatedFields.firstWhere(
        (element) =>
            element.languageId == langId && element.key == 'description',
        orElse: Translations.new,
      );
      return TextEditingController(
        text: descTranslation.value ?? '',
      );
    });

    //add documents in edit mode
    _titleControllers.first.addListener(() {
      setState(() {
        if (project?.slugId != null && project?.slugId != '') {
          _slugController.text = project?.slugId ?? '';
        }
        _slugController.text = generateSlug(_titleControllers.first.text);
      });
    });
    metaTitle = widget.editData?['meta_title']?.toString() ?? '';
    metaDescription = widget.editData?['meta_description']?.toString() ?? '';
    metaImageUrl = widget.editData?['meta_image']?.toString() ?? '';
    final list = project?.documents?.map((document) {
      return UrlDocument(document.name!, document.id!);
    }).toList();

    if (list != null) {
      documentFiles = List<Document<dynamic>>.from(list as List<Document>);
    }
    projectType = project?.type ?? 'upcoming';
    if (project != null && project?.image != '') {
      titleImage = UrlValue(project!.image!);
    }

    if (project != null && project!.gallaryImages!.isNotEmpty) {
      galleryImages = MultiValue(
        project!.gallaryImages!.map((e) => UrlValue(e.name)).toList(),
      );
    }

    ///add plans in edit mode
    project?.plans?.forEach((plan) {
      floorPlansRawData.add({
        'title': plan.title,
        'id': plan.id,
        'image': plan.document,
      });
    });

    setState(() {});
    super.initState();
  }

  Map<String, dynamic> projectDetails = {};
  Map<String, dynamic> toTranslationMap(List<Translations> translatedFields) {
    translationMap.clear();

    for (var i = 0; i < languages.length; i++) {
      final langId = languages[i].id;

      final titleField = translatedFields.firstWhere(
        (t) => t.languageId == langId && t.key == 'title',
        orElse: Translations.new,
      );

      final descField = translatedFields.firstWhere(
        (t) => t.languageId == langId && t.key == 'description',
        orElse: Translations.new,
      );

      final titleValue = titleField.value?.trim() ?? '';
      final descValue = descField.value?.trim() ?? '';

      if (titleValue.isNotEmpty) {
        translationMap.addAll({
          'translations[$i][title][translation_id]': titleField.id ?? '',
          'translations[$i][title][language_id]': langId,
          'translations[$i][title][value]': titleValue,
        });
      }

      if (descValue.isNotEmpty) {
        translationMap.addAll({
          'translations[$i][description][translation_id]': descField.id ?? '',
          'translations[$i][description][language_id]': langId,
          'translations[$i][description][value]': descValue,
        });
      }
    }

    return translationMap;
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _titleControllers) {
      controller.dispose();
    }
    for (final controller in _descriptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: context.color.backgroundColor,
          appBar: CustomAppBar(
            title: CustomText('projectDetails'.translate(context)),
          ),
          bottomNavigationBar: UiUtils.buildButton(
            context,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Check if first language title and description are filled
                if (_titleControllers.first.text.trim().isEmpty ||
                    _descriptionControllers.first.text.trim().isEmpty) {
                  HelperUtils.showSnackBarMessage(
                    context,
                    'pleaseFillMainTitleAndDescription'.translate(context),
                  );
                  return;
                }

                // Update translation fields
                for (var i = 0; i < languages.length; i++) {
                  final langId = languages[i].id;

                  final titleIndex = translatedFields.indexWhere(
                    (t) => t.languageId == langId && t.key == 'title',
                  );

                  if (titleIndex != -1) {
                    translatedFields[titleIndex].value =
                        _titleControllers[i].text.trim();
                  } else {
                    translatedFields.add(Translations(
                      languageId: langId,
                      key: 'title',
                      value: _titleControllers[i].text.trim(),
                    ));
                  }

                  final descIndex = translatedFields.indexWhere(
                    (t) => t.languageId == langId && t.key == 'description',
                  );

                  if (descIndex != -1) {
                    translatedFields[descIndex].value =
                        _descriptionControllers[i].text.trim();
                  } else {
                    translatedFields.add(Translations(
                      languageId: langId,
                      key: 'description',
                      value: _descriptionControllers[i].text.trim(),
                    ));
                  }
                }

                toTranslationMap(translatedFields);

                Map<dynamic, dynamic> documents;
                documents = {};
                try {
                  documents = documentFiles.fold({}, (pr, el) {
                    if (el is FileDocument) {
                      pr.addAll({
                        'documents[${pr.length}]':
                            MultipartFile.fromFileSync(el.value.path),
                      });
                    }
                    return pr;
                  });
                } on Exception catch (e) {
                  log('issue is $e');
                }

                projectDetails = {
                  'title': _titleControllers.first.text,
                  'slug_id': _slugController.text,
                  'description': _descriptionControllers.first.text,
                  'latitude': latitude,
                  'longitude': longitude,
                  'city': _cityNameController.text,
                  'state': _stateNameController.text,
                  'country': _countryNameController.text,
                  'location': _addressController.text,
                  'video_link': _videoLinkController.text,
                  if (titleImage != null &&
                      titleImage is! UrlValue &&
                      titleImage?.value != '')
                    'image': titleImage,
                  'gallery_images': galleryImages,
                  ...documents.cast<String, dynamic>(),
                  'is_edit': isEdit,
                  'project': project,
                  'type': projectType,
                  'remove_gallery_images': removedGalleryImageId.join(','),
                  'remove_documents': removedDocumentId.join(','),
                  'remove_plans': removedPlansId.join(','),
                  'meta_title': metaTitle,
                  'meta_description': metaDescription,
                  'meta_image': metaImageUrl,
                  ...translationMap,

                  ////If there is data it will add into it
                  ...widget.editData?.cast<String, dynamic>() ?? {},
                };
                addCloudData(
                  'add_project_details',
                  projectDetails,
                );
                //this will create Map from List<Map>

                floorPlansRawData
                    .removeWhere((element) => element['image'] is String);

                final fold = floorPlansRawData.fold<Map<String, dynamic>>({},
                    (previousValue, element) {
                  previousValue.addAll({
                    'plans[${previousValue.length ~/ 2}][id]':
                        (element['id'] is ValueKey)
                            ? (element['id'] as ValueKey).value
                            : '',
                    'plans[${previousValue.length ~/ 2}][document]':
                        element['image'],
                    'plans[${previousValue.length ~/ 2}][title]':
                        element['title'],
                  });
                  return previousValue;
                });

                addCloudData('floor_plans', fold);
                Navigator.pushNamed(
                  context,
                  Routes.projectMetaDataScreens,
                );
              }
            },
            height: 48.rh(context),
            outerPadding: const EdgeInsets.all(16),
            buttonTitle: 'continue'.translate(context),
          ),
          body: BlocListener<ManageProjectCubit, ManageProjectState>(
            listener: (context, state) {
              if (state is ManageProjectInProgress) {
                Widgets.showLoader(context);
              }

              if (state is ManageProjectInSuccess) {
                context.read<FetchMyProjectsListCubit>().update(state.project);
                Widgets.hideLoder(context);
                HelperUtils.showSnackBarMessage(
                  context,
                  'projectUpdatedSuccessfully'.translate(context),
                );
                Navigator.of(context)
                  ..pop()
                  ..pop();
              }
              if (state is ManageProjectInFail) {
                log(state.error?.toString() ?? '');
              }
            },
            child: SingleChildScrollView(
              physics: Constant.scrollPhysics,
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildLanguageSelector(context, _tabController, languages),
                      SizedBox(
                        height: 296.rh(context),
                        width: MediaQuery.sizeOf(context).width,
                        child: IndexedStack(
                          index: _tabController.index,
                          sizing: StackFit.expand,
                          children: List.generate(languages.length, (index) {
                            return buildTitleAndDescriptionFields(
                              index: index,
                              requiredSymbol: const CustomText(
                                '*',
                                color: Colors.redAccent,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomText('slugIdLbl'.translate(context)),
                      const SizedBox(height: 8),
                      CustomTextFormField(
                        controller: _slugController,
                        validator: CustomTextFieldValidator.slugId,
                        action: TextInputAction.next,
                        hintText: UiUtils.translate(context, 'slugIdOptional'),
                      ),
                      const SizedBox(height: 8),
                      projectTypeField(context),
                      const SizedBox(height: 8),
                      buildLocationChooseHeader(),
                      const SizedBox(height: 8),
                      buildProjectLocationTextFields(),
                      const SizedBox(height: 8),
                      CustomText(
                        '',
                        isRichText: true,
                        textSpan: TextSpan(
                          style: TextStyle(color: context.color.textColorDark),
                          children: [
                            TextSpan(
                              text: 'uploadMainPicture'.translate(context),
                            ),
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      AdaptiveImagePickerWidget(
                        isRequired: true,
                        multiImage: false,
                        allowedSizeBytes: 3000000,
                        value: isEdit ? UrlValue(project!.image!) : null,
                        title: UiUtils.translate(context, 'addMainPicture'),
                        onSelect: (ImagePickerValue<dynamic>? selected) {
                          titleImage = selected;
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomText('uploadOtherImages'.translate(context)),
                      const SizedBox(height: 8),
                      AdaptiveImagePickerWidget(
                        title: UiUtils.translate(context, 'addOtherImage'),
                        onRemove: (value) {
                          if (value is UrlValue && value.metaData != null) {
                            removedGalleryImageId
                                .add(value.metaData['id'] as int);
                          }
                        },
                        multiImage: true,
                        value: MultiValue([
                          if (project?.gallaryImages != null)
                            ...project?.gallaryImages?.map(
                                  (e) => UrlValue(e.name, {
                                    'id': e.id,
                                  }),
                                ) ??
                                [],
                        ]),
                        onSelect: (ImagePickerValue<dynamic>? selected) {
                          if (selected is MultiValue) {
                            galleryImages = selected;
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomText('videoLink'.translate(context)),
                      const SizedBox(height: 8),
                      CustomTextFormField(
                        action: TextInputAction.next,
                        controller: _videoLinkController,
                        validator: CustomTextFieldValidator.link,
                        hintText: 'http://example.com/video.mp4',
                      ),
                      const SizedBox(height: 8),
                      CustomText('projectDocuments'.translate(context)),
                      const SizedBox(height: 8),
                      buildDocumentPicker(context),
                      ...documentList(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Column(
                            children: [
                              CustomText(
                                'floorPlans'.translate(context),
                              ),
                              CustomText(
                                '${floorPlansRawData.length}',
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                          const Spacer(),
                          MaterialButton(
                            elevation: 0,
                            color: context.color.tertiaryColor
                                .withValues(alpha: 0.1),
                            onPressed: () async {
                              final data = await Navigator.pushNamed(
                                context,
                                Routes.manageFloorPlansScreen,
                                arguments: {'floorPlan': floorPlansRawData},
                              ) as Map?;
                              if (data != null) {
                                floorPlansRawData = (data['floorPlans'] as List)
                                    .cast<Map<String, dynamic>>();

                                removedPlansId = data['removed'] as List<int>;
                              }
                              setState(() {});
                            },
                            child: CustomText('manage'.translate(context)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget projectTypeField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'projectStatus'.translate(context),
          color: context.color.textColorDark,
        ),
        const SizedBox(height: 8),
        DropdownMenu(
          textStyle: TextStyle(
            color: context.color.textColorDark,
          ),
          width: MediaQuery.of(context).size.width * 0.9,
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: TextStyle(
              color: context.color.textColorDark.withValues(alpha: 0.7),
              fontSize: context.font.md,
            ),
            filled: true,
            fillColor: context.color.secondaryColor,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: context.color.tertiaryColor,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.color.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: context.color.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          initialSelection: 'upcoming',
          onSelected: (value) {
            projectType = value!;
            setState(() {});
          },
          dropdownMenuEntries: [
            DropdownMenuEntry(
              value: 'upcoming',
              label: 'Upcoming'.translate(context),
            ),
            DropdownMenuEntry(
              value: 'under_construction',
              label: 'under_construction'.translate(context),
            ),
          ],
        ),
      ],
    );
  }

  Column buildProjectLocationTextFields() {
    return Column(
      children: [
        CustomTextFormField(
          action: TextInputAction.next,
          controller: _cityNameController,
          isReadOnly: false,
          validator: CustomTextFieldValidator.nullCheck,
          hintText: UiUtils.translate(context, 'city'),
        ),
        SizedBox(height: 8.rh(context)),
        CustomTextFormField(
          action: TextInputAction.next,
          controller: _stateNameController,
          isReadOnly: false,
          validator: CustomTextFieldValidator.nullCheck,
          hintText: UiUtils.translate(context, 'state'),
        ),
        SizedBox(height: 8.rh(context)),
        CustomTextFormField(
          action: TextInputAction.next,
          controller: _countryNameController,
          isReadOnly: false,
          validator: CustomTextFieldValidator.nullCheck,
          hintText: UiUtils.translate(context, 'country'),
        ),
        SizedBox(height: 8.rh(context)),
        CustomTextFormField(
          action: TextInputAction.next,
          controller: _addressController,
          hintText: UiUtils.translate(context, 'addressLbl'),
          maxLine: 100,
          validator: CustomTextFieldValidator.nullCheck,
          minLine: 4,
        ),
      ],
    );
  }

  SizedBox buildLocationChooseHeader() {
    return SizedBox(
      height: 35.rh(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            '',
            isRichText: true,
            textSpan: TextSpan(
              style: TextStyle(
                color: context.color.textColorDark,
              ),
              children: [
                TextSpan(
                  text: 'projectLocation'.translate(context),
                  style: TextStyle(
                    color: context.color.textColorDark,
                  ),
                ),
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          // const Spacer(),
          ChooseLocationFormField(
            initialValue: false,
            validator: (bool? value) {
              if (project != null) return null;

              if (value ?? false) {
                return null;
              } else {
                return 'Select location';
              }
            },
            build: (state) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: state.hasError ? Colors.red : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: InkWell(
                  onTap: () {
                    _onTapChooseLocation.call(state);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomImage(
                        imageUrl: AppIcons.location,
                        color: context.color.textLightColor,
                      ),
                      const SizedBox(
                        width: 3,
                      ),
                      CustomText(
                        UiUtils.translate(
                          context,
                          'chooseLocation',
                        ),
                        fontSize: context.font.sm,
                        color: context.color.tertiaryColor,
                      ),
                      const SizedBox(
                        width: 3,
                      ),
                      const CustomText(
                        ' *',
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onTapChooseLocation(FormFieldState<dynamic> state) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();

      final placeMark = await Navigator.pushNamed(
        context,
        Routes.chooseLocaitonMap,
        arguments: {},
      ) as Map?;
      final latlng = placeMark?['latlng'] as LatLng?;
      final place = placeMark?['place'] as Placemark?;

      if (latlng != null && place != null) {
        latitude = latlng.latitude;
        longitude = latlng.longitude;

        _cityNameController.text = place.locality ?? '';
        _countryNameController.text = place.country ?? '';
        _stateNameController.text = place.administrativeArea ?? '';
        _addressController.text =
            [place.locality, place.administrativeArea, place.country].join(',');
        // _addressController.text = getAddress(place);

        state.didChange(true);
      } else {
        // state.didChange(false);
      }
    } on Exception catch (e, st) {
      log('THE ISSUE IS $st');
    }
  }

  List<Widget> documentList() {
    return documentFiles.map((document) {
      var fileName = '';
      if (document is FileDocument) {
        fileName = document.value.path.split('/').last;
      } else {
        fileName = document.value.toString().split('/').last;
      }

      return ListTile(
        title: CustomText(
          fileName,
          maxLines: 2,
        ),
        dense: true,
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (document is UrlDocument) {
              removedDocumentId.add(document.id);
            }
            documentFiles.remove(document);
            setState(() {});
          },
        ),
      );
    }).toList();
  }

  Widget buildDocumentPicker(BuildContext context) {
    return Row(
      children: [
        DottedBorder(
          options: RectDottedBorderOptions(
            color: context.color.textLightColor,
          ),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: IconButton(
                onPressed: () async {
                  final filePickerResult = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                  );
                  if (filePickerResult != null) {
                    final list = List<Document<dynamic>>.from(
                      filePickerResult.files.map((e) {
                        return FileDocument(File(e.path!));
                      }).toList(),
                    );
                    documentFiles.addAll(list);
                  }

                  setState(() {});
                },
                icon: Icon(
                  Icons.upload,
                  color: context.color.textLightColor,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 16.rw(context)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText('UploadDocs'.translate(context)),
            const SizedBox(height: 4),
            CustomText(documentFiles.length.toString()),
          ],
        ),
      ],
    );
  }

  Widget buildLanguageSelector(BuildContext context,
      TabController tabController, List<LanguagesModel> languages) {
    return Center(
      child: Container(
        height: 48.rh(context),
        margin: EdgeInsets.only(bottom: 16.rh(context)),
        padding: EdgeInsets.all(8.rw(context)),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.color.borderColor),
        ),
        child: TabBar(
          onTap: (value) => setState(() {
            FocusScope.of(context).unfocus();
          }),
          controller: tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: context.color.tertiaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          labelColor: context.color.buttonColor,
          unselectedLabelColor: context.color.textColorDark,
          labelStyle: TextStyle(
            fontSize: context.font.sm,
            fontWeight: FontWeight.w500,
            color: context.color.buttonColor,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: context.font.sm,
            fontWeight: FontWeight.w500,
            color: context.color.textColorDark,
          ),
          tabAlignment: TabAlignment.center,
          isScrollable: true,
          dividerColor: Colors.transparent,
          tabs: languages
              .map(
                (lang) => SizedBox(
                  width: 85.rw(context),
                  child: Tab(
                    text: lang.name ?? '',
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget buildTitleAndDescriptionFields({
    required int index,
    required Widget requiredSymbol,
  }) {
    return Column(
      children: [
        Row(
          children: [
            CustomText(
                '${UiUtils.translate(context, 'projectName')} (${languages[index].name})'),
            const SizedBox(width: 3),
            if (index == 0) requiredSymbol,
          ],
        ),
        SizedBox(
          height: 8.rh(context),
        ),
        CustomTextFormField(
          controller: _titleControllers[index],
          validator: index == 0 ? CustomTextFieldValidator.nullCheck : null,
          action: TextInputAction.next,
          hintText: UiUtils.translate(context, 'projectName'),
        ),
        SizedBox(
          height: 8.rh(context),
        ),
        Row(
          children: [
            CustomText(
                '${UiUtils.translate(context, 'Description')} (${languages[index].name})'),
            const SizedBox(width: 3),
            if (index == 0) requiredSymbol,
          ],
        ),
        SizedBox(
          height: 8.rh(context),
        ),
        CustomTextFormField(
          action: TextInputAction.next,
          controller: _descriptionControllers[index],
          validator: index == 0 ? CustomTextFieldValidator.nullCheck : null,
          hintText: UiUtils.translate(context, 'writeSomething'),
          maxLine: 100,
          minLine: 6,
        ),
      ],
    );
  }
}

abstract class Document<T> {
  abstract final T value;
}

class FileDocument extends Document<dynamic> {
  FileDocument(this.value);

  @override
  final File value;
}

class UrlDocument extends Document<dynamic> {
  UrlDocument(this.value, this.id);

  @override
  final String value;
  final int id;
}
