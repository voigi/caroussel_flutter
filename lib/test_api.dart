import 'dart:convert';
import 'package:http/http.dart' as http;


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

