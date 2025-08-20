import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/chat/chat_screen.dart';
import 'package:perfectshelter/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) {
        return const ChatListScreen();
      },
    );
  }

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    chatScreenController.addListener(() {
      if (chatScreenController.isEndReached() && mounted) {
        if (context.read<GetChatListCubit>().hasMoreData()) {
          context.read<GetChatListCubit>().loadMore();
        }
      }
    });
    if (context.read<GetChatListCubit>().state is! GetChatListSuccess) {
      context.read<GetChatListCubit>().fetch(forceRefresh: false);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: CustomAppBar(
          title: CustomText(UiUtils.translate(context, 'message')),
          showBackButton: false,
        ),
        body: CustomRefreshIndicator(
          onRefresh: () async {
            await context.read<GetChatListCubit>().fetch(forceRefresh: true);
          },
          child: BlocBuilder<GetChatListCubit, GetChatListState>(
            builder: (context, state) {
              if (state is GetChatListFailed) {
                if (state.error is NoInternetConnectionError) {
                  return NoInternet(
                    onRetry: () {
                      context.read<GetChatListCubit>().fetch(
                            forceRefresh: false,
                          );
                    },
                  );
                } else {
                  return ScrollConfiguration(
                    behavior: RemoveGlow(),
                    child: SingleChildScrollView(
                      physics: Constant.scrollPhysics,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: const SomethingWentWrong(),
                      ),
                    ),
                  );
                }
              }
              if (state is GetChatListInProgress) {
                return buildChatListShimmer();
              }
              if (state is GetChatListSuccess) {
                if (state.chatedUserList.isEmpty) {
                  return Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomImage(
                          imageUrl: AppIcons.noChatFound,
                          height: MediaQuery.of(context).size.height * 0.35,
                        ),
                        const SizedBox(height: 20),
                        CustomText(
                          UiUtils.translate(context, 'noChats'),
                          fontWeight: FontWeight.w600,
                          fontSize: context.font.xl,
                          color: context.color.tertiaryColor,
                        ),
                        const SizedBox(height: 14),
                        CustomText(
                          'startConversation'.translate(context),
                          textAlign: TextAlign.center,
                          fontSize: context.font.md,
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () {
                            context.read<GetChatListCubit>().fetch(
                                  forceRefresh: false,
                                );
                          },
                          child: SizedBox(
                            height: 50.rh(context),
                            child: Center(
                              child: CustomText(
                                'retry'.translate(context),
                                fontWeight: FontWeight.bold,
                                fontSize: context.font.sm,
                                color: context.color.tertiaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  physics: Constant.scrollPhysics,
                  controller: chatScreenController,
                  itemCount: state.chatedUserList.length,
                  padding: const EdgeInsetsDirectional.all(16),
                  itemBuilder: (context, index) {
                    final chatedUser = state.chatedUserList[index];

                    return ChatTile(
                      id: chatedUser.userId.toString(),
                      propertyId: chatedUser.propertyId.toString(),
                      profilePicture: chatedUser.profile ?? '',
                      userName: chatedUser.name ?? '',
                      propertyPicture: chatedUser.titleImage ?? '',
                      propertyName:
                          chatedUser.translatedTitle ?? chatedUser.title ?? '',
                      pendingMessageCount:
                          chatedUser.unreadCount?.toString() ?? '',
                      isBlockedByMe: chatedUser.isBlockedByMe ?? false,
                      isBlockedByUser: chatedUser.isBlockedByUser ?? false,
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget buildChatListShimmer() {
    return ListView.builder(
      itemCount: 10,
      physics: Constant.scrollPhysics,
      padding: const EdgeInsetsDirectional.all(16),
      itemBuilder: (context, index) {
        return SizedBox(
          height: 74.rh(context),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
                highlightColor:
                    Theme.of(context).colorScheme.shimmerHighlightColor,
                child: Stack(
                  children: [
                    SizedBox(width: 58.rw(context), height: 58.rh(context)),
                    Container(
                      width: 42.rw(context),
                      height: 42.rh(context),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        border: Border.all(
                          color: context.color.secondaryColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        height: 32.rh(context),
                        width: 32.rw(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomShimmer(
                    height: 10,
                    borderRadius: 4,
                    width: 220.rw(context),
                  ),
                  const SizedBox(height: 10),
                  CustomShimmer(
                    height: 10,
                    borderRadius: 4,
                    width: 180.rw(context),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => false;
}

class ChatTile extends StatelessWidget {
  const ChatTile({
    required this.profilePicture,
    required this.userName,
    required this.propertyPicture,
    required this.propertyName,
    required this.pendingMessageCount,
    required this.id,
    required this.propertyId,
    required this.isBlockedByMe,
    required this.isBlockedByUser,
    super.key,
  });

  final String profilePicture;
  final String userName;
  final String propertyPicture;
  final String propertyName;
  final String propertyId;
  final String pendingMessageCount;
  final String id;
  final bool isBlockedByMe;
  final bool isBlockedByUser;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute<dynamic>(
            builder: (context) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => LoadChatMessagesCubit()),
                  BlocProvider(create: (context) => DeleteMessageCubit()),
                ],
                child: Builder(
                  builder: (context) {
                    return ChatScreenNew(
                      profilePicture: profilePicture,
                      proeprtyTitle: propertyName,
                      userId: id,
                      propertyImage: propertyPicture,
                      userName: userName,
                      propertyId: propertyId,
                      isBlockedByMe: isBlockedByMe,
                      isBlockedByUser: isBlockedByUser,
                    );
                  },
                ),
              );
            },
          ),
        );
      },
      child: AbsorbPointer(
        child: Container(
          margin: const EdgeInsetsDirectional.only(bottom: 8),
          height: 74.rh(context),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.color.borderColor, width: 1.5),
          ),
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Stack(
                  children: [
                    SizedBox(width: 62.rw(context), height: 62.rh(context)),
                    Container(
                      width: 52.rw(context),
                      height: 52.rh(context),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CustomImage(
                        imageUrl: propertyPicture,
                      ),
                    ),
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.color.secondaryColor,
                            width: 2,
                          ),
                        ),
                        child: profilePicture == ''
                            ? CircleAvatar(
                                radius: 16,
                                backgroundColor: context.color.tertiaryColor,
                                child: CustomImage(
                                  imageUrl: appSettings.placeholderLogo!,
                                ),
                              )
                            : CircleAvatar(
                                radius: 16,
                                backgroundColor: context.color.tertiaryColor,
                                backgroundImage: NetworkImage(profilePicture),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        userName,
                        fontWeight: FontWeight.bold,
                        color: context.color.textColorDark,
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: CustomText(
                          propertyName,
                          maxLines: 1,
                          color: context.color.textColorDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pendingMessageCount != '0')
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.color.tertiaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: CustomText(
                      pendingMessageCount,
                      color: context.color.buttonColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
