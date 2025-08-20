import 'package:perfectshelter/data/cubits/property/create_advertisement_cubit.dart';
import 'package:perfectshelter/data/model/project_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/home/Widgets/property_card_big.dart';
import 'package:perfectshelter/ui/screens/home/widgets/project_card_horizontal.dart';
import 'package:perfectshelter/ui/screens/project/widgets/project_card_big.dart';
import 'package:perfectshelter/utils/image_picker.dart';
import 'package:flutter/material.dart';

class CreateAdvertisementPopup extends StatefulWidget {
  const CreateAdvertisementPopup({
    required this.property,
    required this.isProject,
    required this.project,
    super.key,
  });
  final PropertyModel property;
  final bool isProject;
  final ProjectModel project;

  @override
  State<CreateAdvertisementPopup> createState() =>
      _CreateAdvertisementPopupState();
}

class _CreateAdvertisementPopupState extends State<CreateAdvertisementPopup>
    with TickerProviderStateMixin {
  final PickImage _pickImage = PickImage();
  final String advertisementType = 'home';
  bool hasPackage = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    Future.delayed(Duration.zero, () {
      context.read<GetSubsctiptionPackageLimitsCubit>().getLimits(
            packageType: 'property_feature',
          );
    });
  }

  void _handleTabChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _pickImage.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget getPreview({required int index}) {
    return Center(
      child: index == 0 && widget.isProject != true
          ? SizedBox(
              height: 273.rh(context),
              child: PropertyCardBig(
                isFromCompare: false,
                showLikeButton: false,
                disableTap: true,
                showFeatured: true,
                property: widget.property,
              ),
            )
          : index != 0 && widget.isProject != true
              ? SizedBox(
                  height: 132.rh(context),
                  child: PropertyHorizontalCard(
                    showFeatured: true,
                    showLikeButton: false,
                    disableTap: true,
                    property: widget.property,
                  ),
                )
              : index == 0 && widget.isProject == true
                  ? SizedBox(
                      height: 273.rh(context),
                      child: ProjectCardBig(
                        showFeatured: true,
                        disableTap: true,
                        project: widget.project,
                      ),
                    )
                  : SizedBox(
                      height: 132.rh(context),
                      child: ProjectHorizontalCard(
                        showFeatured: true,
                        disableTap: true,
                        isRejected: false,
                        project: widget.project,
                      ),
                    ),
    );
  }

  Future<void> _createAdvertisement() async {
    await context.read<CreateAdvertisementCubit>().create(
          featureFor: widget.isProject == true ? 'project' : 'property',
          projectId: widget.project.id.toString(),
          propertyId: widget.property.id.toString(),
        );
  }

  void _showAdvertisePropertyDialog() {
    UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: 'advertiseProperty'.translate(context),
        content: CustomText(
          'advertisementDescription'.translate(context),
          fontSize: context.font.sm,
          fontWeight: FontWeight.w400,
          textAlign: TextAlign.center,
        ),
        showCancleButton: false,
        acceptTextColor: context.color.buttonColor,
      ),
    );
  }

  void _handlePromoteAction() {
    if (hasPackage) {
      _createAdvertisement();
    } else {
      Navigator.pushNamed(
        context,
        Routes.subscriptionPackageListRoute,
        arguments: {
          'isBankTransferEnabled':
              (context.read<GetApiKeysCubit>().state as GetApiKeysSuccess)
                      .bankTransferStatus ==
                  '1',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: context.color.backgroundColor,
      child: AnimatedContainer(
        curve:
            _tabController.index == 0 ? Curves.easeOutBack : Curves.easeInBack,
        duration: const Duration(milliseconds: 250),
        width: 328.rw(context),
        height: _tabController.index == 0 ? 490.rh(context) : 350.rh(context),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 16),
              UiUtils.getDivider(context),
              const SizedBox(height: 16),
              // Content
              BlocConsumer<CreateAdvertisementCubit, CreateAdvertisementState>(
                listener: (context, state) {
                  if (state is CreateAdvertisementInProgress) {
                    Widgets.showLoader(context);
                  }
                  if (state is CreateAdvertisementFailure) {
                    Widgets.hideLoder(context);
                    Navigator.pop(context);
                    HelperUtils.showSnackBarMessage(
                      context,
                      UiUtils.translate(
                          context, state.errorMessage.translate(context)),
                      type: MessageType.warning,
                    );
                  }
                  if (state is CreateAdvertisementSuccess) {
                    Widgets.hideLoder(context);
                    Navigator.pop(context);
                    HelperUtils.showSnackBarMessage(
                      context,
                      state.message.translate(context),
                      type: MessageType.success,
                    );
                  }
                },
                builder: (context, state) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Style Selection Tabs
                      _buildStyleSelectionTabs(),
                      const SizedBox(height: 16),

                      // Preview Section
                      _buildPreviewSection(),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 24.rh(context),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CustomText(
            UiUtils.translate(context, 'createAdvertisment'),
            fontSize: context.font.md,
            fontWeight: FontWeight.bold,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              alignment: Alignment.center,
              height: 24.rh(context),
              width: 24.rw(context),
              child: CustomImage(
                imageUrl: AppIcons.closeCircle,
                color: context.color.textColorDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSelectionTabs() {
    return Container(
      height: 48.rh(context),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: context.color.tertiaryColor,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: context.color.tertiaryColor,
          borderRadius: BorderRadius.circular(4),
        ),
        labelStyle: TextStyle(
          fontSize: context.font.md,
          color: context.color.buttonColor,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: context.font.md,
          color: context.color.textColorDark,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            text: 'grid'.translate(context),
          ),
          Tab(
            text: 'list'.translate(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return SizedBox(
      height: _tabController.index == 0 ? 273.rh(context) : 132.rh(context),
      child: IndexedStack(
        index: _tabController.index,
        children: [
          getPreview(index: 0),
          getPreview(index: 1),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return BlocConsumer<GetSubsctiptionPackageLimitsCubit,
        GetSubscriptionPackageLimitsState>(
      listener: (context, state) {
        if (state is GetSubsctiptionPackageLimitsFailure) {
          UiUtils.showBlurredDialoge(
            context,
            dialog: BlurredDialogBox(
              title: state.errorMessage,
              isAcceptContainesPush: true,
              onAccept: () async {
                await Navigator.popAndPushNamed(
                  context,
                  Routes.subscriptionPackageListRoute,
                  arguments: {
                    'from': 'propertyDetails',
                    'isBankTransferEnabled': (context
                                .read<GetApiKeysCubit>()
                                .state as GetApiKeysSuccess)
                            .bankTransferStatus ==
                        '1',
                  },
                );
              },
              content: CustomText(
                'yourPackageLimitOver'.translate(context),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is GetSubscriptionPackageLimitsSuccess) {
          hasPackage = state.hasSubscription == true;
        }

        return SizedBox(
          height: 48.rh(context),
          child: Row(
            children: [
              Expanded(
                child: UiUtils.buildButton(
                  context,
                  buttonColor: context.color.primaryColor,
                  textColor: context.color.tertiaryColor,
                  onPressed: _showAdvertisePropertyDialog,
                  showElevation: false,
                  buttonTitle: UiUtils.translate(context, 'info'),
                  border: BorderSide(
                    color: context.color.tertiaryColor,
                  ),
                  fontSize: context.font.md,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: UiUtils.buildButton(
                  context,
                  onPressed: _handlePromoteAction,
                  showElevation: false,
                  buttonTitle: hasPackage
                      ? UiUtils.translate(context, 'promote')
                      : UiUtils.translate(context, 'subscribe'),
                  fontSize: context.font.md,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
