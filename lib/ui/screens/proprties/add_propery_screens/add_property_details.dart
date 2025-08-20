import 'package:dio/dio.dart';
import 'package:perfectshelter/data/model/category.dart';
import 'package:perfectshelter/data/model/languages_model.dart';
import 'package:perfectshelter/data/model/translation_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/widgets/panaroma_image_view.dart';
import 'package:perfectshelter/utils/hive_keys.dart';
import 'package:perfectshelter/utils/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';

class AddPropertyDetails extends StatefulWidget {
  const AddPropertyDetails({super.key, this.propertyDetails});

  final Map<dynamic, dynamic>? propertyDetails;

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) {
        return AddPropertyDetails(
          propertyDetails: arguments?['details'] as Map<String, dynamic>?,
        );
      },
    );
  }

  @override
  State<AddPropertyDetails> createState() => _AddPropertyDetailsState();
}

class _AddPropertyDetailsState extends State<AddPropertyDetails>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey();
  late TabController _tabController;
  List<Translations> translatedFields = [];
  final translationMap = <String, dynamic>{};
  List<LanguagesModel> languages = AppSettings.languages;

  late PropertyModel? property = getEditPropertyData(
    widget.propertyDetails?['property'] as Map<String, dynamic>?,
  );

  late final List<TextEditingController> _titleControllers;
  late final List<TextEditingController> _descriptionControllers;

  late final TextEditingController _slugController = TextEditingController(
    text: widget.propertyDetails?['slug_id']?.toString() ?? '',
  );

  late final TextEditingController _cityNameController = TextEditingController(
    text: widget.propertyDetails?['city']?.toString() ?? '',
  );
  late final TextEditingController _stateNameController = TextEditingController(
    text: widget.propertyDetails?['state']?.toString() ?? '',
  );
  late final TextEditingController _countryNameController =
      TextEditingController(
    text: widget.propertyDetails?['country']?.toString() ?? '',
  );
  late final TextEditingController _latitudeController = TextEditingController(
    text: widget.propertyDetails?['latitude']?.toString() ?? '',
  );
  late final TextEditingController _longitudeController = TextEditingController(
    text: widget.propertyDetails?['longitude']?.toString() ?? '',
  );
  late final TextEditingController _addressController = TextEditingController(
    text: widget.propertyDetails?['address']?.toString() ?? '',
  );
  late final TextEditingController _priceController = TextEditingController(
    text: widget.propertyDetails?['price']?.toString() ?? '',
  );
  late final TextEditingController _clientAddressController =
      TextEditingController(
    text: widget.propertyDetails?['client']?.toString() ?? '',
  );

  late final TextEditingController _videoLinkController =
      TextEditingController();

  bool isPrivateProperty = false;

  ///META DETAILS
  late final TextEditingController metaTitleController =
      TextEditingController();
  late final TextEditingController metaDescriptionController =
      TextEditingController();
  late final TextEditingController metaKeywordController =
      TextEditingController();

  ///
  Map<dynamic, dynamic> propertyData = {};
  final PickImage _pickTitleImage = PickImage();
  final PickImage _propertiesImagePicker = PickImage();
  final PickImage _pick360deg = PickImage();

  // final PickImage _pickMetaTitle = PickImage();
  List<dynamic> editPropertyImageList = [];
  String threeDImageURL = '';
  String titleImageURL = '';

  // String metaImageUrl = '';
  String selectedRentType = 'Monthly';
  List<dynamic> removedImageId = [];
  int propertyType = 0;
  List<PropertyDocuments> documentFiles = [];
  List<int> removedDocumentId = [];
  int removeThreeDImage = 0;
  double localLatitude = 0;
  double localLongitude = 0;
  late final Map<String, dynamic> allPropData =
      widget.propertyDetails?['allPropData'] as Map<String, dynamic>? ?? {};

  // meta image new code
  late String metaImageUrl = allPropData['meta_image']?.toString() ?? '';
  late ImagePickerValue<dynamic>? metaImage =
      metaImageUrl != '' ? UrlValue(metaImageUrl) : null;

  List<dynamic> mixedPropertyImageList = [];

  PropertyModel? getEditPropertyData(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    return PropertyModel.fromMap(data);
  }

  @override
  void initState() {
    // Language Selector Tabs
    _tabController = TabController(length: languages.length, vsync: this);
    translatedFields =
        widget.propertyDetails?['translations'] as List<Translations>? ?? [];

    // Initialize title controllers
    _titleControllers = List.generate(languages.length, (index) {
      final langId = languages[index].id;

      final titleTranslation = translatedFields.firstWhere(
        (element) => element.languageId == langId && element.key == 'title',
        orElse: Translations.new,
      );

      return TextEditingController(
        text: titleTranslation.value ??
            widget.propertyDetails?['name']?.toString() ??
            '',
      );
    });

// Initialize description controllers
    _descriptionControllers = List.generate(languages.length, (index) {
      final langId = languages[index].id;

      final descTranslation = translatedFields.firstWhere(
        (element) =>
            element.languageId == langId && element.key == 'description',
        orElse: Translations.new,
      );

      return TextEditingController(
        text: descTranslation.value ??
            widget.propertyDetails?['desc']?.toString() ??
            '',
      );
    });

    _titleControllers.first.addListener(() {
      setState(() {
        if (property?.slugId != null && property?.slugId != '') {
          _slugController.text = property?.slugId ?? '';
        }
        _slugController.text = generateSlug(_titleControllers.first.text);
      });
    });

    documentFiles =
        widget.propertyDetails?['documents'] as List<PropertyDocuments>? ?? [];
    propertyType = widget.propertyDetails?['propType'] == 'rent' ? 1 : 0;
    titleImageURL = widget.propertyDetails?['titleImage']?.toString() ?? '';
    threeDImageURL = widget.propertyDetails?['three_d_image']?.toString() ?? '';
    removeThreeDImage =
        widget.propertyDetails?['remove_three_d_image'] as int? ?? 0;
    metaImageUrl = allPropData['meta_image']?.toString() ?? '';

    mixedPropertyImageList = List<dynamic>.from(
      widget.propertyDetails?['images'] as Iterable<dynamic>? ?? [],
    );

    if (widget.propertyDetails != null) {
      selectedRentType =
          (widget.propertyDetails?['rentduration']).toString().isEmpty
              ? 'Monthly'
              : widget.propertyDetails?['rentduration']?.toString() ?? '';
      isPrivateProperty = allPropData['is_premium'] as bool? ?? false;
    }

    metaTitleController.text = allPropData['meta_title']?.toString() ?? '';
    metaDescriptionController.text =
        allPropData['meta_description']?.toString() ?? '';
    metaKeywordController.text = allPropData['meta_keywords']?.toString() ?? '';

    // Update how we handle property image picker events
    _propertiesImagePicker.listener((dynamic result) {
      if (result != null) {
        try {
          if (result is List) {
            for (final file in result) {
              if (file is File) {
                mixedPropertyImageList.add(file);
              }
            }
          } else if (result is File) {
            // If a single image was selected
            mixedPropertyImageList.add(result);
          }
          setState(() {});
        } on Exception catch (_) {}
      }
    });
    super.initState();
  }

  String generateSlug(String input) {
    return input
        .replaceAll(' ', '-')
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w-]'), '');
  }

  Future<void> _onTapChooseLocation(FormFieldState<dynamic> state) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (Hive.box<dynamic>(HiveKeys.userDetailsBox)
        .get('latitude')
        .toString()
        .isNotEmpty) {
      final dynamic latitudeValue =
          Hive.box<dynamic>(HiveKeys.userDetailsBox).get('latitude') ?? '0';
      localLatitude = double.tryParse(latitudeValue.toString()) ?? 0.0;
    }
    if (Hive.box<dynamic>(HiveKeys.userDetailsBox)
        .get('longitude')
        .toString()
        .isNotEmpty) {
      final dynamic longitudeValue =
          Hive.box<dynamic>(HiveKeys.userDetailsBox).get('longitude') ?? '0';
      localLongitude = double.tryParse(longitudeValue.toString()) ?? 0.0;
    }

    final placeMark = await Navigator.pushNamed(
      context,
      Routes.chooseLocaitonMap,
      arguments: {},
    ) as Map?;
    final latlng = placeMark?['latlng'] as LatLng?;
    final place = placeMark?['place'] as Placemark?;
    if (latlng != null && place != null) {
      _latitudeController.text = latlng.latitude.toString();
      _longitudeController.text = latlng.longitude.toString();
      _cityNameController.text = place.locality ?? '';
      _countryNameController.text = place.country ?? '';
      _stateNameController.text = place.administrativeArea ?? '';
      _addressController
        ..text = ''
        ..text = getAddress(place);

      state.didChange(true);
    } else {
      // state.didChange(false);
    }
  }

  String getAddress(Placemark place) {
    try {
      var address = '';
      if (place.street == null && place.subLocality != null) {
        address = place.subLocality!;
      } else if (place.street == null && place.subLocality == null) {
        address = '';
      } else {
        address = "${place.street ?? ""},${place.subLocality ?? ""}";
      }

      return address;
    } on Exception catch (e, st) {
      throw Exception('$st');
    }
  }

  Future<void> _onTapContinue() async {
    File? titleImage;
    File? v360Image;

    if (_pickTitleImage.pickedFile != null) {
      titleImage = _pickTitleImage.pickedFile;
    }

    if (_pick360deg.pickedFile != null) {
      v360Image = _pick360deg.pickedFile;
    }
    final check = _checkIfLocationIsChosen();
    if (check == false) {
      Future.delayed(Duration.zero, () {
        UiUtils.showBlurredDialoge(
          context,
          sigmaX: 5,
          sigmaY: 5,
          dialog: BlurredDialogBox(
            svgImagePath: AppIcons.warning,
            title: UiUtils.translate(context, 'incomplete'),
            showCancleButton: false,
            onAccept: () async {},
            acceptTextColor: context.color.buttonColor,
            content: CustomText(
              UiUtils.translate(context, 'addressError'),
              textAlign: TextAlign.center,
            ),
          ),
        );
      });

      return;
    } else if (titleImage == null && titleImageURL == '') {
      Future.delayed(Duration.zero, () {
        UiUtils.showBlurredDialoge(
          context,
          sigmaX: 5,
          sigmaY: 5,
          dialog: BlurredDialogBox(
            svgImagePath: AppIcons.warning,
            title: UiUtils.translate(context, 'incomplete'),
            showCancleButton: false,
            acceptTextColor: context.color.buttonColor,
            content: CustomText(
              UiUtils.translate(context, 'uploadImgMsgLbl'),
              textAlign: TextAlign.center,
            ),
          ),
        );
      });
      return;
    } else if (titleImage?.path.split('.').last.toLowerCase() != 'jpg' &&
        titleImage?.path.split('.').last.toLowerCase() != 'png' &&
        titleImage?.path.split('.').last.toLowerCase() != 'jpeg' &&
        titleImageURL == '') {
      Future.delayed(Duration.zero, () {
        UiUtils.showBlurredDialoge(
          context,
          sigmaX: 5,
          sigmaY: 5,
          dialog: BlurredDialogBox(
            svgImagePath: AppIcons.warning,
            title: UiUtils.translate(context, 'incomplete'),
            showCancleButton: false,
            acceptTextColor: context.color.buttonColor,
            content: CustomText(
              UiUtils.translate(context, 'only jpg,jpeg and png supported'),
              textAlign: TextAlign.center,
            ),
          ),
        );
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      var documents = <String, dynamic>{};
      try {
        documents = documentFiles.fold({}, (pr, el) {
          pr.addAll({
            'documents[${pr.length}]': MultipartFile.fromFileSync(el.file!),
          });
          return pr;
        });
      } on Exception catch (_) {}

      _formKey.currentState?.save();

      final list = mixedPropertyImageList.map((e) {
        if (e is File) {
          return e;
        }
      }).toList()
        ..removeWhere((element) => element == null);
      _clientAddressController
        ..clear()
        ..text = HiveUtils.getUserDetails().address ?? '';
      final metaImageData =
          metaImage?.value != '' && metaImage != null ? metaImage : null;

      if (_titleControllers.first.text.trim().isEmpty ||
          _descriptionControllers.first.text.trim().isEmpty) {
        return HelperUtils.showSnackBarMessage(
          context,
          'pleaseFillMainTitleAndDescription'.translate(context),
        );
      }

      for (var i = 0; i < languages.length; i++) {
        final langId = languages[i].id;

        final titleIndex = translatedFields.indexWhere(
          (t) => t.languageId == langId && t.key == 'title',
        );

        if (titleIndex != -1) {
          translatedFields[titleIndex].value = _titleControllers[i].text.trim();
        } else {
          translatedFields.add(Translations(
            languageId: langId,
            key: 'title',
            value: _titleControllers[i].text.trim(),
          ));
        }

        // Update description
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

      propertyData.addAll({
        'title': _titleControllers.first.text,
        'slug_id': _slugController.text,
        'description': _descriptionControllers.first.text,
        'city': _cityNameController.text,
        'state': _stateNameController.text,
        'country': _countryNameController.text,
        'latitude': _latitudeController.text,
        'longitude': _longitudeController.text,
        'address': _addressController.text,
        'client_address': _clientAddressController.text,
        'price': _priceController.text,
        'title_image': titleImage,
        'gallery_images': list,
        ...documents,
        'remove_gallery_images': removedImageId,
        'remove_documents': removedDocumentId,
        'remove_three_d_image': removeThreeDImage,
        'category_id': widget.propertyDetails == null
            ? (Constant.addProperty['category'] as Category).id
            : widget.propertyDetails?['catId'],
        'property_type': propertyType,
        'three_d_image': v360Image,
        'video_link': _videoLinkController.text,
        'meta_title': metaTitleController.text,
        'meta_description': metaDescriptionController.text,
        'meta_keywords': metaKeywordController.text,
        if (metaImageUrl != metaImage?.value) 'meta_image': metaImageData,
        if (propertyType == 1) 'rentduration': selectedRentType,
        'is_premium': isPrivateProperty,
        ...translationMap,
      });

      if (widget.propertyDetails?.containsKey('assign_facilities') ?? false) {
        propertyData['assign_facilities'] =
            widget.propertyDetails!['assign_facilities'];
      }
      if (widget.propertyDetails != null) {
        propertyData['id'] = widget.propertyDetails?['id'];
        propertyData['action_type'] = '0';
      }

      Future.delayed(
        Duration.zero,
        () {
          _pickTitleImage.pauseSubscription();
          // _pickMetaTitle.pauseSubscription();
          Navigator.pushNamed(
            context,
            Routes.setPropertyParametersScreen,
            arguments: {
              'details': propertyData,
              'isUpdate': widget.propertyDetails != null,
            },
          ).then((value) {
            _pickTitleImage.resumeSubscription();
          });
        },
      );
    }
  }

  bool _checkIfLocationIsChosen() {
    if (_cityNameController.text == '' ||
        _stateNameController.text == '' ||
        _countryNameController.text == '' ||
        _latitudeController.text == '' ||
        _longitudeController.text == '') {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    // _pickMetaTitle.dispose();
    for (final element in _titleControllers) {
      element.dispose();
    }
    for (final element in _descriptionControllers) {
      element.dispose();
    }
    _cityNameController.dispose();
    _stateNameController.dispose();
    _countryNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _clientAddressController.dispose();
    _videoLinkController.dispose();
    _pick360deg.dispose();
    _pickTitleImage.dispose();
    _propertiesImagePicker.dispose();
    _slugController.dispose();
    super.dispose();
  }

  List<Widget> documentsList() {
    return documentFiles.map((documents) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: context.color.borderColor),
          borderRadius: BorderRadius.circular(4),
          color: context.color.secondaryColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              documents.name,
              maxLines: 2,
            ),
            GestureDetector(
              onTap: () {
                if (documents.id != null) {
                  removedDocumentId.add(documents.id!);
                }
                documentFiles.remove(documents);
                setState(() {});
              },
              child: Icon(
                Icons.close,
                color: context.color.textColorDark,
                size: 24.rh(context),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const requiredSymbol = CustomText(
      '*',
      color: Colors.redAccent,
    );
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      bottomNavigationBar: ColoredBox(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: UiUtils.buildButton(
            context,
            onPressed: _onTapContinue,
            height: 48.rh(context),
            buttonTitle: UiUtils.translate(context, 'continue'),
          ),
        ),
      ),
      appBar: CustomAppBar(
        title: CustomText(
          widget.propertyDetails == null
              ? UiUtils.translate(context, 'ddPropertyLbl')
              : UiUtils.translate(context, 'updateProperty'),
        ),
        actions: [
          CustomText(
            '2/4',
            fontSize: context.font.sm,
            fontWeight: FontWeight.w500,
            color: context.color.textColorDark,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: Constant.scrollPhysics,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                          requiredSymbol: requiredSymbol,
                        );
                      }),
                    ),
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomText(UiUtils.translate(context, 'slugIdLbl')),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomTextFormField(
                    controller: _slugController,
                    validator: CustomTextFieldValidator.slugId,
                    action: TextInputAction.next,
                    hintText: UiUtils.translate(context, 'slugIdOptional'),
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),

                  CustomText('propertyType'.translate(context)),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  buildPropertyTypeSelector(context),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          'isPrivateProperty'.translate(context),
                        ),
                      ),
                      CupertinoSwitch(
                        value: isPrivateProperty,
                        activeTrackColor: context.color.tertiaryColor,
                        onChanged: (bool value) {
                          isPrivateProperty = value;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  SizedBox(
                    height: 35.rh(context),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CustomText(
                                UiUtils.translate(context, 'addressLbl'),
                              ),
                              const SizedBox(
                                width: 3,
                              ),
                              requiredSymbol,
                            ],
                          ),
                        ),
                        // const Spacer(),
                        ChooseLocationFormField(
                          initialValue: false,
                          validator: (bool? value) {
                            //Check if it has already data so we will not validate it.
                            if (widget.propertyDetails != null) {
                              return null;
                            }

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
                                  width: 1.5,
                                  color: state.hasError
                                      ? Colors.red
                                      : Colors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(9),
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
                                    requiredSymbol,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomTextFormField(
                    action: TextInputAction.next,
                    controller: _cityNameController,
                    isReadOnly: false,
                    validator: CustomTextFieldValidator.nullCheck,
                    hintText: UiUtils.translate(context, 'city'),
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomTextFormField(
                    action: TextInputAction.next,
                    controller: _stateNameController,
                    isReadOnly: false,
                    validator: CustomTextFieldValidator.nullCheck,
                    hintText: UiUtils.translate(context, 'state'),
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomTextFormField(
                    action: TextInputAction.next,
                    controller: _countryNameController,
                    isReadOnly: false,
                    validator: CustomTextFieldValidator.nullCheck,
                    hintText: UiUtils.translate(context, 'country'),
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomTextFormField(
                    action: TextInputAction.next,
                    controller: _addressController,
                    hintText: UiUtils.translate(context, 'addressLbl'),
                    maxLine: 100,
                    validator: CustomTextFieldValidator.nullCheck,
                    minLine: 4,
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomTextFormField(
                    action: TextInputAction.next,
                    controller: _clientAddressController,
                    validator: CustomTextFieldValidator.nullCheck,
                    hintText: UiUtils.translate(context, 'clientaddressLbl'),
                    maxLine: 100,
                    minLine: 4,
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  if (propertyType == 1) ...[
                    Row(
                      children: [
                        CustomText(UiUtils.translate(context, 'rentPrice')),
                        const SizedBox(
                          width: 3,
                        ),
                        requiredSymbol,
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        CustomText(UiUtils.translate(context, 'price')),
                        const SizedBox(
                          width: 3,
                        ),
                        requiredSymbol,
                      ],
                    ),
                  ],
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          action: TextInputAction.next,
                          prefix: Padding(
                            padding: const EdgeInsets.all(20),
                            child: CustomText(
                              '${Constant.currencySymbol} ',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          controller: _priceController,
                          formaters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d*'),
                            ),
                          ],
                          isReadOnly: false,
                          keyboard: TextInputType.number,
                          validator: CustomTextFieldValidator.nullCheck,
                          hintText: '00',
                        ),
                      ),
                      if (propertyType == 1) ...[
                        const SizedBox(
                          width: 5,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: context.color.secondaryColor,
                            border: Border.all(
                              color: context.color.borderColor,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: DropdownButton<String>(
                              value: selectedRentType,
                              dropdownColor: context.color.primaryColor,
                              underline: const SizedBox.shrink(),
                              items: [
                                DropdownMenuItem(
                                  value: 'Daily',
                                  child: CustomText(
                                    'daily'.translate(context),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Monthly',
                                  child:
                                      CustomText('monthly'.translate(context)),
                                ),
                                DropdownMenuItem(
                                  value: 'Quarterly',
                                  child: CustomText(
                                    'quarterly'.translate(context),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Yearly',
                                  child:
                                      CustomText('yearly'.translate(context)),
                                ),
                              ],
                              onChanged: (value) {
                                selectedRentType = value ?? '';
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  Row(
                    children: [
                      CustomText(UiUtils.translate(context, 'uploadPictures')),
                      const SizedBox(
                        width: 3,
                      ),
                      CustomText(
                        'maxSize'.translate(context),
                        fontStyle: FontStyle.italic,
                        fontSize: context.font.xs,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  titleImageListener(),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomText(UiUtils.translate(context, 'otherPictures')),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  propertyImagesListener(),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  DottedBorder(
                    options: RoundedRectDottedBorderOptions(
                      color: context.color.textLightColor,
                      radius: const Radius.circular(4),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        _pick360deg.pick(pickMultiple: false);
                      },
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        height: 48.rh(context),
                        child: CustomText(
                          UiUtils.translate(context, 'add360degPicture'),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  // SHOW 360 PICTURE CODE
                  _pick360deg.listenChangesInUI((context, image) {
                    if (image != null) {
                      return Stack(
                        children: [
                          Container(
                            width: 100.rw(context),
                            height: 100.rw(context),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Image.file(
                              image as File,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute<dynamic>(
                                    builder: (context) {
                                      return PanaromaImageScreen(
                                        imageUrl: image.path,
                                        isFileImage: true,
                                      );
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                width: 100.rw(context),
                                height: 100.rh(context),
                                decoration: BoxDecoration(
                                  color: context.color.tertiaryColor
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.none,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.color.secondaryColor,
                                    ),
                                    width: 60.rw(context),
                                    height: 60.rh(context),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: 30.rh(context),
                                            width: 40.rw(context),
                                            child: CustomImage(
                                              imageUrl: AppIcons.v360Degree,
                                              color:
                                                  context.color.textColorDark,
                                            ),
                                          ),
                                          CustomText(
                                            UiUtils.translate(context, 'view'),
                                            fontWeight: FontWeight.bold,
                                            fontSize: context.font.xs,
                                            color: context.color.textColorDark,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          closeButton(context, () {
                            threeDImageURL.isNotEmpty
                                ? removeThreeDImage = 1
                                : removeThreeDImage = 0;
                            if (removeThreeDImage == 1) {
                              _pick360deg.listenChangesInUI((context, image) {
                                if (image != null || threeDImageURL != '') {
                                  threeDImageURL = '';
                                  image = null;
                                  setState(() {});
                                  return const SizedBox.shrink();
                                }
                              });
                            }
                            setState(() {});
                            return const SizedBox.shrink();
                          }),
                        ],
                      );
                    }
                    return Container();
                  }),
                  _pick360deg.listenChangesInUI((context, image) {
                    if (threeDImageURL != '' && image == null) {
                      return Stack(
                        children: [
                          Container(
                            width: 100.rw(context),
                            height: 100.rh(context),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Image.network(
                              threeDImageURL,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute<dynamic>(
                                    builder: (context) {
                                      return PanaromaImageScreen(
                                        imageUrl: threeDImageURL,
                                        isFileImage: true,
                                      );
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                width: 100.rw(context),
                                height: 100.rh(context),
                                decoration: BoxDecoration(
                                  color: context.color.tertiaryColor.withValues(
                                    alpha: 0.68,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.none,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.color.secondaryColor,
                                    ),
                                    width: 60.rw(context),
                                    height: 60.rh(context),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: 30.rh(context),
                                            width: 40.rw(context),
                                            child: CustomImage(
                                              imageUrl: AppIcons.v360Degree,
                                              color:
                                                  context.color.textColorDark,
                                            ),
                                          ),
                                          CustomText(
                                            UiUtils.translate(context, 'view'),
                                            fontWeight: FontWeight.bold,
                                            fontSize: context.font.xs,
                                            color: context.color.textColorDark,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          closeButton(context, () {
                            setState(() {
                              _pick360deg.clearImage();
                              threeDImageURL = '';
                              removeThreeDImage = 1;
                            });
                          }),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomText(UiUtils.translate(context, 'additionals')),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomTextFormField(
                    controller: _videoLinkController,
                    hintText: 'http://example.com/video.mp4',
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomText('propertyDocuments'.translate(context)),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  buildDocumentsPicker(context),
                  ...documentsList(),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomText('Meta Details'.translate(context)),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomTextFormField(
                    controller: metaTitleController,
                    hintText: 'Title'.translate(context),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: CustomText(
                      'metaTitleLength'.translate(context),
                      fontSize: context.font.xs,
                      color: context.color.textLightColor,
                    ),
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomTextFormField(
                    controller: metaDescriptionController,
                    hintText: 'Description'.translate(context),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: CustomText(
                      'metaDescriptionLength'.translate(context),
                      fontSize: context.font.xs,
                      color: context.color.textLightColor,
                    ),
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  CustomTextFormField(
                    controller: metaKeywordController,
                    hintText: 'Keywords'.translate(context),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: CustomText(
                      'metaKeywordsLength'.translate(context),
                      fontSize: context.font.xs,
                      color: context.color.textLightColor,
                    ),
                  ),
                  SizedBox(
                    height: 10.rh(context),
                  ),
                  AdaptiveImagePickerWidget(
                    isRequired: false,
                    title: UiUtils.translate(context, 'addMetaImage'),
                    multiImage: false,
                    value: metaImage,
                    onSelect: (ImagePickerValue<dynamic>? selected) {
                      if (selected is FileValue || selected == null) {
                        metaImage = selected;
                        setState(() {});
                      }
                    },
                    onRemove: (value) {
                      if (value is UrlValue) {
                        metaImage = UrlValue('');
                      }
                      setState(() {});
                    },
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

  Widget buildTitleAndDescriptionFields({
    required int index,
    required Widget requiredSymbol,
  }) {
    return Column(
      children: [
        Row(
          children: [
            CustomText(
                '${UiUtils.translate(context, 'propertyNameLbl')} (${languages[index].name})'),
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
          hintText: UiUtils.translate(context, 'propertyNameLbl'),
        ),
        SizedBox(
          height: 8.rh(context),
        ),
        Row(
          children: [
            CustomText(
                '${UiUtils.translate(context, 'descriptionLbl')} (${languages[index].name})'),
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

  InputDecorator buildPropertyTypeSelector(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        hintStyle: TextStyle(
          color: context.color.textColorDark.withValues(alpha: 0.7),
          fontSize: context.font.md,
        ),
        filled: true,
        fillColor: context.color.secondaryColor,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: context.color.tertiaryColor),
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
      child: DropdownButton<int>(
        value: propertyType,
        isExpanded: true,
        isDense: true,
        dropdownColor: context.color.secondaryColor,
        borderRadius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        underline: const SizedBox.shrink(),
        items: [
          DropdownMenuItem(
            value: 0,
            child: CustomText('sell'.translate(context)),
          ),
          DropdownMenuItem(
            value: 1,
            child: CustomText('rent'.translate(context)),
          ),
        ],
        onTap: () {},
        onChanged: (int? value) {
          propertyType = value!;
          setState(() {});
        },
      ),
    );
  }

  Widget propertyImagesListener() {
    // Use a StatefulBuilder to ensure updates within this widget trigger rebuilds
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                // Show upload button if no images
                if (mixedPropertyImageList.isEmpty)
                  DottedBorder(
                    options: RoundedRectDottedBorderOptions(
                      color: context.color.textLightColor,
                      radius: const Radius.circular(4),
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          final picker = ImagePicker();
                          final images = await picker.pickMultiImage(
                            imageQuality: Constant.uploadImageQuality,
                          );

                          if (images.isNotEmpty) {
                            for (final image in images) {
                              final file = File(image.path);
                              mixedPropertyImageList.add(file);
                            }
                            setLocalState(() {});
                            setState(() {});
                          }
                        } on Exception catch (_) {}
                      },
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4)),
                        alignment: Alignment.center,
                        height: 48.rh(context),
                        child: CustomText(
                            UiUtils.translate(context, 'addOtherPicture')),
                      ),
                    ),
                  ),

                // Display existing images
                ...mixedPropertyImageList.map((image) {
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HelperUtils.unfocus();
                          if (image is String) {
                            UiUtils.showFullScreenImage(
                              context,
                              provider: NetworkImage(image),
                            );
                          } else if (image is File) {
                            UiUtils.showFullScreenImage(
                              context,
                              provider: FileImage(image),
                            );
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.all(5),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ImageAdapter(
                            image: image,
                          ),
                        ),
                      ),
                      closeButton(context, () {
                        if (image is String) {
                          try {
                            final propertyDetail =
                                widget.propertyDetails?['gallary_with_id']
                                    as List<Gallery>?;
                            if (propertyDetail != null) {
                              final galleryItem = propertyDetail.firstWhere(
                                (element) => element.imageUrl == image,
                                orElse: () => const Gallery(
                                  id: -1,
                                  image: '',
                                  imageUrl: '',
                                ),
                              );

                              if (galleryItem.id != -1) {
                                removedImageId.add(galleryItem.id);
                              }
                            }
                          } on Exception catch (_) {}
                        }

                        // Remove the image and update both states
                        mixedPropertyImageList.remove(image);
                        setLocalState(() {});
                        setState(() {});
                      }),
                    ],
                  );
                }),

                // Show add more button if images exist
                if (mixedPropertyImageList.isNotEmpty)
                  uploadPhotoCard(
                    context,
                    onTap: () async {
                      try {
                        final picker = ImagePicker();
                        final images = await picker.pickMultiImage(
                          imageQuality: Constant.uploadImageQuality,
                        );

                        if (images.isNotEmpty) {
                          for (final image in images) {
                            final file = File(image.path);
                            mixedPropertyImageList.add(file);
                          }
                          setLocalState(() {});
                          setState(() {});
                        }
                      } on Exception catch (_) {}
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget titleImageListener() {
    return _pickTitleImage.listenChangesInUI((context, image) {
      Widget currentWidget = Container();

      // Check for network image first
      if (titleImageURL.isNotEmpty) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(
              context,
              provider: NetworkImage(titleImageURL),
            );
          },
          child: Container(
            width: 100.rw(context),
            height: 100.rh(context),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            child: Image.network(
              titleImageURL,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                );
              },
            ),
          ),
        );
      }
      // Check for picked file (use else if to avoid conflicts)
      else if (_pickTitleImage.pickedFile != null) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(
              context,
              provider: FileImage(_pickTitleImage.pickedFile!),
            );
          },
          child: Container(
            width: 100.rw(context),
            height: 100.rh(context),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            child: Image.file(
              _pickTitleImage.pickedFile!,
              fit: BoxFit.cover,
            ),
          ),
        );
      }

      return Wrap(
        children: [
          // Show add image button only when no image is selected
          if (_pickTitleImage.pickedFile == null && titleImageURL.isEmpty)
            DottedBorder(
              options: RoundedRectDottedBorderOptions(
                color: context.color.textLightColor,
                radius: const Radius.circular(4),
              ),
              child: GestureDetector(
                onTap: () {
                  _pickTitleImage.pick(pickMultiple: false);
                  titleImageURL = '';
                  setState(() {});
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  height: 48.rh(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        UiUtils.translate(context, 'addMainPicture'),
                      ),
                      const SizedBox(width: 4),
                      const CustomText('*', color: Colors.redAccent),
                    ],
                  ),
                ),
              ),
            ),

          // Show image with close button when image is selected
          if (_pickTitleImage.pickedFile != null || titleImageURL.isNotEmpty)
            Stack(
              children: [
                currentWidget,
                closeButton(context, () {
                  _pickTitleImage.clearImage();
                  titleImageURL = '';
                  setState(() {});
                }),
              ],
            ),

          // Show upload photo card when image is selected
          if (_pickTitleImage.pickedFile != null || titleImageURL.isNotEmpty)
            uploadPhotoCard(
              context,
              onTap: () {
                _pickTitleImage
                  ..resumeSubscription()
                  ..pick(pickMultiple: false)
                  ..pauseSubscription();
                titleImageURL = '';
                setState(() {});
              },
            ),
        ],
      );
    });
  }

  Widget buildDocumentsPicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final filePickerResult = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        );
        if (filePickerResult != null) {
          final list = filePickerResult.files.map<PropertyDocuments>((e) {
            return PropertyDocuments(
              name: e.name,
              file: e.path,
            );
          });
          documentFiles.addAll(list);
        }

        setState(() {});
      },
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: context.color.textLightColor,
          radius: const Radius.circular(4),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 64.rh(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.upload,
                color: context.color.textColorDark,
              ),
              const SizedBox(width: 4),
              CustomText('UploadDocs'.translate(context)),
              const SizedBox(width: 4),
              CustomText(documentFiles.length.toString()),
            ],
          ),
        ),
      ),
    );
  }
}

Widget uploadPhotoCard(BuildContext context, {required Function onTap}) {
  return GestureDetector(
    onTap: () {
      onTap.call();
    },
    child: Container(
      width: 100.rw(context),
      height: 100.rh(context),
      margin: const EdgeInsetsDirectional.only(end: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: context.color.textColorDark.withValues(alpha: 0.5),
          radius: const Radius.circular(4),
        ),
        child: Container(
          alignment: Alignment.center,
          child: CustomText('uploadPhoto'.translate(context)),
        ),
      ),
    ),
  );
}

PositionedDirectional closeButton(BuildContext context, Function onTap) {
  return PositionedDirectional(
    top: 4,
    end: 4,
    child: GestureDetector(
      onTap: () {
        onTap.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.color.primaryColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            Icons.close,
            size: 24.rh(context),
            color: context.color.textColorDark,
          ),
        ),
      ),
    ),
  );
}

class ChooseLocationFormField extends FormField<bool> {
  ChooseLocationFormField({
    required Widget Function(FormFieldState<bool> state) build,
    super.key,
    super.onSaved,
    super.validator,
    super.initialValue,
  }) : super(
          builder: (FormFieldState<bool> state) {
            return build(state);
          },
        );
}

class ImageAdapter extends StatelessWidget {
  const ImageAdapter({super.key, this.image});

  final dynamic image;

  @override
  Widget build(BuildContext context) {
    if (image is String) {
      return Image.network(
        image?.toString() ?? '',
        fit: BoxFit.cover,
      );
    } else if (image is File) {
      return Image.file(
        image as File,
        fit: BoxFit.cover,
      );
    }
    return Container();
  }
}
