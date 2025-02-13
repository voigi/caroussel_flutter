import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:developer';

class MediaUploader extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final void Function(List<String> imagePath) imageContainerCallback;
  final void Function(int) selectValueCallback;
  final void Function(int) autoScrollValueCallback;

  const MediaUploader({
    super.key,
    required this.imageContainerCallback,
    required this.selectValueCallback,
    required this.autoScrollValueCallback,
    required this.scaffoldKey,
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
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        String? fileName = result.files.single.name;
        log(fileName);

        String extension = fileName.substring(fileName.lastIndexOf('.')); // Inclut le point (.)

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
  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blue),
),
SizedBox(height: 50.0)
            ],
          ),
          ElevatedButton.icon(
            onPressed: pickFile,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Colors.blue,
            ),
            icon:Icon(Icons.upload_file, color: Colors.white),
            label: Text(
              'Choisir un fichier'.toUpperCase(),
              style: TextStyle(color: Colors.white),
            ),
            
          ),Text('Formats supportés : JPG, PNG', style: TextStyle(color: Colors.white)),
         // const SizedBox(height: 20),
          Row(
            children: [
              _selectedFile != null
                  ? RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _selectedFile!.substring(0, _selectedFile!.lastIndexOf('.')),
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: _selectedFile!.substring(_selectedFile!.lastIndexOf('.')),
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : Container(
                    margin: const EdgeInsets.only(left:20.0),
                    child: Text('Aucun fichier sélectionné.'),
                  ),
              SizedBox(width: 5),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.looks_two, color: Colors.green),
                 Text(
  'Choisir un Format',
  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blue),
),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            dropdownColor: Colors.white,
            hint: Text(
              'Image ou Carré ?',
              style: _selectedFile == null ? TextStyle(color: Colors.grey) : TextStyle(color: Colors.black),
            ),
            decoration: const InputDecoration(
              labelText: 'Format (e.g. Image, Carré)',
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromRGBO(13, 71, 161, 1))),
            ),
            value: selectValue,
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
            onChanged: _selectedFile == null
                ? null
                : (value) {
                    setState(() {
                      selectValue = value;
                      widget.selectValueCallback(value!);
                    });
                  },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.looks_3, color: Colors.green),
                  Text(
  'Défilement Automatique',
  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blue),
),
                ],
              ),
              SizedBox(width: 30),
              Icon(
                autoScrollValue == 1
                    ? Icons.check_circle
                    : autoScrollValue == 2
                        ? Icons.cancel
                        : Icons.circle,
                color: autoScrollValue == 1
                    ? Colors.green
                    : autoScrollValue == 2
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
              style: _selectedFile == null ? TextStyle(color: Colors.grey) : TextStyle(color: Colors.black),
            ),
            decoration: const InputDecoration(
              labelText: 'Défilement automatique Oui/Non',
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromRGBO(13, 71, 161, 1))),
            ),
            value: autoScrollValue,
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
            onChanged: _selectedFile == null || selectValue == null
                ? null
                : (value) {
                    setState(() {
                      autoScrollValue = value;
                      widget.autoScrollValueCallback(value!);
                    });
                  },
          ),
          SizedBox(height: 20),
          ElevatedButton(
             style: _selectedFile!=null && selectValue!=null && autoScrollValue!=null? ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Colors.green,
            ):ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Colors.grey,
            ),
            onPressed: () {
              // Ouvre le Drawer en utilisant la clé passée depuis main.dart
              
              Future.delayed(Duration(milliseconds: 100), () {
                if (widget.scaffoldKey.currentState != null &&_selectedFile != null && selectValue !=null && autoScrollValue !=null)  {
                  widget.scaffoldKey.currentState!.openEndDrawer();
                }
              });
            },
            child: Text('Valider', style: selectValue ==null && autoScrollValue == null? TextStyle(color: Colors.grey[600])
            :TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
