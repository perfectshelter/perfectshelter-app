import 'package:perfectshelter/data/model/mortgage_calculator_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/utils/price_format.dart';
import 'package:flutter/material.dart';

class YearlyBreakdownScreen extends StatefulWidget {
  const YearlyBreakdownScreen({
    required this.mortgageCalculatorModel,
    super.key,
  });
  final MortgageCalculatorModel mortgageCalculatorModel;

  @override
  State<YearlyBreakdownScreen> createState() => _YearlyBreakdownScreenState();
}

class _YearlyBreakdownScreenState extends State<YearlyBreakdownScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return widget.mortgageCalculatorModel.yearlyTotals.isEmpty
        ? const Center(
            child: NoDataFound(),
          )
        : Scaffold(
            backgroundColor: context.color.secondaryColor,
            appBar: CustomAppBar(
              title: CustomText(UiUtils.translate(context, 'yearlyBreakdown')),
            ),
            body: SingleChildScrollView(
              physics: Constant.scrollPhysics,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.1,
                    decoration: BoxDecoration(
                      color: context.color.tertiaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSummaryRow(
                          'principalAmount'.translate(context),
                          (widget.mortgageCalculatorModel.mainTotal
                                      ?.principalAmount ??
                                  '0')
                              .priceFormat(context: context),
                        ),
                        const Spacer(),
                        _buildSummaryRow(
                          'monthlyEMI'.translate(context),
                          (widget.mortgageCalculatorModel.mainTotal
                                      ?.monthlyEmi ??
                                  '0')
                              .priceFormat(context: context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  ...List.generate(
                    widget.mortgageCalculatorModel.yearlyTotals.length,
                    (index) {
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 8),
                        child: _buildYearContent(
                          yearData: widget
                              .mortgageCalculatorModel.yearlyTotals[index],
                          initiallyExpanded: index == 0,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildYearContent({
    required YearlyTotals yearData,
    required bool initiallyExpanded,
  }) {
    return ExpansionTile(
      childrenPadding: EdgeInsets.zero,
      expandedAlignment: Alignment.centerLeft,
      iconColor: context.color.tertiaryColor,
      collapsedIconColor: context.color.inverseSurface,
      title: CustomText(
        yearData.year ?? '',
        fontWeight: FontWeight.bold,
        fontSize: context.font.lg,
      ),
      textColor: context.color.tertiaryColor,
      collapsedTextColor: context.color.textColorDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: context.color.borderColor,
        ),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: context.color.borderColor,
        ),
      ),
      collapsedBackgroundColor: context.color.secondaryColor,
      backgroundColor: context.color.secondaryColor,
      initiallyExpanded: initiallyExpanded,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 16,
            ),
            _buildSummaryRow(
              'principalAmount'.translate(context),
              (yearData.principalAmount ?? '').priceFormat(context: context),
            ),
            const Spacer(),
            _buildSummaryRow(
              'outstandingAmount'.translate(context),
              (yearData.remainingBalance ?? '0').priceFormat(context: context),
            ),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
        _buildPaymentScheduleTable(monthData: yearData.monthlyTotals ?? []),
        const SizedBox(
          height: 16,
        ),
      ],
    );
  }

  Widget _buildPaymentScheduleTable({required List<MonthlyTotals> monthData}) {
    const cellPadding = 12.0;
    return DataTable(
      dividerThickness: 0,
      // horizontalMargin: 10,
      columnSpacing: 4,
      headingRowColor: WidgetStatePropertyAll(context.color.tertiaryColor),
      columns: [
        DataColumn(
          label: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: cellPadding),
            child: CustomText(
              'month'.translate(context),
              fontWeight: FontWeight.bold,
              fontSize: context.font.xs,
              color: context.color.primaryColor,
            ),
          ),
        ),
        DataColumn(
          label: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: cellPadding),
            child: CustomText(
              'principal'.translate(context),
              fontWeight: FontWeight.bold,
              fontSize: context.font.xs,
              color: context.color.primaryColor,
            ),
          ),
        ),
        DataColumn(
          label: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: cellPadding),
            child: CustomText(
              'interest'.translate(context),
              fontWeight: FontWeight.bold,
              fontSize: context.font.xs,
              color: context.color.primaryColor,
            ),
          ),
        ),
        DataColumn(
          label: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: cellPadding),
            child: CustomText(
              'outstanding'.translate(context),
              fontWeight: FontWeight.bold,
              fontSize: context.font.xs,
              color: context.color.primaryColor,
            ),
          ),
        ),
      ],
      rows: List.generate(
        monthData.length,
        (index) => DataRow(
          color: index.isOdd
              ? WidgetStatePropertyAll(
                  context.color.tertiaryColor.withValues(alpha: 0.1),
                )
              : WidgetStatePropertyAll(context.color.secondaryColor),
          cells: [
            DataCell(
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: cellPadding),
                child: CustomText(
                  '${monthData[index].month?.substring(0, 3)}'
                      .toLowerCase()
                      .translate(context),
                  textAlign: TextAlign.center,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DataCell(
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: cellPadding),
                child: CustomText(
                  (monthData[index].principalAmount ?? '0')
                      .priceFormat(context: context),
                  textAlign: TextAlign.center,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DataCell(
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: cellPadding),
                child: CustomText(
                  (monthData[index].payableInterest ?? '0')
                      .priceFormat(context: context),
                  textAlign: TextAlign.center,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DataCell(
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: cellPadding),
                child: CustomText(
                  (monthData[index].remainingBalance ?? '0')
                      .priceFormat(context: context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            label,
            fontSize: context.font.md,
          ),
          CustomText(
            value,
            fontSize: context.font.xl,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}
