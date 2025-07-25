
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';



Future<String> generateVideo(List<String> imagePaths) async {
  String outputFilePath = '/storage/emulated/0/Movies/';

  // Créer une liste de fichiers images sous forme de chaîne
  String images = imagePaths.map((path) => 'file:$path').join('|');
  
  // Commande FFmpeg pour assembler les images en vidéo
  String command = '-f concat -safe 0 -i "concat:$images" -vsync vfr $outputFilePath';

  // Exécution de la commande FFmpeg
  return FFmpegKit.execute(command).then((session) async {
    // Récupérer le code de retour
    final returnCode = await session.getReturnCode();

    // Vérification du code de retour
    if (ReturnCode.isSuccess(returnCode)) {
      print('Vidéo générée avec succès à $outputFilePath');
      return outputFilePath;  // Retourner le chemin de la vidéo générée
    } else if (ReturnCode.isCancel(returnCode)) {
      print('La commande a été annulée');
      return '';  // Retourner une chaîne vide si l'exécution a été annulée
    } else {
      print('Erreur lors de la génération de la vidéo');
      return '';  // Retourner une chaîne vide en cas d'erreur
    }
  });
}