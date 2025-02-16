import 'dart:async';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';

class Carrousel extends StatefulWidget {
  final List<String> imagePath;
  //final int? selectValue;
  final int? autoScrollValue;

  //final List String name;

  const Carrousel(
      {Key? key,
      required this.imagePath,
      //required this.selectValue,
      required this.autoScrollValue})
      : super(key: key);

  @override
  State<Carrousel> createState() => _CarrouselState();
}

class _CarrouselState extends State<Carrousel> {
  int currentIndex = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    autoScroll(); // Appel au démarrage du widget
  }

  // Fonction pour gérer le défilement automatique
  void autoScroll() {
    if (widget.autoScrollValue == 1) {
      timer = Timer.periodic(Duration(seconds: 2), (Timer t) {
        nextIndex();
      });
    } else {
      timer?.cancel();
    }
  }

  // Fonction pour démarrer le défilement automatique
  void nextIndex() {
    if (currentIndex < widget.imagePath.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      setState(() {
        currentIndex = 0; // Revenir au début
      });
    }
  }

  // Fonction pour revenir à l'index précédent
  void previousIndex() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  @override
  void didUpdateWidget(Carrousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Vérifie si la valeur de `autoScrollValue` a changé et ajuste
    if (widget.autoScrollValue != oldWidget.autoScrollValue) {
      autoScroll(); // Démarre ou arrête le défilement automatique
    }
  }

  @override
  void dispose() {
    timer?.cancel(); // Arrête le timer lorsque le widget est détruit
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   // log('selectValue: ${widget.selectValue}');
    log('autoScrollValue: ${widget.autoScrollValue}');
    log('Chemin de l\'image: ${widget.imagePath}');

    return Container(
      margin: EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
     
    

      
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.3,
      
         
         
      child: Stack(
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Image.file(
                File(widget.imagePath[currentIndex]),
                fit: BoxFit.fitWidth,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // Si autoScrollValue == 2, on affiche les icônes normales
          if (widget.autoScrollValue == 2 || widget.imagePath.isNotEmpty) ...[
            Positioned(
              right: 2,
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.edit, size: 35.0),
              ),
            ),
            Positioned(
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.delete, size: 35.0),
                color: Colors.red,
              ),
            ),
            Positioned(
              right: 5.0,
              top: 93.0,
              child: IconButton(
                onPressed: previousIndex,
                icon: Icon(
                  Icons.arrow_circle_right_outlined,
                  size: 35.0,
                ),
              ),
            ),
            Positioned(
              left: 5.0,
              top: 93.0,
              child: IconButton(
                onPressed: nextIndex,
                icon: Icon(
                  Icons.arrow_circle_left_outlined,
                  size: 35.0,
                ),
              ),
            ),
          ],
          // Si autoScrollValue == 1, on applique la transparence aux icônes
          if (widget.autoScrollValue == 1) ...[
            Positioned(
              right: 2,
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.edit, size: 35.0),
                color:
                    Colors.transparent, // Transparence pour l'icône d'édition
              ),
            ),
            Positioned(
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.delete, size: 35.0),
                color: Colors
                    .transparent, // Transparence pour l'icône de suppression
              ),
            ),
            Positioned(
              right: 5.0,
              top: 30.0,
              child: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.arrow_circle_right_outlined,
                  size: 35.0,
                ),
                color: Colors
                    .transparent, // Transparence pour l'icône de défilement
              ),
            ),
            Positioned(
              left: 5.0,
              top: 30.0,
              child: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.arrow_circle_left_outlined,
                  size: 35.0,
                ),
                color: Colors
                    .transparent, // Transparence pour l'icône de défilement
              ),
            ),
          ],
        ],
      ),
    );
  }
}
