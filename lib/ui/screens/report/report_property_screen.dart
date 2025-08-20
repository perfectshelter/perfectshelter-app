import 'package:perfectshelter/data/cubits/report/fetch_property_report_reason_list.dart';
import 'package:perfectshelter/data/cubits/report/property_report_cubit.dart';
import 'package:perfectshelter/data/model/report_property/reason_model.dart';
import 'package:perfectshelter/utils/Extensions/extensions.dart';
import 'package:perfectshelter/utils/extensions/lib/custom_text.dart';
import 'package:perfectshelter/utils/helper_utils.dart';
import 'package:perfectshelter/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportPropertyScreen extends StatefulWidget {
  const ReportPropertyScreen({required this.propertyId, super.key});
  final int propertyId;

  @override
  State<ReportPropertyScreen> createState() => _ReportPropertyScreenState();
}

class _ReportPropertyScreenState extends State<ReportPropertyScreen> {
  List<ReportReason>? reasons = [];
  late int selectedId;
  final TextEditingController _reportmessageController =
      TextEditingController();
  @override
  void initState() {
    reasons =
        context.read<FetchPropertyReportReasonsListCubit>().getList() ?? [];

    if (reasons?.isEmpty ?? true) {
      selectedId = -10;
    } else {
      selectedId = reasons!.first.id;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom - 50;
    final isBottomPaddingNagative = bottomPadding.isNegative;
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              'reportProperty'.translate(context),
              fontSize: context.font.md,
              fontWeight: FontWeight.w500,
            ),
            const SizedBox(height: 12),
            UiUtils.getDivider(context),
            const SizedBox(height: 12),
            ...List.generate(
              reasons?.length ?? 0,
              (index) {
                return GestureDetector(
                  onTap: () {
                    if (selectedId == reasons![index].id) {
                      // selectedId = -10;
                    } else {
                      selectedId = reasons![index].id;
                    }
                    setState(() {});
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: context.color.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: selectedId == reasons?[index].id
                            ? context.color.textColorDark
                            : context.color.textLightColor,
                      ),
                    ),
                    child: CustomText(
                      reasons?[index].reason.firstUpperCase() ?? '',
                      color: selectedId == reasons?[index].id
                          ? context.color.textColorDark
                          : context.color.textLightColor,
                    ),
                  ),
                );
              },
            ),
            if (selectedId.isNegative)
              Padding(
                padding: EdgeInsets.only(
                  bottom: isBottomPaddingNagative ? 0 : bottomPadding,
                ),
                child: TextField(
                  maxLines: null,
                  scrollPadding: EdgeInsets.zero,
                  controller: _reportmessageController,
                  cursorColor: context.color.textColorDark,
                  decoration: InputDecoration(
                    hintText: 'writeReasonHere'.translate(context),
                    focusColor: context.color.textColorDark,
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: context.color.textColorDark),
                    ),
                  ),
                ),
              ),
            const SizedBox(
              height: 14,
            ),
            BlocConsumer<PropertyReportCubit, PropertyReportState>(
              listener: (context, state) {
                if (state is PropertyReportInSuccess) {
                  HelperUtils.showSnackBarMessage(
                    context,
                    state.responseMessage,
                  );

                  Navigator.pop(context);
                }
              },
              builder: (context, state) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: UiUtils.buildButton(
                        context,
                        height: 40,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        buttonTitle: 'cancelLbl'.translate(context),
                        buttonColor: context.color.secondaryColor,
                        textColor: context.color.tertiaryColor,
                        fontSize: context.font.sm,
                        border: BorderSide(color: context.color.tertiaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: UiUtils.buildButton(
                        context,
                        height: 40,
                        buttonTitle: 'report'.translate(context),
                        buttonColor: context.color.tertiaryColor,
                        textColor: context.color.buttonColor,
                        fontSize: context.font.sm,
                        border: BorderSide(color: context.color.borderColor),
                        onPressed: () async {
                          if (selectedId.isNegative) {
                            await context.read<PropertyReportCubit>().report(
                                  propertyId: widget.propertyId,
                                  reasonId: selectedId,
                                  message: _reportmessageController.text,
                                );
                          } else {
                            await context.read<PropertyReportCubit>().report(
                                  propertyId: widget.propertyId,
                                  reasonId: selectedId,
                                );
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
