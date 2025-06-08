import 'package:file_picker/file_picker.dart';
import 'dart:developer'; // Pour utiliser log()

Future<String?> pickFile() async {
  try {
    // Sélectionner un fichier image uniquement
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image ,// Utiliser custom pour filtrer par extensions
     // allowedExtensions: ['bmp', 'jpg', 'png', 'jpeg']
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      String? filePath = result.files.single.path;
      log("✅ Fichier sélectionné : $filePath");
    return filePath;
        }
    log("⚠️ Aucun fichier sélectionné");
    return null;

  } catch (e) {
   log("❌ Erreur lors de la sélection du fichier : $e");
    return null;
  }
}

