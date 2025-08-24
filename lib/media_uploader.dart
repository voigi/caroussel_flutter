import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'carousel_provider.dart'; // Assurez-vous du chemin correct
import 'dart:developer';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'drawer_settings_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MediaUploader extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final void Function(List<String> imagePath) imageContainerCallback;
  final void Function(int)
      selectValueCallback; // Garder si vous en avez toujours besoin pour autre chose
  // Supprimez autoScrollValueCallback car le provider gère l'état directement
  // final void Function(int) autoScrollValueCallback; // <-- SUPPRIMER
  final void Function() onValidation;

  const MediaUploader({
    super.key,
    required this.imageContainerCallback,
    required this.selectValueCallback,
    // required this.autoScrollValueCallback, // <-- SUPPRIMER
    required this.scaffoldKey,
    required this.onValidation,
  });

  @override
  State<MediaUploader> createState() => _MediaUploaderState();
}

// --- Fonctions utilitaires (non modifiées, placez-les ici si elles sont dans le même fichier) ---
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

Future<void> archiveNewVideos(List<File> newVideos) async {
  final moviesDir = Directory('/storage/emulated/0/Movies');
  final archivesDir = Directory('${moviesDir.path}/Archives');
  if (!await archivesDir.exists()) {
    await archivesDir.create(recursive: true);
    print('📁 Dossier Archives créé.');
  }
  for (final file in newVideos) {
    final fileName = file.uri.pathSegments.last;
    final newPath = '${archivesDir.path}/$fileName';
    try {
      await file.copy(newPath);
      print('✅ Copie dans Archives : $fileName');
    } catch (e) {
      print('⚠️ Erreur lors de la copie de $fileName : $e');
    }
  }
}

Future<String> getUniqueVideoPath(
    String baseTitle, String extension, Directory directory) async {
  String candidateTitle = baseTitle;

  int counter = 1;

  while (true) {
    final candidatePath = '${directory.path}/$candidateTitle$extension';

    final file = File(candidatePath);

    if (!(await file.exists())) {
      return candidatePath;
    }

    candidateTitle = '$baseTitle($counter)';

    counter++;
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
  log('📥 Début de convertImagesToVideo');

  if (images.length < 2) {
    log('❌ Il faut au moins deux images.');
    return "";
  }

  final tempDir = await getTemporaryDirectory();
  log('📁 Dossier temporaire : ${tempDir.path}');

  // --- Compression des images ---
  for (int i = 0; i < images.length; i++) {
    final destPath = '${tempDir.path}/image${i + 1}.jpg';
    final compressed = await FlutterImageCompress.compressAndGetFile(
      images[i],
      destPath,
      quality: 85,
      minWidth: 1080,
      minHeight: 1080,
    );
    if (compressed == null) {
      log('❌ Échec compression ${images[i]}');
      return "";
    }
    log('✅ Image compressée : $destPath');
  }

  // --- Préparation dossiers ---
  final outputDir = await getApplicationDocumentsDirectory();
  log('📁 Vidéo sera enregistrée dans le stockage interne : ${outputDir.path}');
  final videoNoSoundDir = Directory('/storage/emulated/0/Movies/NoAudio');
  if (!await outputDir.exists()) await outputDir.create(recursive: true);
  if (!await videoNoSoundDir.exists())
    await videoNoSoundDir.create(recursive: true);

  final bool hasAudio = (audioSource != null && audioSource.isNotEmpty);
  final String outputVideoPath = await getUniqueVideoPath(
    videoTitle ?? 'video',
    '.mp4',
    hasAudio ? outputDir : videoNoSoundDir,
  );
  log('📽️ Chemin de sortie : $outputVideoPath');

  // --- Préparation audio ---
  String? finalAudioFilePath;
  double audioDuration = 0.0;
  if (hasAudio) {
    if (audioSource.startsWith('http://') ||
        audioSource.startsWith('https://')) {
      finalAudioFilePath = await prepareAudioFileForFFmpeg(
        audioUrl: audioSource,
        fileName:
            'downloaded_audio_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
    } else {
      final File f = File(audioSource);
      if (await f.exists()) finalAudioFilePath = audioSource;
    }
    if (finalAudioFilePath != null) {
      audioDuration = await getAudioDuration(finalAudioFilePath);
    }
  }

  // --- Durée par image ---
  double durationPerImage =
      audioDuration > 0 ? audioDuration / images.length : 5.0;
  final double finalVideoDuration = durationPerImage * images.length;
  const double fadeDuration = 3.0;
  final double fadeStart = finalVideoDuration - fadeDuration;

  // --- Construction FFmpeg ---
  String imageInputStrings = '';
  String filterComplex = '';
  String concatInputs = '';

  for (int i = 0; i < images.length; i++) {
    imageInputStrings +=
        '-loop 1 -t $durationPerImage -i "${tempDir.path}/image${i + 1}.jpg" ';
    filterComplex +=
        '[$i:v]scale=720:720:force_original_aspect_ratio=increase,crop=720:720,setsar=1[v$i];';
    concatInputs += '[v$i]';
  }

  filterComplex +=
      '${concatInputs}concat=n=${images.length}:v=1:a=0[outv];[outv]fade=t=out:st=$fadeStart:d=$fadeDuration[outv_faded]';

  String commandVideoOnly =
      '-y $imageInputStrings -filter_complex "$filterComplex" -map "[outv_faded]" -c:v libx264 -pix_fmt yuv420p -loglevel debug "$outputVideoPath"';

  log('🛠️ Commande FFmpeg vidéo seule : $commandVideoOnly');
  var session = await FFmpegKit.execute(commandVideoOnly);
  var returnCode = await session.getReturnCode();
  var logs = await session.getLogsAsString();
  log('📜 Logs vidéo seule:\n$logs');

  if (!ReturnCode.isSuccess(returnCode)) {
    log('❌ Erreur création vidéo sans audio : ${returnCode?.getValue()}');
    return "";
  }

  log('✅ Vidéo sans audio créée avec succès');

  // --- Ajout audio si présent ---
  if (finalAudioFilePath != null) {
    final double safeFadeStart = fadeStart > 0 ? fadeStart : 0.0;
    final tempWithAudio = '${tempDir.path}/video_audio.mp4';

    String commandWithAudio =
        '-y -i "$outputVideoPath" -i "$finalAudioFilePath" '
        '-filter_complex "[1:a]afade=t=out:st=$safeFadeStart:d=$fadeDuration[a_faded]" '
        '-map 0:v -map "[a_faded]" -c:v copy -c:a aac "$tempWithAudio"';

    log('🛠️ Commande FFmpeg ajout audio : $commandWithAudio');
    await FFmpegKit.execute(commandWithAudio);
    if (outputVideoPath.isNotEmpty)
      await File(tempWithAudio).copy(outputVideoPath);
    // ta fonction qui déplace les anciennes vidéos dans Archives }
    await archiveNewVideos([File(outputVideoPath)]);
  }

  return outputVideoPath;
}

Future<void> testImageToVideo(String imagePath, String outputPath) async {
  debugPrint("🚀 Test FFmpeg image->vidéo lancé");

  // Commande FFmpeg minimale : une image répétée 5 sec -> MP4
  final String command = '''
    -loop 1 -t 5 -i $imagePath 
    -c:v libx264 -pix_fmt yuv420p -y $outputPath
  ''';

  try {
    final session = await FFmpegKit.execute(command);

    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      debugPrint("✅ Vidéo générée avec succès → $outputPath");
    } else {
      final logs = await session.getAllLogsAsString();
      debugPrint("❌ Erreur FFmpeg : $logs");
    }
  } catch (e) {
    debugPrint("⚠️ Exception FFmpeg : $e");
  }
}

class _MediaUploaderState extends State<MediaUploader> {
  final _formKey = GlobalKey<FormState>();
  // int? selectValue; // Plus besoin d'état local pour ça, le provider gère

  @override
  void initState() {
    super.initState();
    // Il est bon de s'assurer que le carouselProvider.autoScrollValue a une valeur par défaut
    // s'il n'est pas encore défini (par exemple, au premier démarrage de l'app).
    // Si votre CarouselProvider initialise _autoScrollValue à 0, ce n'est pas strictement nécessaire ici.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final carouselProvider = Provider.of<CarouselProvider>(context, listen: false);
    //   // if (carouselProvider.autoScrollValue == null) {
    //   //   carouselProvider.updateAutoScrollValue(0); // Définit sur Désactivé par défaut
    //   // }
    // });

    // je veux savoir combien de vidéos il y a dans Movies au démarrage meme si l'app a ete desinstallé
  }

  Future<void> pickFileimages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        // allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      final carouselProvider = context.read<CarouselProvider>();

      if (result != null) {
        List<String> newSelectedImages =
            result.files.map((file) => file.path!).toList();

        List<String> currentProviderImages = List.from(carouselProvider.images);
        currentProviderImages.addAll(newSelectedImages);
        carouselProvider.setImages(currentProviderImages);

        String? fileName = result.files.single.name;
        String extension = fileName.substring(fileName.lastIndexOf('.'));

        if (fileName.length > 20) {
          fileName = '${fileName.substring(0, 10)} ...$extension';
        }

        carouselProvider.setSelectedFileLabel('fichier sélectionné: $fileName');
        widget.imageContainerCallback(carouselProvider
            .images); // Maintenez ce callback si un parent en a besoin
      } else {
        carouselProvider.setSelectedFileLabel('Aucun fichier sélectionné.');
      }
    } catch (e) {
      log("Erreur lors de la sélection du fichier : $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection du fichier: $e')),
        );
      }
      final carouselProvider = context.read<CarouselProvider>();
      carouselProvider
          .setSelectedFileLabel('Erreur lors de la sélection du fichier.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écoutez les changements dans CarouselProvider pour que le UI se mette à jour
    final carouselProvider = context.watch<CarouselProvider>();
    final selectFileLabel = carouselProvider.selectedFileLabel;
    final autoScrollValue = carouselProvider
        .autoScrollValue; // Lisez directement depuis le provider
    final int imageCount = carouselProvider.imageCount;

    bool isButtonEnabled =
        selectFileLabel != null && autoScrollValue != null && imageCount >= 2;

    bool canSelectScroll = imageCount >= 2;

    log('autoScrollValue: $autoScrollValue, imageCount: $imageCount, _selectedFile: $selectFileLabel, isButtonEnabled: $isButtonEnabled, canSelectScroll: $canSelectScroll');

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.looks_one, color: Colors.green),
              const Text(
                'Choisir un Média',
                style: TextStyle(
                    fontSize: 15.21,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Tooltip(
            message: 'Cliquez pour choisir des images (JPG, PNG)',
            preferBelow: true,
            margin: const EdgeInsets.all(8),
            textStyle: const TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 194, 199, 204),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: pickFileimages,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
              ),
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                'Choisir des fichiers'.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.looks_two, color: Colors.green),
              const Text(
                'Défilement Automatique',
                style: TextStyle(
                    fontSize: 15.21,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 5),
          if (canSelectScroll)
            DropdownButtonFormField<int?>(
              // La valeur est lue directement depuis le provider.
              // Utilisez null ou une valeur par défaut cohérente (0)
              // si `autoScrollValue` peut être null au démarrage.
              value: carouselProvider.autoScrollValue ?? null,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Désactivé')),
                DropdownMenuItem(value: 1, child: Text('Activé')),
              ],
              onChanged: (int? value) {
                // Mettez à jour le provider directement.
                // Le `context.read` est utilisé ici car nous ne voulons pas
                // que ce widget se reconstruise si la valeur change, seulement la modifier.
                context.read<CarouselProvider>().updateAutoScrollValue(value);
                // Supprimez le callback, il n'est plus nécessaire car le provider est la source de vérité.
                // widget.autoScrollValueCallback(value !); // <-- SUPPRIMER
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Défilement Automatique',
                hintText: ' Sélectionnez une option',
                // helperText: 'Les images défileront automatiquement.',
              ),
            )
          else
            const Text(
              'Au moins 2 images sont nécessaires pour activer le défilement automatique.',
              style: TextStyle(color: Colors.red),
            ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: isButtonEnabled ? Colors.green : Colors.grey,
            ),
            onPressed: isButtonEnabled
                ? () async {
                    widget.onValidation();
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (widget.scaffoldKey.currentState != null) {
                        //on reset l'état du drawer via le provider
                        final drawerProvider =
                            Provider.of<DrawerSettingsProvider>(context, listen: false);
                        drawerProvider.resetAllDrawerOptions();

                        widget.scaffoldKey.currentState!.openEndDrawer();
                      }
                    });
                  }
                : null,
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            label: Text(
              'Continuer'.toUpperCase(),
              style: isButtonEnabled
                  ? const TextStyle(color: Colors.white)
                  : TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
