import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../controller/story_controller.dart';
import '../utils.dart';

class VideoLoader {
  String url;
  Widget placeholderWidget;
  File? videoFile;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading;

  VideoLoader(this.url, this.placeholderWidget, {this.requestHeaders});

  void loadVideo(VoidCallback onComplete) {
    if (this.videoFile != null) {
      this.state = LoadState.success;
      onComplete();
    }

    final fileStream = DefaultCacheManager().getFileStream(this.url,
        headers: this.requestHeaders as Map<String, String>?);

    fileStream.listen((fileResponse) {
      if (fileResponse is FileInfo) {
        if (this.videoFile == null) {
          this.state = LoadState.success;
          this.videoFile = fileResponse.file;
          onComplete();
        }
      }
    });
  }
}

class StoryVideo extends StatefulWidget {
  final StoryController? storyController;
  final VideoLoader videoLoader;

  StoryVideo(this.videoLoader, {this.storyController, Key? key})
      : super(key: key ?? UniqueKey());

  static StoryVideo url(String url, Widget placeholderWidget,
      {StoryController? controller,
      Map<String, dynamic>? requestHeaders,
      Key? key}) {
    return StoryVideo(
      VideoLoader(url, placeholderWidget, requestHeaders: requestHeaders),
      storyController: controller,
      key: key,
    );
  }

  @override
  State<StatefulWidget> createState() {
    return StoryVideoState();
  }
}

class StoryVideoState extends State<StoryVideo> {
  Future<void>? playerLoader;

  StreamSubscription? _streamSubscription;

  VideoPlayerController? playerController;

  @override
  void initState() {
    super.initState();

    widget.storyController!.pause();

    widget.videoLoader.loadVideo(() {
      if (widget.videoLoader.state == LoadState.success) {
        this.playerController =
            VideoPlayerController.file(widget.videoLoader.videoFile!);

        playerController!.initialize().then((v) {
          setState(() {});
          widget.storyController!.play();
        });

        if (widget.storyController != null) {
          _streamSubscription =
              widget.storyController!.playbackNotifier.listen((playbackState) {
            if (playbackState == PlaybackState.pause) {
              playerController!.pause();
            } else {
              playerController!.play();
            }
          });
        }
      } else {
        setState(() {});
      }
    });
  }

  Widget getContentView() {
    if (widget.videoLoader.state == LoadState.success &&
        playerController!.value.isInitialized) {
      // return AspectRatio(
      //   aspectRatio: playerController!.value.aspectRatio,
      //   child: VideoPlayer(playerController!),
      // );
      // return SizedBox.expand(
      //   child: Container(
      //     color: Colors.yellow,
      //     child: FittedBox(
      //       fit: BoxFit.cover,
      //       child: SizedBox(
      //         width: playerController!.value.size.width ?? 0,
      //         height: playerController!.value.size.height ?? 0,
      //         child: VideoPlayer(playerController!),
      //       ),
      //     ),
      //   ),
      // );
      // return FittedBox(
      //   fit: BoxFit.cover,
      //   child: SizedBox(
      //     width: playerController!.value.aspectRatio,
      //     height: 1,
      //     child: VideoPlayer(playerController!),
      //   ),
      // );
      // return SizedBox.expand(
      //   child: FittedBox(
      //     fit: BoxFit.fitWidth,
      //     child: Transform.scale(
      //       alignment: Alignment.center,
      //       scale: 1.15,
      //       child: SizedBox(
      //         width: playerController!.value.size.width,
      //         height: playerController!.value.size.height,
      //         child: VideoPlayer(playerController!),
      //       ),
      //     ),
      //   ),
      // );
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: playerController!.value.size.width,
          height: playerController!.value.size.height,
          child: AspectRatio(
            aspectRatio: playerController!.value.aspectRatio,
            child: VideoPlayer(playerController!),
          ),
        ),
      );
    }

    return widget.videoLoader.placeholderWidget;
    // SizedBox.expand(
    //   child: FittedBox(
    //     fit: BoxFit.fitHeight,
    //     child: Transform.scale(
    //       alignment: Alignment.center,
    //       scale: 1.0,
    //       child: widget.videoLoader.placeholderWidget,
    //     ),
    //   ),
    // )
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      // height: MediaQuery.of(context).size.height * .40,
      height: MediaQuery.of(context).size.height,
      // height: double.infinity,
      width: double.infinity,
      child: getContentView(),
    );
  }

  @override
  void dispose() {
    playerController?.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
