

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:developer';


class MediaUploader extends StatefulWidget {

  //1. creation des callbacks
  final void Function(List<String> imagePath) imageContainerCallback;
  final void Function(int) selectValueCallback;
  final void Function(int) autoScrollValueCallback;
  //final void Function(String name) nameCallback; 
  //2. Ajout des callbacks dans le constructeur
  const MediaUploader({super.key, required this.imageContainerCallback, required this.selectValueCallback,required,required this.autoScrollValueCallback});

  @override
  State<MediaUploader> createState() => _MediaUploaderState();
}

class _MediaUploaderState extends State<MediaUploader> {
  
  String? _selectedFile; // Stocke le fichier sélectionné
  final _formKey = GlobalKey<FormState>();
  int? selectValue ;
  int? autoScrollValue;

// Valeur par défaut pour le Dropdown
  List<String> selectedImages = [];

  Future<void> pickFile() async {
    try {
      // Sélectionner un fichier
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
         // Permet tous les types de fichiers
      );

      if (result != null) {
        // Récupérer le nom du fichier
       String? fileName = result.files.single.name;

      log(fileName);
        // Récupérer l'extension du fichier


        
       String extension = fileName.substring(fileName.lastIndexOf('.')); // Inclut le point (.)

       // Vérifier si le nom du fichier est trop long
        if (fileName.length > 20) {
          // Tronquer le nom du fichier tout en gardant l'extension
          fileName = '${fileName.substring(0, 10)} ...$extension';
        }

       // Mettre à jour le texte avec le nom du fichier sélectionné
        setState(() {
          _selectedFile = 'fichier sélectionné: $fileName';
          selectedImages.add(result.files.single.path!);
         // log('selectedImages: $selectedImages');
        });
        List<String> imagePath = selectedImages;
        //3. Appel des callbacks
        widget.imageContainerCallback(imagePath );
       // widget.nameCallback(fileName.substring(0, fileName.lastIndexOf('.')));
      } else {
        setState(() {
           
          _selectedFile = 'Aucun fichier sélectionné.';
          
        });
      }
    } catch (e) {
      print("Erreur lors de la sélection du fichier : $e");
      setState(() {
        _selectedFile = 'Erreur lors de la sélection du fichier.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         
          Row(
            children: [
              Icon(Icons.looks_one, color: Colors.green),
              Text(
                'Choisir un Fichier',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: pickFile,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50), // Largeur infinie, hauteur 50
              backgroundColor: Colors.blue,
            ),
            child: Text(
              'Choisir un fichier'.toUpperCase(),
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _selectedFile != null
                  ? RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _selectedFile!.substring(0, _selectedFile!.lastIndexOf('.')),
                            style: TextStyle(color: Colors.black), // Style normal pour le nom du fichier
                          ),
                          TextSpan(
                            text: _selectedFile!.substring(_selectedFile!.lastIndexOf('.')),
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), // Styliser l'extension
                          ),
                        ],
                      ),
                    )
                  : Text('Aucun fichier sélectionné.'),
              SizedBox(width: 5),
            ],
          ),
           Row(
             children: [
                Icon(Icons.looks_two, color: Colors.green),
               const Text(
                ' Choisir un Format',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                         ),
             ],
           ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            dropdownColor: Colors.white,
            hint: Text('Image ou Carré ?',
            style: _selectedFile == null ? TextStyle(color:Colors.grey):TextStyle(color: Colors.black)),
            decoration: const InputDecoration(
              labelText: 'Format (e.g. Image, Carré)',
              border: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(13, 71, 161, 1))),
            ),
            value: selectValue, // Valeur initiale
            items: const [
              DropdownMenuItem(
                value: 1,
                child: Text('Image'),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text('Carré'),
              ),
            ],
            
            onChanged:  _selectedFile == null ? null : (value) {
              
              setState(() {
                selectValue = value;
                widget.selectValueCallback(value!); 
              }
             
              );
            },
            
           
          ),
          const SizedBox(height: 20),
          Row(
          children: [
    Row(
      children: [
        Icon(Icons.looks_3, color: Colors.green),
        Text(
          ' Défilement Oui/Non',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    ),
    SizedBox(width: 30),
    Icon(
      autoScrollValue == 1 
          ? Icons.check_circle 
          : autoScrollValue == 2 
            ? Icons.cancel 
            : Icons.circle, // Icône par défaut quand null
      color: autoScrollValue == 1
          ? Colors.green
          : autoScrollValue == 2
            ? Colors.red
            : Colors.transparent, // Transparent si null
    ),
  ],
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<int>(
            dropdownColor: Colors.white,
            hint: Text('Défilement automatique ?',
            style: _selectedFile == null ? TextStyle(color:Colors.grey):TextStyle(color: Colors.black)),
            decoration: const InputDecoration(
             labelText: 'Défilement automatique Oui/Non',
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromRGBO(13, 71, 161, 1))),
            ),
           value:autoScrollValue, // Valeur initiale
            items: const [
              DropdownMenuItem(
                value: 1,
                child: Text('Oui'),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text('Non'),
              ),
            ],
            onChanged:  _selectedFile == null || selectValue ==  null? null : (value) {
              setState(() {
              /*si la valeur est 1 alors on active le défilement automatique sinon on le désactive
              l'idée est de récupérer le contenu de la liste selectImages et de faire défiler son contenu ds le carousel
              */
                autoScrollValue = value;
                widget.autoScrollValueCallback(value!);
              });
            },
          )
        ],
      ),
    );
  }
}
