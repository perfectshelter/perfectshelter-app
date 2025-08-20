import 'package:perfectshelter/data/cubits/agents/fetch_agents_cubit.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/agents/cards/agent_card.dart';
import 'package:perfectshelter/utils/sliver_grid_delegate_with_fixed_cross_axis_count_and_fixed_height.dart';
import 'package:flutter/material.dart';

class AgentListScreen extends StatefulWidget {
  const AgentListScreen({
    super.key,
    this.title,
  });

  final String? title;

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>? ?? {};
    return CupertinoPageRoute(
      builder: (_) => AgentListScreen(
        title: args['title'] as String? ?? '',
      ),
    );
  }

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen> {
  @override
  void initState() {
    context.read<FetchAgentsCubit>().fetchAgents(
          forceRefresh: false,
        );
    addPageScrollListener();
    super.initState();
  }

  void addPageScrollListener() {
    agentsListScreenController.addListener(pageScrollListener);
  }

  void pageScrollListener() {
    ///This will load data on page end
    if (agentsListScreenController.isEndReached()) {
      if (mounted) {
        if (context.read<FetchAgentsCubit>().hasMoreData()) {
          context.read<FetchAgentsCubit>().fetchMore();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: buildAgentsList(context));
  }

  Widget buildAgentsList(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final isBigTablet = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: CustomText(widget.title ?? UiUtils.translate(context, 'agents')),
      ),
      body: SingleChildScrollView(
        physics: Constant.scrollPhysics,
        controller: agentsListScreenController,
        child: Column(
          children: <Widget>[
            BlocBuilder<FetchAgentsCubit, FetchAgentsState>(
              builder: (context, state) {
                if (state is FetchAgentsFailure) {
                  return const SomethingWentWrong();
                }
                if (state is FetchAgentsLoading) {
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 8,
                      bottom: 8,
                    ),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      crossAxisCount: isBigTablet
                          ? 4
                          : isTablet
                              ? 3
                              : 2,
                      height: 258.rh(context),
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return CustomShimmer(
                        height: 258.rh(context),
                        width: 150.rw(context),
                      );
                    },
                  );
                }
                if (state is FetchAgentsSuccess && state.agents.isEmpty) {
                  return NoDataFound(
                    onTap: () {
                      Navigator.pushNamed(context, Routes.agentListScreen);
                    },
                  );
                }
                if (state is FetchAgentsSuccess && state.agents.isNotEmpty) {
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 8,
                      bottom: 8,
                    ),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      crossAxisCount: isBigTablet
                          ? 4
                          : isTablet
                              ? 3
                              : 2,
                      height: 258.rh(context),
                    ),
                    itemCount: state.agents.length,
                    itemBuilder: (context, index) {
                      final agent = state.agents[index];
                      return AgentCard(
                        agent: agent,
                        propertyCount: agent.propertyCount,
                        name: agent.name,
                      );
                    },
                  );
                }
                return Container();
              },
            ),
            if (context.watch<FetchAgentsCubit>().isLoadingMore()) ...[
              Center(
                child: UiUtils.progress(
                  height: 30.rh(context),
                  width: 30.rw(context),
                ),
              ),
            ],
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}
