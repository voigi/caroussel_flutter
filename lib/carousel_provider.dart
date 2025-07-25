import 'package:flutter/material.dart';



class CarouselProvider with ChangeNotifier {
  List<String> _images = [];
  int? _autoScrollValue;
   int _imageCount = 0; 
  int get imageCount => _imageCount;
  bool _isContainerVisible = true;
  bool get isContainerVisible => _isContainerVisible;
  String? _selectedFileLabel;
  String? get selectedFileLabel => _selectedFileLabel;

  setSelectedFileLabel(String? label) {
    _selectedFileLabel = label;
    notifyListeners();
  }

  List<String> get images => _images;
  int? get autoScrollValue => _autoScrollValue;

  void setImages(List<String> images) {
    _images = images;
    _imageCount = _images.length; // Mettre à jour le nombre d'images
    notifyListeners();
  }

  void addImage(String path) {
    _images.add(path);
    _imageCount = _images.length; // Mettre à jour le nombre d'images
    notifyListeners();
  }

  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      _imageCount = _images.length; // Mettre à jour le nombre d'images
      notifyListeners();
    }
  }

  void updateImageAtIndex(int index, String newPath) {
    if (index >= 0 && index < _images.length) {
      _images[index] = newPath;
      notifyListeners();
    }
  }

  void updateAutoScrollValue(int? value) {
    _autoScrollValue = value;
    notifyListeners();
  }
  void setContainerVisible(bool visible) {
  _isContainerVisible = visible;
  notifyListeners();
}
}

