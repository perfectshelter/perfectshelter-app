import 'package:perfectshelter/data/cubits/interested/get_interested_user_cubit.dart';
import 'package:perfectshelter/data/model/interested_user_model.dart';
import 'package:perfectshelter/utils/constant.dart';
import 'package:perfectshelter/utils/custom_image.dart';
import 'package:perfectshelter/utils/extensions/extensions.dart';
import 'package:perfectshelter/utils/extensions/lib/custom_text.dart';
import 'package:perfectshelter/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class InterestedUserListWidget extends StatefulWidget {
  const InterestedUserListWidget({
    required this.totalCount,
    required this.interestedUserCubitReference,
    super.key,
  });

  final String totalCount;
  final GetInterestedUserCubit interestedUserCubitReference;

  @override
  State<InterestedUserListWidget> createState() =>
      _InterestedUserListWidgetState();
}

class _InterestedUserListWidgetState extends State<InterestedUserListWidget> {
  final ScrollController _bottomSheetScrollController = ScrollController();

  @override
  void initState() {
    _bottomSheetScrollController.addListener(() {
      if (_bottomSheetScrollController.isEndReached()) {
        if (widget.interestedUserCubitReference.hasMoreData()) {
          widget.interestedUserCubitReference.fetchMore();
        }
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SingleChildScrollView(
        physics: Constant.scrollPhysics,
        controller: _bottomSheetScrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: CustomText(
                'interestedUsers'.translate(context),
                fontWeight: FontWeight.bold,
                fontSize: context.font.lg,
              ),
            ),
            BlocBuilder<GetInterestedUserCubit, GetInterestedUserState>(
              bloc: widget.interestedUserCubitReference,
              builder: (context, state) {
                if (state is GetInterestedUserInProgress) {
                  return Center(child: UiUtils.progress());
                }

                if (state is GetInterestedUserSuccess) {
                  if (state.list.isEmpty) {
                    return const Center(
                      child: CustomText('No data found'),
                    );
                  }
                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final interestedUser = state.list[index];

                      return InterestedUserCard(
                        interestedUser: interestedUser,
                      );
                    },
                    itemCount: state.list.length,
                    shrinkWrap: true,
                  );
                }
                return Container();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class InterestedUserCard extends StatelessWidget {
  const InterestedUserCard({
    required this.interestedUser,
    super.key,
  });

  final InterestedUserModel interestedUser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // CircleAvatar(radius: 25, backgroundImage: SvgPro),
          Container(
            width: 50,
            height: 50,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              // color: Colors.red,
            ),
            child: CustomImage(
              imageUrl: interestedUser.image ?? '',
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            flex: 3,
            child: CustomText(interestedUser.name ?? ''),
          ),
          const SizedBox(
            width: 10,
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async {
                  await launchUrl(
                    Uri.parse('mailto:${interestedUser.email}'),
                    mode: LaunchMode.externalApplication,
                  );
                },
                icon: Icon(
                  Icons.email,
                  color: context.color.tertiaryColor,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await launchUrl(
                    Uri.parse('tel:${interestedUser.mobile}'),
                    mode: LaunchMode.externalApplication,
                  );
                },
                color: context.color.tertiaryColor,
                icon: const Icon(Icons.call),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
