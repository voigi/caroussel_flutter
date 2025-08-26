import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final VoidCallback onPrivacyTap;
  final VoidCallback onContactTap; // Nouveau callback

  const BottomNavBar({
    super.key,
    required this.onPrivacyTap,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 50,
      color: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // espace les boutons
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onPrivacyTap,
              child: Text(
                "Politique de confidentialité",
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onContactTap,
              child: Row(
                children: const [
                  Icon(Icons.email_outlined, color: Colors.blue, size: 18),
                  SizedBox(width: 4),
                  Text(
                    "Me contacter",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
