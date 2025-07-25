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
  final void Function() onValidation;

  const MediaUploader({
    super.key,
    required this.imageContainerCallback,
    required this.selectValueCallback,
    required this.autoScrollValueCallback,
    required this.scaffoldKey,
    required this.onValidation,
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

Future<void> manageVideoFiles() async {
  final moviesDir = Directory('/storage/emulated/0/Movies');

  if (!await moviesDir.exists()) {
    print('❌ Le dossier Movies n\'existe pas.');
    return;
  }

  // Créer le dossier Archives s'il n'existe pas
  final archivesDir = Directory('${moviesDir.path}/Archives');
  if (!await archivesDir.exists()) {
    await archivesDir.create(recursive: true);
    print('📁 Dossier Archives créé.');
  }

  // Filtrer les fichiers vidéo (pas les dossiers, et pas déjà dans Archives)
  final videoFiles = moviesDir.listSync().whereType<File>().where((file) {
    final path = file.path.toLowerCase();
    return (path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi')) &&
           !path.contains('/Archives/');
  }).toList();

  // Trier par date de modification (plus récentes d'abord)
  videoFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

  // Garder les 5 plus récentes
  if (videoFiles.length > 5) {
    final toArchive = videoFiles.sublist(5);

    for (final file in toArchive) {
      final fileName = file.uri.pathSegments.last;
      final newPath = '${archivesDir.path}/$fileName';

      try {
        await file.rename(newPath);
        print('✅ Fichier archivé : $fileName');
      } catch (e) {
        print('⚠️ Erreur lors du déplacement de $fileName : $e');
      }
    }
  } else {
    print('🟢 Moins de 6 vidéos : aucune archive nécessaire.');
  }
}


Future<String> getUniqueVideoPath(String baseTitle, String extension, Directory directory) async {
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
final videoNoSoundDir = Directory('/storage/emulated/0/Movies/NoAudio');

if (!await outputDir.exists()) await outputDir.create(recursive: true);
if (!await videoNoSoundDir.exists()) await videoNoSoundDir.create(recursive: true);

// Vérifie si on a de l’audio ou non pour choisir le chemin de sortie
final bool hasAudio = (audioSource != null && audioSource.isNotEmpty);

final String outputVideoPath = await getUniqueVideoPath(
  videoTitle ?? 'video',
  '.mp4',
  hasAudio ? outputDir : videoNoSoundDir,
);
  

 // log('📽️ Chemin de sortie vidéo sans audio : $videoNoAudioPath');


  log('📽️ Chemin de sortie vidéo : $outputVideoPath');

  if (outputVideoPath.isNotEmpty) {
   
  await manageVideoFiles(); // ta fonction qui déplace les anciennes vidéos dans Archives
}

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

//si le dossier Movies/noAudio n'existe pas, on le crée
 // final videoNoAudioPath = Directory('/storage/emulated/0/Movies/NoAudio');
 
  //final videoNoAudioPath = Directory('/storage/emulated/0/Movies/NoAudio');
     

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
      '-map "[outv]" -c:v libx264 -pix_fmt yuv420p -loglevel debug "$outputVideoPath"';

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

  final tempWithAudioPath = '${tempDir.path}/video_with_audio_${DateTime.now().millisecondsSinceEpoch}.mp4';

  String commandWithAudio = '-y -i "$outputVideoPath" -i "$finalAudioFilePath" '
      '-filter_complex "[0:v]fade=t=out:st=$safeFadeOutStartTime:d=$fadeOutDuration[v_faded]; '
      '[1:a]afade=t=out:st=$safeFadeOutStartTime:d=$fadeOutDuration[a_faded]" '
      '-map "[v_faded]" -map "[a_faded]" '
      '-c:v libx264 -preset veryfast -crf 26 -c:a aac -strict experimental '
      '"$tempWithAudioPath"';

  log('🛠️ Commande FFmpeg pour ajout audio et fade out : $commandWithAudio');
  final session = await FFmpegKit.execute(commandWithAudio);
  final returnCode = await session.getReturnCode();
  final logs = await session.getLogsAsString();
  log('📜 Logs ajout audio et fade out:\n$logs');

  if (!ReturnCode.isSuccess(returnCode)) {
    log('❌ Erreur lors de l’ajout de l’audio et du fade out. Code: ${returnCode?.getValue()}');
    return "";
  }

  log('✅ Vidéo avec audio générée temporairement à : $tempWithAudioPath');

  // On écrase la vidéo finale sans audio par la version avec audio
  try {
    await File(tempWithAudioPath).copy(outputVideoPath);
    log('✅ Vidéo finale avec audio écrite à : $outputVideoPath');
    return outputVideoPath;
  } catch (e) {
    log('❌ Erreur lors de l’écriture finale de la vidéo avec audio : $e');
    return "";
  }
}

  log('✅ Vidéo créée sans audio à : $outputVideoPath');
  return outputVideoPath;
  
}

class _MediaUploaderState extends State<MediaUploader> {
  //String? _selectedFile;
  final _formKey = GlobalKey<FormState>();
  int? selectValue;
 // int? autoScrollValue;

  

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
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    final carouselProvider = context.read<CarouselProvider>();

    if (result != null) {
      List<String> newSelectedImages = result.files.map((file) => file.path!).toList();

      // Ajout des nouvelles images au provider
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

      // Met à jour dans le provider la chaîne affichée
      carouselProvider.setSelectedFileLabel('fichier sélectionné: $fileName');

      widget.imageContainerCallback(carouselProvider.images);
      log('Callback called with: ${carouselProvider.images}');
    } else {
      // Pas de fichier sélectionné : on vide aussi la sélection dans le provider
      carouselProvider.setSelectedFileLabel('Aucun fichier sélectionné.');
    }
  } catch (e) {
    log("Erreur lors de la sélection du fichier : $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du fichier: $e')),
      );
    }
    // En cas d'erreur, on met à jour aussi le provider
    final carouselProvider = context.read<CarouselProvider>();
    carouselProvider.setSelectedFileLabel('Erreur lors de la sélection du fichier.');
  }
}


  @override
  Widget build(BuildContext context) {
   final carouselProvider = context.watch<CarouselProvider>();
   final selectFileLabel = carouselProvider.selectedFileLabel;
   final autoScrollValue = carouselProvider.autoScrollValue;
    final int imageCount = carouselProvider.imageCount;

    bool isButtonEnabled = selectFileLabel != null &&
        autoScrollValue != null &&
        imageCount >= 2;
    
    // Condition pour activer/désactiver le dropdown du défilement automatique
    bool canSelectScroll = imageCount >= 2;
 log('autoScrollValue: $autoScrollValue, imageCount: $imageCount, _selectedFile: $selectFileLabel, isButtonEnabled: $isButtonEnabled, canSelectScroll: $canSelectScroll');
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Utilisez MainAxisSize.min pour que la colonne ne prenne que l'espace nécessaire.
        // C'est crucial si le parent a une hauteur illimitée (comme un Expanded).
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
              onPressed: pickFile,
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
          // if (_selectedFile != null)
          //   Padding(
          //     padding: const EdgeInsets.only(top: 8.0),
          //     child: Text(
          //       _selectedFile!,
          //       style: const TextStyle(color: Colors.black, fontSize: 14),
          //     ),
          //   ),
          // const Text('Formats supportés : JPG, PNG',
          //     style: TextStyle(color: Colors.grey)),
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
 DropdownButtonFormField<int>(
  value: carouselProvider.autoScrollValue,
  items: const [
    DropdownMenuItem(value: 0, child: Text('Désactivé')),
    DropdownMenuItem(value: 1, child: Text('Activé')),
  ],
  onChanged: (value) {
    context.read<CarouselProvider>().updateAutoScrollValue(value);
    widget.autoScrollValueCallback(value !);
  
    
  }
  ,
  decoration: const InputDecoration(
    border: OutlineInputBorder(),
    labelText: 'Défilement Automatique',
  ),
)
          else
            const Text(
              'Au moins 2 images sont nécessaires pour activer le défilement automatique.',
              style: TextStyle(color: Colors.red),
            ),
          const SizedBox(height: 20),
          
        

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
             
              backgroundColor: isButtonEnabled ? Colors.green : Colors.grey,
            ), 
            onPressed: isButtonEnabled
                ?  () async {
                   // await convertImagesToVideo(carouselProvider.images);
                  widget.onValidation(); // Appel du callback pour activer le swipe
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (widget.scaffoldKey.currentState != null) {
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

        ],
      ),
    );
  }
}