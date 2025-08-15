// Fichier : privacy_policy_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';

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
              child: Html(
                data: snapshot.data!,
                style: {
                  "body": Style(
                    fontSize: FontSize(16.0),
                    fontFamily: 'OpenSans',
                  ),
                },
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