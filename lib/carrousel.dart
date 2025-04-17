import 'dart:async';
import 'dart:io';
import 'dart:developer';
//import 'package:caroussel/main.dart';
import 'package:flutter/material.dart';
import 'package:caroussel/edit_modal.dart';


class Carrousel extends StatefulWidget {
  final List<String> imagePath;
  //final int? selectValue;
   final int? autoScrollValue ;
   final Function updateImageLengthCallback;
   //final VoidCallback onImageDeleted;
  
//final Function(int?) onAutoScrollChanged;
  //final List String name;

  const Carrousel(
      {Key? key,
      required this.imagePath,
      required this .updateImageLengthCallback,
     // required this.onImageDeleted,
      //required this.selectValue,
      required this.autoScrollValue})
      : super(key: key);

  @override
  State<Carrousel> createState() => _CarrouselState();
}

class _CarrouselState extends State<Carrousel> {
  int currentIndex = 0;
  Timer? timer;
  int? localAutoScrollValue;

  @override
  void initState() {
    super.initState();
    localAutoScrollValue = widget.autoScrollValue; // Initialisation de la valeur
    autoScroll(); // Appel au démarrage du widget
  }

   void updateImageAtIndex(String newPath) {
  setState(() {
    widget.imagePath[currentIndex] = newPath;
  });
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

  //Fonction pour supprimmer une image
  void deleteImage() {
    if (widget.autoScrollValue == 2 || widget.imagePath.isNotEmpty) {
      if (widget.imagePath.isNotEmpty &&
          currentIndex >= 0 &&
          currentIndex < widget.imagePath.length) {
        setState(() {
          widget.imagePath.removeAt(currentIndex);

          // S'assurer que l'index reste valide après suppression
          if (currentIndex >= widget.imagePath.length) {
            currentIndex =
                widget.imagePath.isNotEmpty ? widget.imagePath.length - 1 : 0;
          }
          //faire passer la nouvelle valeur de widget.imagepath.lenght à mediauploader.dart
           // Appeler la fonction pour informer mediaUploader.dart
        widget.updateImageLengthCallback(widget.imagePath.length);
        });
      }
    }
  }

  // Fonction pour revenir à l'index précédent
  void previousIndex() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    } else {
      setState(() {
        currentIndex = widget.imagePath.length - 1; // Revenir à la fin
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

    if (widget.imagePath.isEmpty) {
      // setState(() {
      //   widget.onAutoScrollChanged(null);
      // });
      setState(() {
        localAutoScrollValue = null; // On met localAutoScrollValue à null
      });
    
      return SizedBox.shrink();
       
    }

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
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          if (widget.autoScrollValue == 1) ...[
            Positioned(
              right: 2,
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.edit, size: 35.0),
                color: Colors.transparent,
              ),
            ),
            Positioned(
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.delete, size: 35.0),
                color: Colors.transparent,
              ),
            ),
          ] else ...[
            Positioned(
              right: 2,
              child: IconButton(
                onPressed: () async {
                  await editModal(context,updateImageAtIndex,currentIndex);
                },
                icon: Icon(Icons.edit, size: 35.0),
              ),
            ),
            Positioned(
              child: IconButton(
                onPressed: deleteImage,
                icon: Icon(Icons.delete, size: 35.0),
                color: Colors.red,
              ),
            ),
            Positioned(
              right: 5.0,
              top: 93.0,
              child: IconButton(
                onPressed: nextIndex,
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
                onPressed: previousIndex,
                icon: Icon(
                  Icons.arrow_circle_left_outlined,
                  size: 35.0,
                ),
              ),
            )
          ],
          // if (widget.autoScrollValue == 2 || widget.imagePath.isNotEmpty) ...[
          //   Positioned(
          //     right: 2,
          //     child: IconButton(
          //       onPressed: () async  {await editModal(context);},
          //       icon: Icon(Icons.edit, size: 35.0),
          //     ),
          //   ),
          //   Positioned(
          //     child: IconButton(
          //       onPressed: deleteImage,
          //       icon: Icon(Icons.delete, size: 35.0),
          //       color: Colors.red,
          //     ),
          //   ),
          //   Positioned(
          //     right: 5.0,
          //     top: 93.0,
          //     child: IconButton(
          //       onPressed: nextIndex,
          //       icon: Icon(
          //         Icons.arrow_circle_right_outlined,
          //         size: 35.0,
          //       ),
          //     ),
          //   ),
          //   Positioned(
          //     left: 5.0,
          //     top: 93.0,
          //     child: IconButton(
          //       onPressed: previousIndex,
          //       icon: Icon(
          //         Icons.arrow_circle_left_outlined,
          //         size: 35.0,
          //       ),
          //     ),
          //   )
          // ],
        ],
      ),
    );
  }
}
