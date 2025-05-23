import 'package:flutter/material.dart';



class CarouselProvider with ChangeNotifier {
  List<String> _images = [];
  int? _autoScrollValue;

  List<String> get images => _images;
  int? get autoScrollValue => _autoScrollValue;

  void setImages(List<String> images) {
    _images = images;
    notifyListeners();
  }

  void addImage(String path) {
    _images.add(path);
    notifyListeners();
  }

  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
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
}
