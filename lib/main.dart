import 'package:flutter/material.dart';
import 'package:caroussel/media_uploader.dart';
import 'package:flutter/services.dart';
import 'package:caroussel/carrousel.dart';
import 'package:caroussel/drawer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Verrouille l'orientation sur le mode portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Mode portrait vertical
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isContainerVisible = false;
  List<String>? _imagePath;
  List<String> _imageNames = []; // Liste pour les noms des images
  int? _selectValue = 1;
  int? _autoScrollValue;

  // Modifie cette méthode pour gérer à la fois les images et leurs noms
  void _imageContainer(imagePath) {
    setState(() {
      _isContainerVisible = true;
      _imagePath = imagePath;
 
    });
  }

  void _selectedValue(int selectValue) {
    setState(() {
      _selectValue = selectValue;
    });
  }

  // Callback pour gérer le nom des images
  void name(String name) {
    setState(() {
      _imageNames.add(name); // Ajouter le nom de l'image dans la liste
    });
  }

  void autoScrollValue(int autoScrollValue) {
    setState(() {
      _autoScrollValue = autoScrollValue;
    });
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
      
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.cyan[700],
          title: Center(child: Text('Mon Carrousel', style: TextStyle(color: Colors.white))),
          actions: [IconButton(onPressed: null, icon: Icon(Icons.search, color: Colors.transparent))],
        ),
        
         endDrawer: MyDrawer(),
         endDrawerEnableOpenDragGesture: false,
        
        
        
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centrer tout le contenu
          children: [
            SizedBox(height: 30.0),

            // Affichage conditionnel du Carrousel
            if (_isContainerVisible)
              Carrousel(
                imagePath: _imagePath!,
                selectValue: _selectValue,
                autoScrollValue: _autoScrollValue,
               // imageNames: _imageNames,
              ),

            // Utilisation de Expanded pour occuper tout l'espace restant et centrer le contenu
            Expanded(
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(249, 250, 251, 1.0),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 10,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ajouter un Média',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        //4. Ajouter le callback pour le nom ds le widget MediaUploader
                        MediaUploader(
                          scaffoldKey: _scaffoldKey,
                          imageContainerCallback: _imageContainer,
                          selectValueCallback: _selectedValue,
                          autoScrollValueCallback: autoScrollValue,
                         // nameCallback: name, // Passer le callback pour les noms d'images
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
