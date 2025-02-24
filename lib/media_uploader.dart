import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:developer';

class MediaUploader extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final void Function(List<String> imagePath) imageContainerCallback;
  final void Function(int) selectValueCallback;
  final void Function(int) autoScrollValueCallback;
  //final Function updateImageLengthCallback;
  final List <String> imagePath;

  const MediaUploader({
    super.key,
    required this.imageContainerCallback,
   // required this .updateImageLengthCallback,
    required this.selectValueCallback,
    required this.autoScrollValueCallback,
    required this.scaffoldKey,
    required this .imagePath,
  });

  @override
  State<MediaUploader> createState() => _MediaUploaderState();
}

class _MediaUploaderState extends State<MediaUploader> {
  
  String? _selectedFile; // Stocke le fichier sélectionné
  final _formKey = GlobalKey<FormState>();
  int? selectValue;
  int? autoScrollValue;

  // Liste pour stocker les images sélectionnées
  List<String> selectedImages = [];

  Future<void> pickFile() async {
    try {
      // Sélectionner un fichier
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        String? fileName = result.files.single.name;
        log(fileName);

        String extension = fileName
            .substring(fileName.lastIndexOf('.')); // Inclut le point (.)

        // Tronquer le nom du fichier si nécessaire
        if (fileName.length > 20) {
          fileName = '${fileName.substring(0, 10)} ...$extension';
        }

        setState(() {
          _selectedFile = 'fichier sélectionné: $fileName';
          selectedImages.add(result.files.single.path!);
        });

        List<String> imagePath = selectedImages;
        widget.imageContainerCallback(imagePath);
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

//  void updateImageLength() {
//   setState(() {
//    var longueurPath = selectedImages.length;
//     log('images: $longueurPath'); // Vérifier la nouvelle valeur
//   });
// }




  @override
  Widget build(BuildContext context) {
    


  //   if (widget.imagePath.isEmpty && autoScrollValue != null) {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     setState(() {
  //       autoScrollValue = null;
        
        
  //     });
  //   });
  // }
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
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
              
            ],
          ),
         SizedBox(height: 10),
          Tooltip(
         message: 'Cliquez pour choisir un fichier',
            preferBelow: true,
            margin: EdgeInsets.all(8),
            textStyle: TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 194, 199, 204),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: pickFile,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blue,
              ),
              icon: Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                'Choisir un fichier'.toUpperCase(),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Text('Formats supportés : JPG, PNG',
              style: TextStyle(color: Colors.white)),
          // const SizedBox(height: 20),
         
        
          const SizedBox(height: 20),
        
          
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.looks_two, color: Colors.green),
                  Text(
                    'Défilement Automatique',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ],
              ),
              SizedBox(width: 30),
              Icon(
                autoScrollValue == 1 && selectedImages.length > 1
                    ? Icons.check_circle
                    : autoScrollValue == 2 && selectedImages.length > 1
                        ? Icons.cancel
                        : Icons.circle,
                color: autoScrollValue == 1 && selectedImages.length > 1
                    ? Colors.green
                    : autoScrollValue == 2 && selectedImages.length > 1
                        ? Colors.red
                        : Colors.transparent,
              ),
            ],
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<int>(
            dropdownColor: Colors.white,
            hint: Text(
              
              'Défilement automatique ?',
              style: _selectedFile == null || widget.imagePath.isEmpty || selectedImages.length <= 1
                  ? TextStyle(color: Colors.grey)
                  : TextStyle(color: Colors.black),
            ),
            decoration: const InputDecoration(
              labelText: 'Défilement automatique Oui/Non',
              border: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(13, 71, 161, 1))),
            ),
            value: autoScrollValue,
            items: [
              DropdownMenuItem(
                value: 1,
                child: Text(
                  selectedImages.length <= 1
        ? 'Défilement automatique ?'
        : 
                  'Oui'),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text(
                  selectedImages.length <= 1
        ? 'Défilement automatique ?'
        : 
                  
                  
                  'Non'),
              ),
            ],
            onChanged: _selectedFile == null || selectedImages.isEmpty || selectedImages.length <= 1
                ? null
                : (value) {
                    setState(() {
                      autoScrollValue = value;
                      widget.autoScrollValueCallback(value!);
                    });
                  },
          ),
          SizedBox(height: 20),
          Tooltip(
            message:  _selectedFile != null && autoScrollValue != null
                ? 'Cliquez pour valider'
                : 'Veuillez sélectionner un fichier et une option',
            preferBelow: true,
            margin: EdgeInsets.all(13),
            textStyle: TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: _selectedFile != null && autoScrollValue != null
                  ? Colors.blue
                  : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              style: _selectedFile != null &&
                      autoScrollValue != null &&  selectedImages.length > 1
                  ? ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                    )
                  : ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.grey,
                    ),
              onPressed: () {
                // Ouvre le Drawer en utilisant la clé passée depuis main.dart
            
                Future.delayed(Duration(milliseconds: 100), () {
                  if (widget.scaffoldKey.currentState != null &&
                      _selectedFile != null &&
                      autoScrollValue != null) {
                    widget.scaffoldKey.currentState!.openEndDrawer();
                  }
                });
              },
              child: Text('Valider',
                  style: autoScrollValue == null
                      ? TextStyle(color: Colors.grey[600])
                      : TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
