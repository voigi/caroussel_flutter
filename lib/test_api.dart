import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';


Future<List> fetchData() async {

 const apiKeytest ='BnTMdvUVteCn8xR13DR7r82iBdpATBZoKQYpGMYW';


  final response = await http.get(Uri.parse('https://freesound.org/apiv2/search/text/?query=background&filter=duration:[0 TO 10]&fields=id,name&token=$apiKeytest'));


  if (response.statusCode == 200) {
    // Si la requête est réussie (statusCode 200), parse le JSON
    print('Réponse de l\'API: ${response.body}');
     // Décoder la réponse JSON
      var decodedData = json.decode(response.body);

      // Convertir explicitement les résultats en une liste
      List<dynamic> results = decodedData['results'];
      print('Résultats: $results');
      return results;
  } else {
    // Si la requête échoue, lance une exception
    throw Exception('Erreur lors de la récupération des données');
  }
}

Future<String?> getSoundDownloadUrl(int soundId) async {
  const apiKeytest = 'BnTMdvUVteCn8xR13DR7r82iBdpATBZoKQYpGMYW'; // Votre clé API

  final response = await http.get(Uri.parse('https://freesound.org/apiv2/sounds/$soundId/?token=$apiKeytest'));

  if (response.statusCode == 200) {
    var decodedData = json.decode(response.body);

    // C'est cette ligne de log qui va nous donner les informations cruciales !
    log('Réponse complète des détails du son $soundId:\n${json.encode(decodedData)}');

    if (decodedData['previews'] != null) {
      if (decodedData['previews']['preview-lq-mp3'] != null) {
        log('URL de prévisualisation (lq-mp3) trouvée: ${decodedData['previews']['preview-lq-mp3']}');
        return decodedData['previews']['preview-lq-mp3'];
      } else if (decodedData['previews']['preview-hq-mp3'] != null) {
        log('URL de prévisualisation (hq-mp3) trouvée: ${decodedData['previews']['preview-hq-mp3']}');
        return decodedData['previews']['preview-hq-mp3'];
      }
    } else if (decodedData['download'] != null) {
      log('URL de téléchargement direct trouvée (nécessite potentiellement OAuth): ${decodedData['download']}');
      return decodedData['download'];
    }

    log('❌ Aucune URL de téléchargement ou de prévisualisation valide trouvée pour le son $soundId');
    return null;
  } else {
    log('❌ Erreur lors de la récupération des détails du son $soundId: ${response.statusCode}');
    return null;
  }
}