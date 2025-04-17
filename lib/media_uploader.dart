import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'carousel_provider.dart';
import 'dart:developer';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
//import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:path_provider/path_provider.dart';
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

        // Mettre à jour l'état global avec les images sélectionnées
        context.read<CarouselProvider>().setSelectedImages(selectedImages);
        
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

  // Créer un dossier temporaire
  final tempDir = await Directory.systemTemp.createTemp('carousel_temp_');

  // Copier les images dans le dossier temporaire avec des noms séquentiels
  for (int i = 0; i < images.length; i++) {
    final extension = images[i].split('.').last.toLowerCase();
    final targetPath = '${tempDir.path}/image${i + 1}.jpg';
    final original = File(images[i]);

    // Ici on copie toujours, mais on pourrait convertir plus tard
    await original.copy(targetPath);
  }

  // Remplacer ceci :
  // Directory ? downloadsDir = await getExternalStorageDirectory();
  // String  outputVideoPath = '${downloadsDir!.path}/output.mp4';

  // Par cela :
final outputDir = await getExternalStorageDirectory();

  final outputVideoPath = '${outputDir!.path}/output.mp4';

  final command =
      '-y -framerate 0.33 -i "${tempDir.path}/image%d.jpg" -c:v libx264 -r 30 -pix_fmt yuv420p "$outputVideoPath"';

  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();

  if (ReturnCode.isSuccess(returnCode)) {
    log('✅ Vidéo créée avec succès : $outputVideoPath');
    // Tu peux ensuite utiliser Share.shareFile(File(outputVideoPath)); si tu veux partager
  } else {
    final logs = await session.getAllLogsAsString();
    log('❌ Erreur FFmpeg :\n$logs');
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
