import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';


final String apiKeytest = dotenv.env['FREESOUND_API_KEY']!;

Future<List<dynamic>> fetchData({String keyword = 'background'}) async {
  log('Appel API FreeSound avec le mot-clé: $keyword');

  // Construction de l'URL de recherche FreeSound
  // Le 'query' sera le mot-clé fourni par l'utilisateur.
  // 'filter=duration:[0 TO 10]' limite les sons à 10 secondes maximum.
  // 'fields=id,name' demande uniquement l'ID et le nom du son pour simplifier la réponse.
  final url = Uri.parse(
      'https://freesound.org/apiv2/search/text/?query=$keyword&filter=duration:[0 TO 60]&fields=id,name&token=$apiKeytest');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      // L'API FreeSound renvoie ses résultats sous la clé 'results' dans le JSON.
      final List<dynamic> data = responseBody['results'] ?? [];
      log('Données API brutes reçues: $data');
      return data;
    } else {
      // Gérer les erreurs de réponse HTTP (ex: 404, 500)
      log('Échec de la récupération des données API FreeSound: Code ${response.statusCode}');
      log('Corps de la réponse: ${response.body}');
      throw Exception('Erreur de chargement des données FreeSound, code: ${response.statusCode}');
    }
  } catch (e) {
    // Gérer les erreurs de connexion réseau ou autres exceptions
    log('Erreur lors de l\'appel API FreeSound: $e');
    throw Exception('Échec de la connexion à l\'API FreeSound: $e');
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