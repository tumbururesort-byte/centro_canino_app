
import 'package:flutter/material.dart';

// Enum para representar las páginas principales de la aplicación
enum AppPage {
  clientes,
  perfil,
}

class NavigationProvider with ChangeNotifier {
  AppPage _currentPage = AppPage.clientes; // Página inicial
  VoidCallback? _fabAction;
  String _searchQuery = '';

  // Getters públicos
  AppPage get currentPage => _currentPage;
  VoidCallback? get fabAction => _fabAction;
  String get searchQuery => _searchQuery;

  // Cambia la página actual
  void changePage(AppPage page) {
    if (_currentPage == page) return; // No hacer nada si ya estamos en la página

    _currentPage = page;
    _fabAction = null; // Reseteamos la acción del FAB
    _searchQuery = ''; // Reseteamos la búsqueda
    notifyListeners();
  }

  // Métodos para la búsqueda
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Métodos para el FAB
  void registerFabAction(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fabAction = action;
      notifyListeners();
    });
  }

  void unregisterFabAction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fabAction = null;
      notifyListeners();
    });
  }
}
