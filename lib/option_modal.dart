import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer';
import 'dart:async'; // Import pour utiliser Timer

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

  VideoPlayerModal({required this.videoUrl});

  @override
  _VideoPlayerModalState createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  // Variables pour la barre de progression
  double _currentPosition = 0.0;
  double _totalDuration = 0.0;
  bool _isDragging = false;
  bool _isPlaying = false; // Pour gérer l'état du play/pause
  bool _showPlayPause = false; // Pour gérer l'affichage du bouton Play/Pause
  Timer? _hidePlayPauseTimer; // Timer pour cacher l'icône Play/Pause

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..setLooping(true)
      ..setVolume(1.0);

    _initializeVideoPlayerFuture = _controller.initialize();

    // Mettre à jour la position de la vidéo pendant sa lecture
    _controller.addListener(() {
      if (!_isDragging) {
        setState(() {
          _currentPosition = _controller.value.position.inSeconds.toDouble();
          _totalDuration = _controller.value.duration.inSeconds.toDouble();
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _hidePlayPauseTimer?.cancel(); // Annuler le timer lorsqu'on quitte la page
  }

  // Fonction pour sauter à une position dans la vidéo
  void _seekTo(double value) {
    final position = Duration(seconds: value.toInt());
    _controller.seekTo(position);
  }

  // Toggle play/pause
  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
      _showPlayPause = true; // Montrer le bouton Play/Pause lorsque l'utilisateur appuie sur la vidéo
    });

    // Démarrer un timer pour masquer le bouton après un certain délai (par exemple, 3 secondes)
    _hidePlayPauseTimer?.cancel(); // Annuler tout timer existant
    _hidePlayPauseTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        _showPlayPause = false; // Cacher le bouton après 3 secondes
      });
    });
  }

  // Fonction pour afficher le bouton Play/Pause au toucher
  void _onTap() {
    setState(() {
      _showPlayPause = true;
    });

    // Démarrer un timer pour masquer le bouton après un certain délai (par exemple, 3 secondes)
    _hidePlayPauseTimer?.cancel(); // Annuler tout timer existant
    _hidePlayPauseTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        _showPlayPause = false; // Cacher le bouton après 3 secondes
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Aperçu de votre vidéo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Voulez-vous vraiment valider ces options ?',
            style: TextStyle(fontSize: 13),
          ),
          SizedBox(height: 20),
          FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: _onTap, // Lorsque l'utilisateur appuie sur la vidéo
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    // Barre de progression
                    Positioned(
                      bottom: 10,
                      left: 20,
                      right: 20,
                      child: Slider(
                        value: _currentPosition,
                        min: 0.0,
                        max: _totalDuration,
                        onChanged: (value) {
                          setState(() {
                            _currentPosition = value;
                            _isDragging = true;
                          });
                        },
                        onChangeEnd: (value) {
                          _seekTo(value); // Sauter à la position sélectionnée
                          setState(() {
                            _isDragging = false;
                          });
                        },
                      ),
                    ),
                    // Afficher l'icône Play/Pause seulement si nécessaire
                    if (_showPlayPause)
                      Positioned(
                        child: IconButton(
                          onPressed: _togglePlayPause,
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                  ],
                );
              } else {
                return CircularProgressIndicator(); // En attendant que la vidéo soit prête
              }
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            log('Options annulées');
          },
          child: Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            log('Options validées');
          },
          child: Text('Valider'),
        ),
      ],
    );
  }
}
