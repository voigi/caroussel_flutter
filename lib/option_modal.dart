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

// La fonction qui affiche la modale principale (VideoPlayerModal)
Future<void> optionModal(BuildContext context, String videoUrl, {String? videoTitle}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return VideoPlayerModal(videoUrl: videoUrl, videoTitle: videoTitle);
    },
  );
}

// Le widget de la modale du lecteur vidéo
class VideoPlayerModal extends StatefulWidget {
  final String videoUrl;
  final String? videoTitle;

  const VideoPlayerModal({required this.videoUrl, this.videoTitle, super.key});

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
    _initializeVideoPlayerFuture = _videoPlayerController.initialize().then((_) {
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
    log('[dispose] VideoPlayerModal disposed.');
    super.dispose();
  }

  // --- Fonctions de Partage Spécifiques ---

  // Partage générique (pour "Autres applications") - utilise share_plus
  Future<void> _shareVideoGeneric({String? appName}) async {
    try {
      final String videoPath = widget.videoUrl;
      final File videoFile = File(videoPath);
      if (videoPath.isNotEmpty && await videoFile.exists()) {
        await Share.shareXFiles(
          [XFile(videoPath)],
          text: 'Découvrez ma nouvelle vidéo !',
          subject: widget.videoTitle != null && widget.videoTitle!.isNotEmpty
              ? 'Vidéo "${widget.videoTitle!}" créée avec Caroussel !'
              : 'Ma vidéo créée avec Caroussel !',
        );
        log('[_shareVideoGeneric] Partage vidéo initié avec succès pour : $videoPath');
         if (mounted) {
            String message = 'Choisissez l\'application pour partager votre vidéo.';
            if (appName != null) {
              message = 'Sélectionnez $appName dans la liste pour partager votre vidéo.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 3),
              ),
            );
          }
      } else {
        log('[_shareVideoGeneric] Erreur de partage : Chemin vidéo invalide ou fichier inexistant. Chemin : $videoPath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de partager la vidéo : fichier introuvable.')),
          );
        }
      }
    } catch (e, stackTrace) {
      log('[_shareVideoGeneric] Erreur inattendue lors du partage générique : $e\nStackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Une erreur est survenue lors du partage : $e')),
        );
      }
    }
  }

  // Partage par E-mail - utilise url_launcher
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
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Ouvrez votre application mail. Vous devrez peut-être ajouter la vidéo en pièce jointe.')),
  //           );
  //         }
  //       } else {
  //         log('[_shareVideoByEmail] Impossible de lancer le client e-mail.');
  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Impossible d\'ouvrir l\'application mail.')),
  //           );
  //         }
  //       }
  //     } else {
  //       log('[_shareVideoByEmail] Erreur de partage : Chemin vidéo invalide ou fichier inexistant. Chemin : $videoPath');
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Impossible de partager la vidéo par mail : fichier introuvable.')),
  //         );
  //       }
  //     }
  //   } catch (e, stackTrace) {
  //     log('[_shareVideoByEmail] Erreur inattendue lors du partage par e-mail : $e\nStackTrace: $stackTrace');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Une erreur est survenue lors du partage par mail : $e')),
  //       );
  //     }
  //   }
  // }

  // Partage sur WhatsApp (direct) - utilise share_whatsapp_plus
  Future<void> _shareVideoOnWhatsApp() async {
    try {
      final String videoPath = widget.videoUrl;
      final File videoFile = File(videoPath);
      if (videoPath.isNotEmpty && await videoFile.exists()) {
        final bool success = await  shareWhatsappPlus.shareFile(
          XFile(videoPath), // Paramètre positionnel de type XFile
        );

        if (success) {
          log('[_shareVideoOnWhatsApp] Partage WhatsApp initié avec succès via share_whatsapp_plus pour : $videoPath');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ouverture de WhatsApp. Sélectionnez un contact ou un groupe.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        } else {
          log('[_shareVideoOnWhatsApp] share_whatsapp_plus a échoué, retour au partage générique share_plus.');
          _shareVideoGeneric(appName: 'WhatsApp');
        }
      } else {
        log('[_shareVideoOnWhatsApp] Erreur de partage : Chemin vidéo invalide ou fichier inexistant. Chemin : $videoPath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de partager sur WhatsApp : fichier introuvable.')),
          );
        }
      }
    } catch (e, stackTrace) {
      log('[_shareVideoOnWhatsApp] Erreur inattendue lors du partage WhatsApp : $e\nStackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage sur WhatsApp : $e')),
        );
      }
      _shareVideoGeneric(appName: 'WhatsApp');
    }
  }

  // NOUVEAU : Partage sur Facebook - utilise social_sharing_plus
  Future<void> _shareVideoOnFacebook() async {
    try {
      final String videoPath = widget.videoUrl;
      final File videoFile = File(videoPath);
      if (videoPath.isNotEmpty && await videoFile.exists()) {
        // La méthode shareToSocialMedia de social_sharing_plus prend le chemin du fichier
        // pour 'media'. 'isOpenBrowser' est rarement utile pour le partage de fichiers
        // directement dans l'application. On retire la gestion du booléen de succès direct,
        // car social_sharing_plus renvoie void ou lance une erreur.
        await SocialSharingPlus.shareToSocialMedia(
          SocialPlatform.facebook,
          'Découvrez cette vidéo créée avec Caroussel !', // Texte à partager
          media: videoPath, // Passez le chemin du fichier vidéo ici
        );

        log('[_shareVideoOnFacebook] Partage Facebook initié via social_sharing_plus pour : $videoPath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ouverture de Facebook. Vous devrez peut-être sélectionner la vidéo manuellement dans l\'éditeur de post.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        log('[_shareVideoOnFacebook] Erreur de partage : Chemin vidéo invalide ou fichier inexistant. Chemin : $videoPath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de partager sur Facebook : fichier introuvable.')),
          );
        }
      }
    } catch (e, stackTrace) {
      log('[_shareVideoOnFacebook] Erreur inattendue lors du partage Facebook : $e\nStackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage sur Facebook : $e')),
        );
      }
      _shareVideoGeneric(appName: 'Facebook'); // Fallback en cas d'échec
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
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Ouverture de LinkedIn. Vous devrez peut-être sélectionner la vidéo manuellement dans l\'éditeur de post.'),
  //             duration: Duration(seconds: 5),
  //           ),
  //         );
  //       }
  //     } else {
  //       log('[_shareVideoOnLinkedIn] Erreur de partage : Chemin vidéo invalide ou fichier inexistant. Chemin : $videoPath');
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Impossible de partager sur LinkedIn : fichier introuvable.')),
  //         );
  //       }
  //     }
  //   } catch (e, stackTrace) {
  //     log('[_shareVideoOnLinkedIn] Erreur inattendue lors du partage LinkedIn : $e\nStackTrace: $stackTrace');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Erreur lors du partage sur LinkedIn : $e')),
  //       );
  //     }
  //     _shareVideoGeneric(appName: 'LinkedIn'); // Fallback en cas d'échec
  //   }
  // }


  // --- Modale de Choix de Partage Personnalisée ---
  void _showCustomShareOptionsModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      //enableDrag: false,
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
                'Comment voulez-vous partager votre vidéo ?',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Bouton "Partager sur WhatsApp"
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
              // NOUVEAU Bouton "Partager sur Facebook"
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _shareVideoOnFacebook(); // Appelle la nouvelle fonction Facebook
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
            
              // NOUVEAU Bouton "Partager sur LinkedIn"
              // ElevatedButton.icon(
              //   onPressed: () {
              //     Navigator.pop(context);
              //     _shareVideoOnLinkedIn(); // Appelle la nouvelle fonction LinkedIn
              //   },
              //   icon: const FaIcon(FontAwesomeIcons.linkedin, size: 24),
              //   label: const Text('Partager sur LinkedIn'),
              //   style: ElevatedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(vertical: 12),
              //     backgroundColor: const Color(0xFF0A66C2),
              //     foregroundColor: Colors.white,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 10),
              // // Bouton "Envoyer par E-mail"
              // ElevatedButton.icon(
              //   onPressed: () {
              //     Navigator.pop(context);
              //     _shareVideoByEmail();
              //   },
              //   icon: const Icon(Icons.email),
              //   label: const Text('Envoyer par E-mail'),
              //   style: ElevatedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(vertical: 12),
              //     backgroundColor: Colors.blueAccent,
              //     foregroundColor: Colors.white,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 10),
              // Bouton "Autres applications"
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _shareVideoGeneric();
                },
                icon: const Icon(Icons.apps),
                label: const Text('Partager (E-mail, LinkedIn, etc.)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Column(
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
              padding: const EdgeInsets.only(top: 4.0),
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
            log('Prévisualisation annulée');
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
            _showCustomShareOptionsModal();
          },
          child: const Text('Partager'),
        ),
      ],
    );
  }
}