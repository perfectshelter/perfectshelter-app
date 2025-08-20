import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:perfectshelter/ui/screens/home/widgets/project_card_horizontal.dart';
import 'package:flutter/material.dart';

class MyProjects extends StatefulWidget {
  const MyProjects({super.key});

  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) {
        return const MyProjects();
      },
    );
  }

  @override
  State<MyProjects> createState() => _MyProjectsState();
}

class _MyProjectsState extends State<MyProjects> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    context.read<FetchMyProjectsListCubit>().fetchMyProjects();

    _scrollController.addListener(() {
      if (_scrollController.isEndReached()) {
        if (context.read<FetchMyProjectsListCubit>().hasMoreData()) {
          context.read<FetchMyProjectsListCubit>().fetchMore(
                isPromoted: false,
              );
        }
      }
    });
    super.initState();
  }

  String statusText(String text) {
    if (text == '1') {
      return UiUtils.translate(context, 'active');
    } else if (text == '0') {
      return UiUtils.translate(context, 'inactive');
    } else if (text == 'rejected') {
      return UiUtils.translate(context, 'rejected');
    } else if (text == 'pending') {
      return UiUtils.translate(context, 'pending');
    }
    return '';
  }

  Color statusColor(String text) {
    if (text == '1') {
      return Colors.green;
    } else if (text == '0') {
      return Colors.orangeAccent;
    } else if (text == 'rejected') {
      return Colors.redAccent;
    } else if (text == 'pending') {
      return Colors.blue;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: CustomText(UiUtils.translate(context, 'myProjects')),
      ),
      body: CustomRefreshIndicator(
        onRefresh: () async {
          await context.read<FetchMyProjectsListCubit>().fetchMyProjects();
        },
        child: BlocBuilder<FetchMyProjectsListCubit, FetchMyProjectsListState>(
          builder: (context, state) {
            if (state is FetchMyProjectsListInProgress) {
              return UiUtils.buildHorizontalShimmer(context);
            }
            if (state is FetchMyProjectsListFail) {
              if (state.error is NoInternetConnectionError) {
                return NoInternet(
                  onRetry: () {
                    context.read<FetchMyProjectsListCubit>().fetchMyProjects();
                  },
                );
              }
              return const SomethingWentWrong();
            }
            if (state is FetchMyProjectsListSuccess) {
              if (state.projects.isEmpty) {
                return const NoDataFound();
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      physics: Constant.scrollPhysics,
                      shrinkWrap: true,
                      controller: _scrollController,
                      itemCount: state.projects.length,
                      padding: const EdgeInsets.all(14),
                      itemBuilder: (context, index) {
                        final project = state.projects[index];
                        final requestStatus =
                            project.requestStatus == 'approved'
                                ? project.status.toString()
                                : project.requestStatus.toString();
                        return ProjectHorizontalCard(
                          project: project,
                          isRejected: project.requestStatus == 'rejected',
                          statusButton: StatusButton(
                            lable: statusText(requestStatus),
                            color: statusColor(requestStatus)
                                .withValues(alpha: 0.2),
                            textColor: statusColor(requestStatus),
                          ),
                        );
                      },
                    ),
                  ),
                  if (context
                      .watch<FetchMyProjectsListCubit>()
                      .hasMoreData()) ...[
                    Center(child: UiUtils.progress()),
                  ],
                ],
              );
              // return ProjectCard(title: "Hello",categoryIcon: ,);
            }
            if (state is FetchMyProjectsListFail) {
              return Center(
                child: CustomText(state.error.toString()),
              );
            }

            return Container();
          },
        ),
      ),
    );
  }
}
