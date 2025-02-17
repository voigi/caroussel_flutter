import 'package:file_picker/file_picker.dart';
import 'dart:developer';

Future<void> pickFile() async {
  try {
    // Sélectionner un fichier
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      String? fileName = result.files.single.name;
      log(fileName);
    }
  } catch (e) {
    print("Erreur lors de la sélection du fichier : $e");
  }
}
