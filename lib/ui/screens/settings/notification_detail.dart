import 'package:ebroker/exports/main_export.dart';
import 'package:flutter/material.dart';

class NotificationDetail extends StatefulWidget {
  const NotificationDetail({super.key});

  @override
  State<NotificationDetail> createState() => _NotificationDetailState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const NotificationDetail(),
    );
  }
}

class _NotificationDetailState extends State<NotificationDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: CustomText(UiUtils.translate(context, 'notifications')),
      ),
      body: ListView(
        children: <Widget>[
          if (selectedNotification.image!.isNotEmpty)
            CustomImage(
              imageUrl: selectedNotification.image ?? '',
              width: double.maxFinite,
              height: 200.rh(context),
            ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: detailWidget(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    Routes.currentRoute = Routes.previousCustomerRoute;
    super.dispose();
  }

  Column detailWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          selectedNotification.title!,
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .merge(const TextStyle(fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 5),
        Text(
          selectedNotification.message!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
