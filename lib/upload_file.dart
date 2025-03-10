import 'package:file_picker/file_picker.dart';

Future<String?> pickFile() async {
  try {
    // Sélectionner un fichier
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowedExtensions: ['bmp', 'jpg', 'png', 'jpeg'],
      allowMultiple: false,
    );

    if (result != null) {
      //String? fileName = result.files.single.name;
      String? filePath = result.files.single.path;
      return filePath;
     // log(fileName);
    }
    return null;
  } catch (e) {
    print("Erreur lors de la sélection du fichier : $e");
  }
  return null;
}
