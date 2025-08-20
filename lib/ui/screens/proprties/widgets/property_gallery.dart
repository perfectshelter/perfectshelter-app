import 'package:perfectshelter/data/model/project_model.dart';
import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/ui/screens/widgets/all_gallary_image.dart';
import 'package:perfectshelter/ui/screens/widgets/video_view_screen.dart';
import 'package:flutter/material.dart';

class PropertyGallery extends StatelessWidget {
  const PropertyGallery({
    required this.gallary,
    required this.youtubeVideoThumbnail,
    required this.flickManager,
    required this.onShowGoogleMap,
    super.key,
  });
  final List<Gallery>? gallary;
  final String youtubeVideoThumbnail;
  final FlickManager? flickManager;
  final VoidCallback onShowGoogleMap;

  @override
  Widget build(BuildContext context) {
    if (gallary?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          UiUtils.translate(context, 'gallery'),
          fontWeight: FontWeight.w600,
          color: context.color.textColorDark,
          fontSize: context.font.md,
        ),
        SizedBox(height: 8.rh(context)),
        SizedBox(
          height: 90.rh(context),
          width: double.infinity,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: gallary?.length.clamp(0, 5) ?? 0,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (gallary?[index].isVideo ?? false) {
                        return;
                      }

                      // Hide Google map before showing image gallery
                      onShowGoogleMap();

                      final images = gallary?.map((e) => e.imageUrl).toList();

                      UiUtils.imageGallaryView(
                        context,
                        images: images!,
                        initalIndex: index,
                        then: onShowGoogleMap,
                      );
                    },
                    child: SizedBox(
                      width: 90.rw(context),
                      height: 90.rh(context),
                      child: gallary?[index].isVideo ?? false
                          ? CustomImage(imageUrl: youtubeVideoThumbnail)
                          : CustomImage(
                              imageUrl: gallary?[index].imageUrl ?? '',
                            ),
                    ),
                  ),
                  _buildVideoOverlay(context, index),
                  _buildMoreImagesOverlay(context, index),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoOverlay(BuildContext context, int index) {
    if (!(gallary?[index].isVideo ?? false)) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute<dynamic>(
              builder: (context) {
                return VideoViewScreen(
                  videoUrl: gallary?[index].image ?? '',
                  flickManager: flickManager,
                );
              },
            ),
          );
        },
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.3),
          child: FittedBox(
            fit: BoxFit.none,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.color.tertiaryColor.withValues(alpha: 0.8),
              ),
              width: 30,
              height: 30,
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreImagesOverlay(BuildContext context, int index) {
    if (index != 4 || (gallary?.length ?? 0) <= 5) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute<dynamic>(
              builder: (context) {
                return AllGallaryImages(
                  youtubeThumbnail: youtubeVideoThumbnail,
                  images: gallary ?? [],
                );
              },
            ),
          );
        },
        child: Container(
          alignment: Alignment.center,
          color: Colors.black.withValues(alpha: 0.3),
          child: CustomText(
            '+${(gallary?.length ?? 0) - 3}',
            fontWeight: FontWeight.bold,
            fontSize: context.font.md,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class ProjectGallery extends StatelessWidget {
  const ProjectGallery({
    required this.gallary,
    required this.onShowGoogleMap,
    super.key,
  });
  final List<ProjectGalleryModel>? gallary;
  final VoidCallback onShowGoogleMap;

  @override
  Widget build(BuildContext context) {
    if (gallary?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          UiUtils.translate(context, 'gallery'),
          fontWeight: FontWeight.w600,
          color: context.color.textColorDark,
          fontSize: context.font.md,
        ),
        SizedBox(height: 8.rh(context)),
        SizedBox(
          height: 90.rh(context),
          width: double.infinity,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: gallary?.length.clamp(0, 5) ?? 0,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Hide Google map before showing image gallery
                      onShowGoogleMap();

                      final images = gallary?.map((e) => e.name).toList();

                      UiUtils.imageGallaryView(
                        context,
                        images: images!,
                        initalIndex: index,
                        then: onShowGoogleMap,
                      );
                    },
                    child: SizedBox(
                      width: 90.rw(context),
                      height: 90.rh(context),
                      child: CustomImage(
                        imageUrl: gallary?[index].name ?? '',
                      ),
                    ),
                  ),
                  _buildMoreImagesOverlay(context, index),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreImagesOverlay(BuildContext context, int index) {
    if (index != 4 || (gallary?.length ?? 0) <= 5) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute<dynamic>(
              builder: (context) {
                return AllGallaryImages(
                  youtubeThumbnail: '',
                  images: gallary ?? [],
                );
              },
            ),
          );
        },
        child: Container(
          alignment: Alignment.center,
          color: Colors.black.withValues(alpha: 0.3),
          child: CustomText(
            '+${(gallary?.length ?? 0) - 3}',
            fontWeight: FontWeight.bold,
            fontSize: context.font.md,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
