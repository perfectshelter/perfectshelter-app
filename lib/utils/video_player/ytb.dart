import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YtbRepo {
  YoutubeExplode yt = YoutubeExplode();
  Future<Video> getVideoMetadata(String url) async {
    final video = await yt.videos.get(url);

    return video;
  }

  Future<List<Map<dynamic, dynamic>>> getOnlyAudio(String videoId) async {
    final temp = <Map<dynamic, dynamic>>[];
    final streamManifest = await yt.videos.streamsClient.getManifest(videoId);

    for (final audioStream in streamManifest.audioOnly) {
      temp.add({
        'type': 'audio',
        'url': audioStream.url.toString(),
        'size': audioStream.size.totalMegaBytes.toStringAsFixed(2),
        'quality': audioStream.qualityLabel,
        'bitrate': audioStream.bitrate.megaBitsPerSecond,
      });
    }
    return temp;
  }

  Future<List<Map<dynamic, dynamic>>> getMuxed(String videoId) async {
    final temp = <Map<dynamic, dynamic>>[];
    final streamManifest = await yt.videos.streamsClient.getManifest(videoId);

    for (final muxed in streamManifest.muxed) {
      temp.add({
        'type': 'video',
        'url': muxed.url.toString(),
        'size': muxed.size.totalMegaBytes.toStringAsFixed(2),
        'quality': muxed.videoQuality.name,
        'bitrate': muxed.bitrate.megaBitsPerSecond,
      });
    }
    return temp;
  }
}
