import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final VoidCallback onPrivacyTap;

  const BottomNavBar({super.key, required this.onPrivacyTap});

  @override
  Widget build(BuildContext context) {
    // La BottomAppBar s'adapte à la hauteur de son parent.
    return BottomAppBar(
      height: 50,
      color: Colors.grey[200],
      // Le Padding crée une zone cliquable plus large et plus facile à atteindre.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent, // Assure que les clics sont détectés même dans les zones transparentes
          onTap: onPrivacyTap,
          child: Center(
            // Le texte est déplacé vers le haut pour être centré visuellement
            child: Transform.translate(
              offset: const Offset(0, -1.0),
              child: Text(
                "Politique de confidentialité",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
