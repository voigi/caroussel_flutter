import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavBarHelper {
  /// Rend la barre de navigation transparente si possible
  /// et met une couleur de secours sinon.
  static void makeTransparent({Color fallbackColor = Colors.black}) {
    try {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    } catch (e) {
      // Si jamais un constructeur Android bloque la transparence
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          systemNavigationBarColor: fallbackColor,
          systemNavigationBarDividerColor: fallbackColor,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    }
  }
}
