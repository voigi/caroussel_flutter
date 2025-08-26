import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';



class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Politique de confidentialité',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/privacy.html'),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
Html(
  data: snapshot.data!,
onLinkTap: (url, attributes, element) async {
  if (url != null) {
    // Vérifie si c'est bien le mail de contact
    if (url.startsWith("mailto:")) {
      final String email = "moncarrousel.contact@gmail.com";
      final Uri mailtoUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': "Question concernant l'application Mon Carrousel",
          'body': "Bonjour,j'ai une question au sujet de l'application Mon Carrousel :",
        },
      );

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir l’application mail.')),
        );
      }
    } else {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir ce lien.')),
        );
      }
    }
  }
},

  style: {
    "body": Style(
      fontSize: FontSize(16.0),
      fontFamily: 'OpenSans',
    ),
  },
),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // retourne true
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text("J’accepte"),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return const Center(
                child: Text(
                    'Erreur de chargement de la politique de confidentialité.'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
