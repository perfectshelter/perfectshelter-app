import 'package:ebroker/data/model/agent/agent_model.dart';
import 'package:ebroker/exports/main_export.dart';

class AgentCard extends StatelessWidget {
  const AgentCard({
    required this.agent,
    required this.propertyCount,
    required this.name,
    super.key,
    this.isFirst,
    this.showEndPadding,
  });

  final AgentModel agent;
  final bool? isFirst;
  final bool? showEndPadding;
  final String name;
  final String propertyCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HelperUtils.share(context, agent.name);
      },
      onTap: () async {
        try {
          await Navigator.pushNamed(
            context,
            Routes.agentDetailsScreen,
            arguments: {
              'agentID': agent.id.toString(),
              'isAdmin': agent.isAdmin,
            },
          );
        } on Exception catch (_) {}
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: context.color.secondaryColor,
          border: Border.all(
            color: context.color.borderColor,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        width: 181.rw(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 135.rh(context),
              margin: EdgeInsets.only(bottom: 8.rh(context)),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CustomImage(
                  imageUrl: agent.profile,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Name
                  Row(
                    children: [
                      Flexible(
                        child: CustomText(
                          agent.name.firstUpperCase(),
                          fontWeight: FontWeight.w500,
                          fontSize: context.font.sm,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      if (agent.isVerified)
                        CustomImage(
                          imageUrl: AppIcons.agentBadge,
                          height: 24.rh(context),
                          width: 24.rw(context),
                          color: context.color.tertiaryColor,
                        ),
                    ],
                  ),
                  SizedBox(
                    height: 4.rh(context),
                  ),
                  //Email
                  CustomText(
                    agent.email,
                    fontSize: context.font.xs,
                    fontWeight: FontWeight.w400,
                    color: context.color.textLightColor,
                    maxLines: 1,
                  ),
                  SizedBox(
                    height: 8.rh(context),
                  ),
                  //Property count &  Project count
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          context.color.textLightColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                'properties'.translate(context),
                                fontSize: context.font.xxs,
                                fontWeight: FontWeight.w500,
                                maxLines: 1,
                                color: context.color.textLightColor,
                              ),
                            ),
                            CustomText(
                              agent.propertyCount,
                              fontSize: context.font.xxs,
                              fontWeight: FontWeight.w500,
                              maxLines: 1,
                              color: context.color.textLightColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        UiUtils.getDivider(context),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                'projects'.translate(context),
                                fontSize: context.font.xxs,
                                fontWeight: FontWeight.w500,
                                maxLines: 1,
                                color: context.color.textLightColor,
                              ),
                            ),
                            CustomText(
                              agent.projectsCount,
                              fontSize: context.font.xxs,
                              fontWeight: FontWeight.w500,
                              maxLines: 1,
                              color: context.color.textLightColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ),
          ],
        ),
      ),
    );
  }
}
