import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'carousel_provider.dart';
import 'dart:developer';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MediaUploader extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final void Function(List<String> imagePath) imageContainerCallback;
  final void Function(int) selectValueCallback;
  final void Function(int) autoScrollValueCallback;
  // `imagePath` n'est plus utilisé ici car les images sont gérées par le Provider
  // final List<String> imagePath; // <-- Peut être supprimé du constructeur

  const MediaUploader({
    super.key,
    required this.imageContainerCallback,
    required this.selectValueCallback,
    required this.autoScrollValueCallback,
    required this.scaffoldKey,
    // this.imagePath = const [], // <-- Supprimer si non utilisé
  });

  @override
  State<MediaUploader> createState() => _MediaUploaderState();
}

// --- Fonctions utilitaires (getAudioDuration, test, prepareAudioFileForFFmpeg, convertImagesToVideo) ---
// Ces fonctions ne sont pas directement liées au bug actuel du bouton, je ne les modifierai pas ici.
// Assurez-vous qu'elles fonctionnent correctement par ailleurs.

Future<double> getAudioDuration(String audioPath) async {
  final session = await FFmpegKit.execute('-i "$audioPath" -hide_banner');
  final logs = await session.getAllLogsAsString();

  final regex = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})');
  final match = regex.firstMatch(logs!);

  if (match != null) {
    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    final seconds = int.parse(match.group(3)!);
    final centiseconds = int.parse(match.group(4)!);
    final duration = hours * 3600 + minutes * 60 + seconds + centiseconds / 100;
    log('⏱️ Durée audio : $duration secondes');
    return duration;
  } else {
    log('⚠️ Impossible de récupérer la durée audio');
    return 0;
  }
}

Future<String?> test() async {
  log('hello world');
  await Future.delayed(Duration(seconds: 1));
  return "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4";
}

Future<String?> prepareAudioFileForFFmpeg({
  required String audioUrl,
  required String fileName,
}) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(audioUrl));
    final response = await request.close();

    if (response.statusCode == HttpStatus.ok) {
      final appTempDir = await getTemporaryDirectory();
      final filePath = '${appTempDir.path}/$fileName';
      final file = File(filePath);
      await response.pipe(file.openWrite());
      log('✅ Audio téléchargé avec succès vers: $filePath');
      return filePath;
    } else {
      log('❌ Échec du téléchargement de l\'audio: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    log('❌ Erreur lors du téléchargement de l\'audio: $e');
    return null;
  }
}

Future<String> convertImagesToVideo(
  List<String> images, {
  String? audioSource,
  String? videoTitle,
}) async {
  log('📥 Début de la fonction convertImagesToVideo');
  if (images.length < 2) {
    log('❌ Il faut au moins deux images pour créer une vidéo.');
    return "";
  }

  final tempDir = await getTemporaryDirectory();
  log('📁 Dossier temporaire créé : ${tempDir.path}');

  // --- Étape 1 : Compression et préparation des images ---
  for (int i = 0; i < images.length; i++) {
    final sourcePath = images[i];
    final destPath = '${tempDir.path}/image${i + 1}.jpg';
    log('📸 Compression de l’image $i : $sourcePath → $destPath');

    final compressed = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      destPath,
      quality: 85,
      minWidth: 1080,
      minHeight: 1080,
    );

    if (compressed == null) {
      log('❌ Échec de compression pour $sourcePath');
      return "";
    } else {
      log('✅ Image compressée : ${compressed.path}');
    }
  }

  final outputDir = Directory('/storage/emulated/0/Movies');
  final outputVideoPath = '${outputDir.path}/$videoTitle.mp4';
  log('📽️ Chemin de sortie vidéo : $outputVideoPath');

  // --- Vérification et préparation de la source audio ---
  String? finalAudioFilePath;
  double audioDuration = 0.0;

  if (audioSource != null && audioSource.isNotEmpty) {
    if (audioSource.startsWith('http://') || audioSource.startsWith('https://')) {
      log('🎧 Source audio est une URL: $audioSource. Tentative de téléchargement.');
      finalAudioFilePath = await prepareAudioFileForFFmpeg(
        audioUrl: audioSource,
        fileName: 'downloaded_audio_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
      if (finalAudioFilePath == null) {
        log('❌ Échec du téléchargement de l\'audio depuis l\'URL fournie. La vidéo sera sans audio.');
      }
    } else {
      final File localFile = File(audioSource);
      if (await localFile.exists()) {
        log('🎧 Source audio est un chemin local existant: $audioSource');
        finalAudioFilePath = audioSource;
      } else {
        log('❌ Fichier audio local non trouvé à: $audioSource. La vidéo sera sans audio.');
      }
    }

    if (finalAudioFilePath != null) {
      audioDuration = await getAudioDuration(finalAudioFilePath);
      if (audioDuration == 0.0) {
        log('❌ Impossible d\'obtenir la durée de l\'audio. La vidéo sera sans audio ou utilisera une durée d\'image par default.');
      }
    }
  } else {
    log('⚠️ Aucun chemin audio ou URL audio fourni. La vidéo n\'aura pas de son.');
  }

  final videoNoAudioPath = '${tempDir.path}/{$videoTitle}video_no_audio.mp4';

  double durationPerImage = 5.0;
  double finalVideoDuration = 0.0;

  if (audioDuration > 0 && images.isNotEmpty) {
    durationPerImage = audioDuration / images.length;
    finalVideoDuration = audioDuration;
    log('⏳ Durée par image calculée : $durationPerImage secondes.');
  } else {
    log('⏳ Utilisation de la durée par défaut de 5 secondes par image.');
    finalVideoDuration = durationPerImage * images.length;
  }
  log('🎥 Durée totale de la vidéo finale prévue : $finalVideoDuration secondes');

  String imageInputStrings = "";
  for(int i = 0; i < images.length; i++) {
    imageInputStrings += '-i "${tempDir.path}/image${i + 1}.jpg" ';
  }

  String filterComplex = "";
  String concatInputs = "";
  for (int i = 0; i < images.length; i++) {
    filterComplex += '[$i:v]scale=720:720:force_original_aspect_ratio=increase,crop=720:720,setsar=1,tpad=stop_mode=clone:stop_duration=$durationPerImage[v$i];';
    concatInputs += '[v$i]';
  }
  filterComplex += '${concatInputs}concat=n=${images.length}:v=1:a=0[outv]';

  String commandVideoOnly = '-y $imageInputStrings -filter_complex "$filterComplex" '
      '-map "[outv]" -c:v libx264 -pix_fmt yuv420p -loglevel debug "$videoNoAudioPath"';

  log('🛠️ Commande FFmpeg pour vidéo seule : $commandVideoOnly');
  var session = await FFmpegKit.execute(commandVideoOnly);
  var returnCode = await session.getReturnCode();
  var logs = await session.getLogsAsString();
  log('📜 Logs création vidéo seule:\n$logs');

  if (!ReturnCode.isSuccess(returnCode)) {
    log('❌ Erreur lors de la création de la vidéo sans audio. Code de retour: ${returnCode?.getValue()}');
    return "";
  }
  log('✅ Vidéo sans audio créée avec succès.');

  if (finalAudioFilePath != null && finalAudioFilePath.isNotEmpty) {
    const double fadeOutDuration = 3.0;
    final double fadeOutStartTime = finalVideoDuration - fadeOutDuration;
    final double safeFadeOutStartTime = fadeOutStartTime > 0 ? fadeOutStartTime : 0.0;

    String probeCommand = '-i "$finalAudioFilePath" -hide_banner';
    log('🛠️ Commande FFprobe pour infos audio : $probeCommand');
    var probeSession = await FFmpegKit.execute(probeCommand);
    var probeLogs = await probeSession.getLogsAsString();
    log('📜 Logs FFprobe audio:\n$probeLogs');

    String commandWithAudio = '-y -i "$videoNoAudioPath" -i "$finalAudioFilePath" '
    '-filter_complex "' '[0:v]fade=t=out:st=$safeFadeOutStartTime:d=$fadeOutDuration[v_faded]; ' '[1:a]afade=t=out:st=$safeFadeOutStartTime:d=$fadeOutDuration[a_faded]" ' '-map "[v_faded]" -map "[a_faded]" ' '-c:v libx264 -preset veryfast -crf 26 -c:a aac -strict experimental ' '"$outputVideoPath"';

    log('🛠️ Commande FFmpeg pour ajout audio et fade out : $commandWithAudio');
    session = await FFmpegKit.execute(commandWithAudio);
    returnCode = await session.getReturnCode();
    logs = await session.getLogsAsString();
    log('📜 Logs ajout audio et fade out:\n$logs');

    if (!ReturnCode.isSuccess(returnCode)) {
      log('❌ Erreur lors de l’ajout de l’audio et du fade out. Code de retour: ${returnCode?.getValue()}');
      return "";
    }
    log('✅ Vidéo finale avec audio et fade out créée avec succès à : $outputVideoPath');
    return outputVideoPath;
  } else {
    log('⚠️ Pas d’audio préparé, on renvoie la vidéo sans audio. Aucun fade out appliqué.');
    return videoNoAudioPath;
  }
}

class _MediaUploaderState extends State<MediaUploader> {
  String? _selectedFile;
  final _formKey = GlobalKey<FormState>();
  int? selectValue;
  int? autoScrollValue;

  // Cette liste n'est plus la source de vérité.
  // Elle peut être supprimée si elle n'est pas utilisée pour d'autres logiques internes.
  // List<String> selectedImages = [];

  Future<void> testWritePermission() async {
    final testFile = File('/storage/emulated/0/Download/test_permission.txt');
    try {
      await testFile.writeAsString('Test permission write');
      print('✅ Écriture OK');
    } catch (e) {
      print('❌ Écriture échouée : $e');
    }
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        List<String> newSelectedImages = result.files.map((file) => file.path!).toList();

        final carouselProvider = context.read<CarouselProvider>();
        List<String> currentProviderImages = List.from(carouselProvider.images);
        currentProviderImages.addAll(newSelectedImages);
        carouselProvider.setImages(currentProviderImages);

        log('Images combinées pour le Provider: ${carouselProvider.images}');
        log('Nombre d\'images dans le Provider: ${carouselProvider.images.length}');

        String? fileName = result.files.single.name;
        log(fileName);

        String extension = fileName.substring(fileName.lastIndexOf('.'));

        if (fileName.length > 20) {
          fileName = '${fileName.substring(0, 10)} ...$extension';
        }

        setState(() {
          _selectedFile = 'fichier sélectionné: $fileName';
          // Pas besoin de mettre à jour la liste selectedImages locale si elle n'est pas utilisée.
          // selectedImages.addAll(newSelectedImages);
        });

        // Appeler le callback avec la liste d'images du Provider
        widget.imageContainerCallback(carouselProvider.images);
        log('Callback called with: ${carouselProvider.images}');

      } else {
        setState(() {
          _selectedFile = 'Aucun fichier sélectionné.';
        });
      }
    } catch (e) {
      log("Erreur lors de la sélection du fichier : $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection du fichier: $e')),
        );
      }
      setState(() {
        _selectedFile = 'Erreur lors de la sélection du fichier.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter le CarouselProvider pour obtenir le nombre d'images.
    final carouselProvider = context.watch<CarouselProvider>();
    final int imageCount = carouselProvider.imageCount;

    // La variable `selectedImages` locale du State n'est plus nécessaire pour ces conditions.
    // Nous utilisons `imageCount` du Provider.
    bool isButtonEnabled = _selectedFile != null &&
        autoScrollValue != null &&
        imageCount >= 2; // Condition basée sur le Provider

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.looks_one, color: Colors.green),
              const Text(
                'Choisir un Fichier',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Tooltip(
            message: 'Cliquez pour choisir un fichier',
            preferBelow: true,
            margin: const EdgeInsets.all(8),
            textStyle: const TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 194, 199, 204),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: pickFile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
              ),
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                'Choisir un fichier'.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const Text('Formats supportés : JPG, PNG',
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 20),
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.looks_two, color: Colors.green),
                  const Text(
                    'Défilement Automatique',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(width: 30),
              // Mise à jour de l'icône pour dépendre du Provider
              Icon(
                autoScrollValue == 1 && imageCount >= 2
                    ? Icons.check_circle
                    : autoScrollValue == 2 && imageCount >= 2
                        ? Icons.cancel
                        : Icons.circle, // Ou Icons.radio_button_unchecked pour une icône neutre
                color: autoScrollValue == 1 && imageCount >= 2
                    ? Colors.green
                    : autoScrollValue == 2 && imageCount >= 2
                        ? Colors.red
                        : Colors.transparent, // Ou Colors.grey pour une icône neutre visible
              ),
            ],
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<int>(
            dropdownColor: Colors.white,
            hint: Text(
              'Défilement automatique ?',
              // Mise à jour de la condition pour le hint et la couleur du texte
              style: _selectedFile == null || imageCount < 2
                  ? const TextStyle(color: Colors.grey)
                  : const TextStyle(color: Colors.black),
            ),
            decoration: const InputDecoration(
              labelText: 'Défilement automatique Oui/Non',
              border: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(13, 71, 161, 1))),
            ),
            value: autoScrollValue,
            items: [
              DropdownMenuItem(
                value: 1,
                // Le texte devrait aussi dépendre de imageCount
                child: Text(imageCount < 2 ? 'Défilement automatique ?' : 'Oui'),
              ),
              DropdownMenuItem(
                value: 2,
                // Le texte devrait aussi dépendre de imageCount
                child: Text(imageCount < 2 ? 'Défilement automatique ?' : 'Non'),
              ),
            ],
            // Mise à jour de la condition pour onPressed du Dropdown
            onChanged: _selectedFile == null || imageCount < 2
                ? null
                : (value) {
                    setState(() {
                      autoScrollValue = value;
                      widget.autoScrollValueCallback(value!);
                    });
                  },
          ),
          const SizedBox(height: 20),
          Tooltip(
            message: _selectedFile != null && autoScrollValue != null && imageCount >= 2
                ? 'Cliquez pour valider'
                : 'Veuillez sélectionner au moins deux fichiers et une option de défilement',
            preferBelow: true,
            margin: const EdgeInsets.all(13),
            textStyle: const TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: isButtonEnabled ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: isButtonEnabled ? Colors.green : Colors.grey,
              ),
              onPressed: isButtonEnabled
                  ? () async {
                      // Convertir les images sélectionnées en vidéo
                      // Utilisez carouselProvider.images pour la conversion
                      await convertImagesToVideo(carouselProvider.images);
                      // testWritePermission(); // Décommenter si nécessaire
                      // test(); // Décommenter si nécessaire

                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (widget.scaffoldKey.currentState != null &&
                            _selectedFile != null &&
                            autoScrollValue != null) {
                          widget.scaffoldKey.currentState!.openEndDrawer();
                        }
                      });
                    }
                  : null,
              child: Text(
                'Valider',
                style: isButtonEnabled
                    ? const TextStyle(color: Colors.white)
                    : TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}