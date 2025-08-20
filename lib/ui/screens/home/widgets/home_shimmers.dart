import 'package:perfectshelter/ui/screens/home/home_screen.dart';
import 'package:perfectshelter/ui/screens/widgets/custom_shimmer.dart';
import 'package:perfectshelter/utils/constant.dart';
import 'package:perfectshelter/utils/extensions/extensions.dart';
import 'package:perfectshelter/utils/responsive_size.dart';
import 'package:flutter/material.dart';

class HomeShimmer extends StatefulWidget {
  const HomeShimmer({super.key});

  @override
  State<HomeShimmer> createState() => _HomeShimmerState();
}

ScrollController _scrollController = ScrollController();

void initState() {
  _scrollController.addListener(() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  });
}

class _HomeShimmerState extends State<HomeShimmer> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: ListView(
        shrinkWrap: true,
        controller: _scrollController,
        physics: Constant.scrollPhysics,
        children: [
          CustomShimmer(
            height: 170,
            width: context.screenWidth,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48.rh(context),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return CustomShimmer(
                  margin: const EdgeInsetsDirectional.only(end: 12),
                  height: 48.rh(context),
                  width: 84.rw(context),
                );
              },
              itemCount: 5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 274.rh(context),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return CustomShimmer(
                  margin: const EdgeInsetsDirectional.only(end: 10),
                  height: 274.rh(context),
                  width: 290.rw(context),
                );
              },
              itemCount: 5,
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return CustomShimmer(
                  height: 130.rh(context),
                  margin: const EdgeInsetsDirectional.only(bottom: 12),
                );
              },
              itemCount: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class PromotedPropertiesShimmer extends StatelessWidget {
  const PromotedPropertiesShimmer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 261,
      child: ListView.builder(
        itemCount: 5,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          horizontal: sidePadding,
        ),
        scrollDirection: Axis.horizontal,
        physics: Constant.scrollPhysics,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 8),
            child: const CustomShimmer(
              height: 272,
              width: 250,
            ),
          );
        },
      ),
    );
  }
}

class NearbyPropertiesShimmer extends StatelessWidget {
  const NearbyPropertiesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: 5,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          horizontal: sidePadding,
        ),
        scrollDirection: Axis.horizontal,
        physics: Constant.scrollPhysics,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 8),
            child: const CustomShimmer(
              height: 200,
              width: 300,
            ),
          );
        },
      ),
    );
  }
}
