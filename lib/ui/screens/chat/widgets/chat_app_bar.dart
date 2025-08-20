import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/chat/helpers/chat_helpers.dart';
import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    required this.profilePicture,
    required this.userName,
    required this.propertyTitle,
    required this.propertyImage,
    required this.isBlockedByMe,
    required this.isBlockedByUser,
    required this.isNotificationPermissionGranted,
    required this.userId,
    required this.propertyId,
    required this.onMenuSelected,
    required this.isFrom,
    super.key,
  });

  final String profilePicture;
  final String userName;
  final String propertyTitle;
  final String propertyImage;
  final bool isBlockedByMe;
  final bool isBlockedByUser;
  final bool isNotificationPermissionGranted;
  final String userId;
  final String propertyId;
  final Future<void> Function(String action) onMenuSelected;
  final String isFrom;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    final color = context.color;

    return CustomAppBar(
      onTapBackButton: () async {
        await context.read<GetChatListCubit>().fetch(forceRefresh: true);
      },
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomImageHeroAnimation(
            type: CImageType.network,
            image: profilePicture.isEmpty
                ? appSettings.placeholderLogo!
                : profilePicture,
            child: CircleAvatar(
              radius: 18,
              backgroundImage: CachedNetworkImageProvider(profilePicture),
            ),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                userName,
                fontSize: context.font.sm,
                fontWeight: FontWeight.w500,
                color: context.color.textColorDark,
              ),
              CustomText(
                propertyTitle,
                maxLines: 1,
                fontSize: context.font.xs,
                color: context.color.textColorDark,
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (propertyImage.isNotEmpty)
          GestureDetector(
            onTap: () async {
              if (isFrom == 'property') {
                Navigator.pop(context);
              } else {
                await ChatHelpers.onTapPropertyDetails(
                  context,
                  userId,
                  propertyId,
                );
              }
            },
            child: Container(
              margin: const EdgeInsetsDirectional.only(end: 8),
              width: 46.rw(context),
              height: 46.rh(context),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(propertyImage),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        PopupMenuButton<String>(
          onSelected: onMenuSelected,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: color.primaryColor,
          icon: Icon(
            Icons.more_vert,
            color: context.color.tertiaryColor,
          ),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'agentDetails',
              child: CustomText('agentDetails'.translate(context)),
            ),
            if (!(isBlockedByUser || isBlockedByMe))
              PopupMenuItem(
                value: 'deleteAllMessages',
                child: CustomText('deleteAllMessages'.translate(context)),
              ),
            if (!isBlockedByMe)
              PopupMenuItem(
                value: 'blockUser',
                child: CustomText('blockUser'.translate(context)),
              ),
            if (isBlockedByMe)
              PopupMenuItem(
                value: 'unblockUser',
                child: CustomText('unblockUser'.translate(context)),
              ),
          ],
        ),
      ],
    );
  }
}
