import 'dart:developer';

import 'package:ebroker/data/model/category.dart' as c;
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:flutter/material.dart';

class ProjectMetaDetails extends StatefulWidget {
  const ProjectMetaDetails({super.key});
  static CupertinoPageRoute<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) {
        return BlocProvider(
          create: (context) => ManageProjectCubit(),
          child: const ProjectMetaDetails(),
        );
      },
    );
  }

  @override
  CloudState<ProjectMetaDetails> createState() => _ProjectMetaDetailsState();
}

class _ProjectMetaDetailsState extends CloudState<ProjectMetaDetails> {
  late Map<String, dynamic> projectDetails = Map<String, dynamic>.from(
    getCloudData('add_project_details') as Map? ?? {},
  );
  late ProjectModel? project = projectDetails['project'] is Map
      ? ProjectModel.fromMap(projectDetails['project'] as Map<String, dynamic>)
      : projectDetails['project'] as ProjectModel? ?? ProjectModel();
  final GlobalKey<FormState> _formKey = GlobalKey();
  late final TextEditingController _metaTitleController =
      TextEditingController(text: project?.metaTitle);
  late final TextEditingController _metaDescriptionController =
      TextEditingController(text: project?.metaDescription);
  late final TextEditingController _metaKeywordsController =
      TextEditingController(text: project?.metaKeywords);
  late String metaImageUrl = project?.metaImage ?? '';
  late ImagePickerValue<dynamic>? metaImage =
      metaImageUrl != '' ? UrlValue(metaImageUrl) : null;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: CustomAppBar(
          title: CustomText('addProjectMeta'.translate(context)),
        ),
        bottomNavigationBar: UiUtils.buildButton(
          context,
          onPressed: () {
            if (context.read<ManageProjectCubit>().state
                is ManageProjectInProgress) {
              return;
            }
            final data = <String, dynamic>{};
            final metaDetails = <String, dynamic>{
              'meta_title': _metaTitleController.text,
              'meta_description': _metaDescriptionController.text,
              'meta_keywords': _metaKeywordsController.text,
            };
            final metaImageData = metaImage?.value != metaImageUrl &&
                    metaImage?.value != '' &&
                    metaImage != null
                ? <String, dynamic>{
                    'meta_image': metaImage,
                  }
                : null;
            data
              ..addAll(projectDetails)
              ..addAll(metaDetails)
              ..addAll(metaImageData ?? {})
              ..addAll(
                Map<String, dynamic>.from(
                  getCloudData('floor_plans') as Map? ?? {},
                ),
              );

            if (!projectDetails.containsKey('category_id')) {
              data.addAll({
                'category_id':
                    (Constant.addProperty['category'] as c.Category).id,
              });
            }
            data.remove('project');
            context.read<ManageProjectCubit>().manage(
                  type: ManageProjectType.create,
                  data: data,
                );
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
              Navigator.popUntil(
                  context, (Route<dynamic> route) => route.isFirst);
            }
            if (state is ManageProjectInFail) {
              log(state.error?.toString() ?? ' ');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText('metaDetails'.translate(context)),
                  height(),
                  CustomTextFormField(
                    controller: _metaTitleController,
                    hintText: 'metaTitle'.translate(context),
                  ),
                  height(8),
                  CustomTextFormField(
                    controller: _metaKeywordsController,
                    hintText: 'metaKeywords'.translate(context),
                  ),
                  height(8),
                  CustomTextFormField(
                    controller: _metaDescriptionController,
                    hintText: 'metaDescription'.translate(context),
                    minLine: 5,
                    maxLine: 100,
                  ),
                  height(8),
                  AdaptiveImagePickerWidget(
                    isRequired: false,
                    title: UiUtils.translate(context, 'addMetaImage'),
                    multiImage: false,
                    value: project?.metaImage != null ? metaImage : null,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget height([double? h]) {
    return SizedBox(
      height: h?.rh(context) ?? 15.rh(context),
    );
  }
}
