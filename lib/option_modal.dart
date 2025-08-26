import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart'; // Gardons pour le fallback ou "Autres applications"
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_whatsapp_plus/share_whatsapp_plus.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart'; // NOUVEL IMPORT ICI
// Importez le fichier main.dart pour accéder à rootScaffoldMessengerKey
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'export_modal.dart';
import 'package:caroussel/notif.dart';

// La fonction qui affiche la modale principale (VideoPlayerModal)
Future<void> optionModal(BuildContext context, String videoUrl,
    {String? videoTitle}) {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return VideoPlayerModal(
          scaffoldMessenger: scaffoldMessenger,
          videoUrl: videoUrl,
          videoTitle: videoTitle);
    },
  );
}

// Le widget de la modale du lecteur vidéo
class VideoPlayerModal extends StatefulWidget {
  final String videoUrl;
  final String? videoTitle;
  final ScaffoldMessengerState scaffoldMessenger;

  const VideoPlayerModal(
      {required this.videoUrl,
      this.videoTitle,
      required this.scaffoldMessenger,
      super.key});

  @override
  _VideoPlayerModalState createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
// --- Fonctions Utilitaires ---
// Fonction de vérification des permissions (Android)
  Future<bool> _checkVideoPermission() async {
    // Vérifie si la permission est déjà accordée
    if (await Permission.videos.isGranted) return true;

    // Sinon, demande la permission
    final status = await Permission.videos.request();
    return status.isGranted;
  }

  // Fonction d'exportation (sauvegarde) de la vidéo
  Future<void> _exportVideo(BuildContext context, String videoPath) async {
    try {
      if (!await _checkVideoPermission()) {
        Fluttertoast.showToast(
          msg: "Permission refusée pour accéder aux vidéos",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return; // stop l'export
      }

      final File videoFile = File(videoPath);
      if (videoPath.isEmpty || !await videoFile.exists()) {
        log('[_exportVideo] Chemin vidéo invalide ou fichier inexistant : $videoPath');
        Fluttertoast.showToast(
          msg: 'Fichier vidéo introuvable',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      final String fileName = p.basename(videoPath);

      // Android → MediaStore
      const channel = MethodChannel('com.example.caroussel/media');
      final bool? success = await channel.invokeMethod('saveVideoToGallery', {
        'sourcePath': videoPath,
        'fileName': fileName,
      });

      if (success == true) {
        showVideoSavedNotification();

        final navigator = Navigator.of(context);
        // on ferme la modale avant d'afficher la suivante
        navigator.pop();
      //delai pour laisser le temps à l'utilisateur de lire la notification
        await Future.delayed(const Duration(seconds: 7));
        
        ExportDialog(navigator.context);
      } else {
        Fluttertoast.showToast(
          msg: 'Erreur lors de l\'enregistrement de la vidéo',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e, stackTrace) {
      log('[_exportVideo] Erreur inattendue : $e\nStackTrace: $stackTrace');
      widget.scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Une erreur est survenue : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      log('[_exportVideo] Exportation terminée pour : $videoPath');
    }
  }

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
        materialProgressColors: ChewieProgressColors(
          playedColor:
              const Color.from(alpha: 1, red: 0, green: 0.592, blue: 0.655),
          handleColor:
              const Color.from(alpha: 1, red: 0, green: 0.592, blue: 0.655),
          bufferedColor: Colors.grey,
          backgroundColor: Colors.white54,
        ),
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        showControls: true,
        showControlsOnInitialize: true,
        // showControlsOnPause: true, // Afficher les contrôles à la pause
        showOptions: true,
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
      _videoPlayerController.addListener(_videoListener);
      setState(() {});
    });
  }

  void _videoListener() {
    // Si la vidéo est terminée et qu'elle n'est pas en cours de lecture
    if (_videoPlayerController.value.position >=
            _videoPlayerController.value.duration &&
        !_videoPlayerController.value.isPlaying) {
      // Se remet au début
      _videoPlayerController.seekTo(Duration.zero);

      log('[VideoPlayerModal] Vidéo terminée, remise à 0.');
      // Ne pas appeler _videoPlayerController.pause(); car elle n\'est déjà pas en lecture,
      // et ne pas appeler .play() car on ne veut pas qu'elle se relance.
      _videoPlayerController.pause();
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    log('[dispose] VideoPlayerModal disposed.');
    super.dispose();
  }

  void _showError(String message) {
        try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // --- Fonctions de Partage Spécifiques ---

  // Partage générique (pour "Autres applications") - utilise share_plus
  Future<void> _shareVideoGeneric({String? appName}) async {
    try {
      final String videoPath = widget.videoUrl;
      final File videoFile = File(videoPath);
      if (videoPath.isNotEmpty && await videoFile.exists()) {
        await SharePlus.instance.share(
          ShareParams(
          files:   [XFile(videoPath)],
          text: 'Découvrez ma nouvelle vidéo !',
          subject: widget.videoTitle != null && widget.videoTitle!.isNotEmpty
              ? 'Vidéo "${widget.videoTitle!}" créée avec Caroussel !'
              : 'Ma vidéo créée avec Caroussel !',
          )
        
        );
        log('[_shareVideoGeneric] Partage vidéo initié avec succès pour : $videoPath');
        if (mounted) {
          String message =
              'Choisissez l\'application pour partager votre vidéo.';
          if (appName != null) {
            message =
                'Sélectionnez $appName dans la liste pour partager votre vidéo.';
          }
          widget.scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        log('[_shareVideoGeneric] Erreur de partage : Chemin vidéo invalide ou fichier inexistant. Chemin : $videoPath');
        if (mounted) {
          widget.scaffoldMessenger.showSnackBar(
            const SnackBar(
                content: Text(
                    'Impossible de partager la vidéo : fichier introuvable.')),
          );
        }
      }
    } catch (e, stackTrace) {
      
      if (mounted) {
        log('[_shareVideoGeneric] Erreur inattendue lors du partage générique : $e\nStackTrace: $stackTrace');
        
      }
    }
  }

//  Partage par E-mail - utilise url_launcher
  // Future<void> _shareVideoByEmail() async {
  //   try {
  //     final String videoPath = widget.videoUrl;
  //     final File videoFile = File(videoPath);
  //     if (videoPath.isNotEmpty && await videoFile.exists()) {
  //       final String videoTitle = widget.videoTitle != null && widget.videoTitle!.isNotEmpty
  //           ? widget.videoTitle!
  //           : 'Ma vidéo Caroussel';
  //       final String subject = Uri.encodeComponent('Ma nouvelle vidéo : "$videoTitle"');
  //       final String body = Uri.encodeComponent('Découvrez la vidéo que j\'ai créée avec Caroussel !');

  //       final Uri emailLaunchUri = Uri(
  //         scheme: 'mailto',
  //         path: '',
  //         query: 'subject=$subject&body=$body',
  //       );

  //       if (await canLaunchUrl(emailLaunchUri)) {
  //         await launchUrl(emailLaunchUri);
  //         log('[_shareVideoByEmail] Client e-mail lancé avec succès.');
  //         if (mounted) {
  //           widget.scaffoldMessenger.showSnackBar(
  //             const SnackBar(content: Text('Ouvrez votre application mail. Vous devrez peut-être ajouter la vidéo en pièce jointe.')),
  //           );
  //         }
  //       } else {
  //         log('[_shareVideoByEmail] Impossible de lancer le client e-mail.');
  //         if (mounted) {
  //           widget.scaffoldMessenger.showSnackBar(
  //             const SnackBar(content: Text('Impossible d\'ouvrir l\'application mail.')),
  //           );
  //         }
  //       }
  //     } else {
  //       log('[_shareVideoByEmail] Erreur de partage : Chemin vidéo invalide ou fichier inexistant. Chemin : $videoPath');
  //       if (mounted) {
  //         widget.scaffoldMessenger.showSnackBar(
  //           const SnackBar(content: Text('Impossible de partager la vidéo par mail : fichier introuvable.')),
  //         );
  //       }
  //     }
  //   } catch (e, stackTrace) {
  //     log('[_shareVideoByEmail] Erreur inattendue lors du partage par e-mail : $e\nStackTrace: $stackTrace');
  //     if (mounted) {
  //        Fluttertoast.showToast(
  //       msg: "Erreur lors du partage par e-mail : $e",
  //       toastLength: Toast.LENGTH_LONG,
  //       gravity: ToastGravity.BOTTOM,
  //       backgroundColor: Colors.red,
  //       textColor: Colors.white,
  //     );
  //     }
  //   }
  // }

  // Partage sur WhatsApp (direct) - utilise share_whatsapp_plus
  Future<void> _shareVideoOnWhatsApp() async {
    try {
      final path = widget.videoUrl;
      if (path.isEmpty || !await File(path).exists()) {
        _showError("Impossible de partager sur WhatsApp : fichier introuvable.");
        return;
      }

      final ok = await shareWhatsappPlus.shareFile(XFile(path));
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Ouverture de WhatsApp..."),
              duration: Duration(seconds: 4)),
        );
      } else {
        _shareVideoGeneric(appName: "WhatsApp");
      }
    } catch (e, st) {
      log("[_shareVideoOnWhatsApp] Erreur: $e\n$st");
      _showError("Erreur lors du partage WhatsApp : $e");
    //  _shareVideoGeneric(appName: "WhatsApp");
    }
  }

  // NOUVEAU : Partage sur Facebook - utilise social_sharing_plus
 Future<void> _shareVideoOnFacebook() async {
    try {
      final path = widget.videoUrl;
      if (path.isEmpty || !await File(path).exists()) {
        _showError("Impossible de partager sur Facebook : fichier introuvable.");
        return;
      }

      await SocialSharingPlus.shareToSocialMedia(
        SocialPlatform.facebook,
        "Découvrez cette vidéo créée avec Caroussel !",
        media: path,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Ouverture de Facebook. Ajoutez la vidéo si besoin dans l’éditeur."),
            duration: Duration(seconds: 5)),
      );
    } catch (e, st) {
      log("[_shareVideoOnFacebook] Erreur: $e\n$st");
      _showError("Erreur lors du partage Facebook : $e");
      //_shareVideoGeneric(appName: "Facebook");
    }
  }

  // NOUVEAU : Partage sur LinkedIn - utilise social_sharing_plus
  // Future<void> _shareVideoOnLinkedIn() async {
  //   try {
  //     final String videoPath = widget.videoUrl;
  //     final File videoFile = File(videoPath);
  //     if (videoPath.isNotEmpty && await videoFile.exists()) {
  //       // La méthode shareToSocialMedia de social_sharing_plus prend le chemin du fichier
  //       // pour 'media'.
  //       await SocialSharingPlus.shareToSocialMedia(
  //         SocialPlatform.linkedin,
  //         'Découvrez cette vidéo professionnelle créée avec Caroussel !', // Texte à partager
  //         media: videoPath, // Passez le chemin du fichier vidéo ici
  //       );

  //       log('[_shareVideoOnLinkedIn] Partage LinkedIn initié via social_sharing_plus pour : $videoPath');
  //       if (mounted) {
  //         widget.scaffoldMessenger.showSnackBar(
  //           const SnackBar(
  //             content: Text('Ouverture de LinkedIn. Vous devrez peut-être sélectionner la vidéo manuellement dans l\'éditeur de post.'),
  //             duration: Duration(seconds: 5),
  //           ),
  //         );
  //       }
  //     } else {
  //       log('[_shareVideoOnLinkedIn] Erreur de partage : Chemin vidéo invalide ou fichier inexistant. Chemin : $videoPath');
  //       if (mounted) {
  //         widget.scaffoldMessenger.showSnackBar(
  //           const SnackBar(content: Text('Impossible de partager sur LinkedIn : fichier introuvable.')),
  //         );
  //       }
  //     }
  //   } catch (e, stackTrace) {
  //     log('[_shareVideoOnLinkedIn] Erreur inattendue lors du partage LinkedIn : $e\nStackTrace: $stackTrace');
  //     if (mounted) {
  //       widget.scaffoldMessenger.showSnackBar(
  //         SnackBar(content: Text('Erreur lors du partage sur LinkedIn : $e')),
  //       );
  //     }
  //     _shareVideoGeneric(appName: 'LinkedIn'); // Fallback en cas d\'échec
  //   }
  // }

  // --- Modale de Choix de Partage Personnalisée ---
  void _showCustomShareOptionsModal() {
    showModalBottomSheet(
      context: context,
      isDismissible:
          true, // L'utilisateur peut cliquer à côté ou balayer pour fermer
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Où partager ?',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _shareVideoOnWhatsApp();
                },
                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 24),
                label: const Text('Partager sur WhatsApp'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),


              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _shareVideoOnFacebook();
                },
                icon: const FaIcon(FontAwesomeIcons.facebook, size: 24),
                label: const Text('Partager sur Facebook'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              //partage par e-mail
              const SizedBox(height: 10),
              // ElevatedButton.icon(
              //   onPressed: () {
              //     Navigator.pop(context);
              //     _shareVideoByEmail();
              //   },
              //   icon: const Icon(Icons.email),
              //   label: const Text('Partager par e-mail'),
              //   style: ElevatedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(vertical: 12),
              //     backgroundColor: Colors.orange,
              //     foregroundColor: Colors.white,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //   ),
              // ),


              // const SizedBox(height: 10),

              
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _shareVideoGeneric();
                },
               
                icon: const Icon(Icons.apps),
                label: const Text('Autres applications'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  // Calcul du padding vertical en fonction de la hauteur de l'écran
  final screenHeight = MediaQuery.of(context).size.height;
  // Utiliser un pourcentage de la hauteur, par exemple 5% de chaque côté
  final verticalPadding = screenHeight * 0.05;

  return AlertDialog(
    insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: verticalPadding),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    titlePadding: EdgeInsets.zero, // on gère le padding via la colonne
    title: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ligne pour le bouton de fermeture
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.close, size: 24, color: Colors.black54),
              tooltip: 'Fermer',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      
        // Titre centré
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Aperçu de votre vidéo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.videoTitle != null && widget.videoTitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    widget.videoTitle!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
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
    actionsAlignment: MainAxisAlignment.center,
    actions: [
      Wrap(
        spacing: 10,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => _exportVideo(context, widget.videoUrl),
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showCustomShareOptionsModal,
            icon: const Icon(Icons.share_rounded),
            label: const Text('Partager'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}



}
