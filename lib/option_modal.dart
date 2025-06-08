import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

Future<void> optionModal(BuildContext context, String videoUrl) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return VideoPlayerModal(videoUrl: videoUrl);
    },
  );
}

class VideoPlayerModal extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerModal({required this.videoUrl});

  @override
  _VideoPlayerModalState createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();

    _videoPlayerController = VideoPlayerController.file(File(widget.videoUrl));

    _initializeVideoPlayerFuture =
        _videoPlayerController.initialize().then((_) {
      _videoPlayerController.setVolume(1.0);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: true,
        allowPlaybackSpeedChanging: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {});
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Center(
        child: Text(
          'Aperçu de votre vidéo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      content: FutureBuilder<void>(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized) {
            return AspectRatio(
              aspectRatio: _videoPlayerController.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Chewie(controller: _chewieController!),
              ),
            );
          } else if (snapshot.hasError) {
            return const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Erreur lors du chargement de la vidéo',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          } else {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
      actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
      actionsAlignment: MainAxisAlignment.end,
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            log('Options annulées');
          },
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            log('Options validées');
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
