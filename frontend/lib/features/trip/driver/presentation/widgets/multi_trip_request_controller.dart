import 'package:flutter/material.dart';

class MultiAddressCardController extends ChangeNotifier {
  final Set<int> _selectedIndices = {};

  Set<int> get selectedIndices => _selectedIndices;

  void toggle(int index) {
    if (_selectedIndices.contains(index)) {
      _selectedIndices.remove(index);
    } else {
      _selectedIndices.add(index);
    }
    notifyListeners();
  }

  void clear() {
    _selectedIndices.clear();
    notifyListeners();
  }

  void select(int index) {
    _selectedIndices.add(index);
    notifyListeners();
  }

  void deselect(int index) {
    _selectedIndices.remove(index);
    notifyListeners();
  }

  bool isSelected(int index) => _selectedIndices.contains(index);
}
