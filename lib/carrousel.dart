import 'dart:async';
import 'dart:io';
import 'dart:developer';
//import 'package:caroussel/main.dart';
import 'package:caroussel/carousel_provider.dart';
import 'package:flutter/material.dart';
import 'package:caroussel/edit_modal.dart';
import 'package:provider/provider.dart';


class Carrousel extends StatefulWidget {
  
  //final int? selectValue;
   final int? autoScrollValue ;
  //final Function updateImageLengthCallback;
   //final VoidCallback onImageDeleted;
  
//final Function(int?) onAutoScrollChanged;
  //final List String name;

  const Carrousel(
      {super.key,
     //required this.imagePath,
     // required this .updateImageLengthCallback,
     // required this.onImageDeleted,
      //required this.selectValue,
      required this.autoScrollValue});

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
  final imagePaths = context.watch<CarouselProvider>().images;
  setState(() {
    imagePaths[currentIndex] = newPath;
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
    final imagePaths = context.read<CarouselProvider>().images;
    if (currentIndex < imagePaths.length - 1) {
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
    // Utilisez context.read pour accéder au provider sans reconstruire le widget
    final carouselProvider = context.read<CarouselProvider>();
    final imagePaths = carouselProvider.images; // Obtenez la liste actuelle du provider

    // La condition autoScrollValue == 2 semble spécifique à votre logique, gardons-la.
    // L'ajout de imagePaths.isNotEmpty dans la condition externe est aussi redondant
    // car la condition interne imagePaths.isNotEmpty la couvre déjà.
    if (widget.autoScrollValue == 2 || imagePaths.isNotEmpty) {
      if (imagePaths.isNotEmpty && currentIndex >= 0 && currentIndex < imagePaths.length) {
        setState(() {
          // --- MODIFICATION CLÉ ICI ---
          // Au lieu de modifier la liste locale et d'appeler un callback,
          // on demande au Provider de supprimer l'image.
          carouselProvider.removeImage(currentIndex);
          // --- FIN MODIFICATION ---

          // Note: Si le carrousel doit lui-même se mettre à jour après la suppression,
          // et que currentIndex est géré localement dans Carrousel,
          // vous devez vous assurer que currentIndex reste valide.
          // Le Provider notifiera les autres widgets, mais Carrousel doit gérer son propre affichage.

          // S'assurer que l'index reste valide après suppression pour le carrousel lui-même
          if (carouselProvider.images.isNotEmpty) { // Vérifiez la liste du provider
            if (currentIndex >= carouselProvider.images.length) {
              currentIndex = carouselProvider.images.length - 1;
            }
          } else {
            currentIndex = 0; // Si la liste est vide, réinitialiser l'index
          }
        });
        // Pas besoin d'appeler widget.updateImageLengthCallback ici
        // puisque le Provider s'en occupe déjà via notifyListeners().
      }
    }
  }

  // Fonction pour revenir à l'index précédent
  void previousIndex() {
    final imagePaths = context.read<CarouselProvider>().images;
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    } else {
      setState(() {
        currentIndex = imagePaths.length - 1; // Revenir à la fin
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
    final imagePaths = Provider.of<CarouselProvider>(context).images;
    log('autoScrollValue: ${widget.autoScrollValue}');
    log('Chemin de l\'image: $imagePaths');
    

    if (imagePaths.isEmpty) {
      // setState(() {
      //   widget.onAutoScrollChanged(null);
      // });
      // setState(() {
      //   localAutoScrollValue = null; 
      // });
      return Center(child: Text("Ajoutez des images pour démarrer le carrousel."));
    
    //  return SizedBox.shrink();
       
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
                File(imagePaths[currentIndex]),
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
