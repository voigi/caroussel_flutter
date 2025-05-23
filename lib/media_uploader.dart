import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'carousel_provider.dart';
import 'dart:developer';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
//import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'dart:io';

class MediaUploader extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final void Function(List<String> imagePath) imageContainerCallback;
  final void Function(int) selectValueCallback;
  final void Function(int) autoScrollValueCallback;
  final List<String> imagePath;

  const MediaUploader({
    super.key,
    required this.imageContainerCallback,
    required this.selectValueCallback,
    required this.autoScrollValueCallback,
    required this.scaffoldKey,
    required this.imagePath,
  });

  @override
  State<MediaUploader> createState() => _MediaUploaderState();
}

class _MediaUploaderState extends State<MediaUploader> {
  String? _selectedFile;
  final _formKey = GlobalKey<FormState>();
  int? selectValue;
  int? autoScrollValue;

  // Liste pour stocker les images sélectionnées
  List<String> selectedImages = [];

  test(){
    log('hello world');
  }

  Future<void> pickFile() async {
    try {
      // Sélectionner un fichier
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        // Obtenir les chemins des fichiers sélectionnés
        List<String> newSelectedImages = result.files.map((file) => file.path!).toList();
        
        // Ajouter les nouvelles images à la liste existante
        selectedImages.addAll(newSelectedImages);
        log('selectedImages:$selectedImages');

        // Mettre à jour l'état global avec les images sélectionnées
        context.read<CarouselProvider>().setImages(selectedImages);
        //log('Provider images: ${context.read<CarouselProvider>().setImages(selectedImages)}');

        
        String? fileName = result.files.single.name;
        log(fileName);

        String extension = fileName
            .substring(fileName.lastIndexOf('.')); // Inclut le point (.)

        // Tronquer le nom du fichier si nécessaire
        if (fileName.length > 20) {
          fileName = '${fileName.substring(0, 10)} ...$extension';
        }

        setState(() {
          _selectedFile = 'fichier sélectionné: $fileName';
        });

        widget.imageContainerCallback(selectedImages);
       log('Callback called with: $selectedImages');

      } else {
        setState(() {
          _selectedFile = 'Aucun fichier sélectionné.';
        });
      }
    } catch (e) {
      print("Erreur lors de la sélection du fichier : $e");
      setState(() {
        _selectedFile = 'Erreur lors de la sélection du fichier.';
      });
    }
  }


  // Fonction pour convertir les images en vidéo avec FFmpeg
Future<void> convertImagesToVideo(List<String> images) async {
 if (images.length < 2) {
    log('❌ Il faut au moins deux images pour créer une vidéo.');
    return;
  }

  log('➡️ Création du dossier temporaire...');
  final tempDir = await Directory.systemTemp.createTemp('carousel_temp_');
  log('📁 Dossier temporaire : ${tempDir.path}');

  log('➡️ Copie et compression des images...');
  for (int i = 0; i < images.length; i++) {
    final sourcePath = images[i];
    final destPath = '${tempDir.path}/image${i + 1}.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      destPath,
      quality: 85,
      minWidth: 1080,
      minHeight: 1080,
    );

    if (compressed == null) {
      log('❌ Erreur de compression pour $sourcePath');
      return;
    }

    log('✅ Comprimée et copiée : $destPath');
  }

  log('➡️ Récupération du dossier de sortie...');
  final outputDir =  Directory('/storage/emulated/0/Download');
  final outputVideoPath = '${outputDir.path}/video.mp4';
  log('📦 Vidéo finale : $outputVideoPath');

  log('➡️ Construction de la commande FFmpeg...');
  final command =
      '-y -framerate 0.33 -i "${tempDir.path}/image%d.jpg" -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -r 25 -pix_fmt yuv420p "$outputVideoPath"';
  log('🛠️ Commande FFmpeg : $command');

  log('▶️ Exécution de la commande FFmpeg...');
  final session = await FFmpegKit.execute(command);

  final returnCode = await session.getReturnCode();
  if (ReturnCode.isSuccess(returnCode)) {
    log('✅ Vidéo créée avec succès : $outputVideoPath');
  } else {
    final logs = await session.getAllLogsAsString();
    final stacktrace = await session.getFailStackTrace();
    log('❌ Erreur FFmpeg :\n$logs');
    if (stacktrace != null) log('💥 Stacktrace : $stacktrace');
  }
}



  @override
  Widget build(BuildContext context) {
    bool isButtonEnabled = _selectedFile != null &&
        autoScrollValue != null &&
        selectedImages.length > 1;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.looks_one, color: Colors.green),
              Text(
                'Choisir un Fichier',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ],
          ),
          SizedBox(height: 10),
          Tooltip(
            message: 'Cliquez pour choisir un fichier',
            preferBelow: true,
            margin: EdgeInsets.all(8),
            textStyle: TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 194, 199, 204),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: pickFile,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blue,
              ),
              icon: Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                'Choisir un fichier'.toUpperCase(),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Text('Formats supportés : JPG, PNG',
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 20),

          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.looks_two, color: Colors.green),
                  Text(
                    'Défilement Automatique',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ],
              ),
              SizedBox(width: 30),
              Icon(
                autoScrollValue == 1 && selectedImages.length > 1
                    ? Icons.check_circle
                    : autoScrollValue == 2 && selectedImages.length > 1
                        ? Icons.cancel
                        : Icons.circle,
                color: autoScrollValue == 1 && selectedImages.length > 1
                    ? Colors.green
                    : autoScrollValue == 2 && selectedImages.length > 1
                        ? Colors.red
                        : Colors.transparent,
              ),
            ],
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<int>(
            dropdownColor: Colors.white,
            hint: Text(
              'Défilement automatique ?',
              style: _selectedFile == null || widget.imagePath.isEmpty || selectedImages.length <= 1
                  ? TextStyle(color: Colors.grey)
                  : TextStyle(color: Colors.black),
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
                child: Text(
                  selectedImages.length <= 1
                      ? 'Défilement automatique ?'
                      : 'Oui'),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text(
                  selectedImages.length <= 1
                      ? 'Défilement automatique ?'
                      : 'Non'),
              ),
            ],
            onChanged: _selectedFile == null || selectedImages.isEmpty || selectedImages.length <= 1
                ? null
                : (value) {
                    setState(() {
                      autoScrollValue = value;
                      widget.autoScrollValueCallback(value!);
                    });
                  },
          ),
          SizedBox(height: 20),
          Tooltip(
            message: _selectedFile != null && autoScrollValue != null
                ? 'Cliquez pour valider'
                : 'Veuillez sélectionner un fichier et une option',
            preferBelow: true,
            margin: EdgeInsets.all(13),
            textStyle: TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: isButtonEnabled ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: isButtonEnabled ? Colors.green : Colors.grey,
              ),
              onPressed: isButtonEnabled
                  ? () async {
                      // Convertir les images sélectionnées en vidéo

                      await convertImagesToVideo(selectedImages);

                      //test();

                      // Lancer une action après la conversion (comme fermer le drawer)
                      Future.delayed(Duration(milliseconds: 100), () {
                        if (widget.scaffoldKey.currentState != null &&
                            _selectedFile != null &&
                            autoScrollValue != null) {
                          widget.scaffoldKey.currentState!.openEndDrawer();
                        }
                      });
                    }
                  : null,
              child: Text('Valider',
                  style: isButtonEnabled
                      ? TextStyle(color: Colors.white)
                      : TextStyle(color: Colors.grey[600])),
            ),
          ),
        ],
      ),
    );
  }
}
