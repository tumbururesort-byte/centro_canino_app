
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
  bool _isSearchActive = false; // <-- NUEVO: Estado para la búsqueda

  // Getters públicos
  AppPage get currentPage => _currentPage;
  VoidCallback? get fabAction => _fabAction;
  String get searchQuery => _searchQuery;
  bool get isSearchActive => _isSearchActive; // <-- NUEVO: Getter para el estado

  // Cambia la página actual
  void changePage(AppPage page) {
    if (_currentPage == page) return; 

    _currentPage = page;
    _fabAction = null; 
    _searchQuery = ''; 
    _isSearchActive = false; // <-- NUEVO: Reseteamos la búsqueda al cambiar de página
    notifyListeners();
  }

  // --- MÉTODOS PARA LA BÚSQUEDA ---

  // Inicia el modo de búsqueda
  void startSearch() {
    if (_isSearchActive) return;
    _isSearchActive = true;
    notifyListeners();
  }

  // Detiene el modo de búsqueda y limpia la consulta
  void stopSearch() {
    if (!_isSearchActive) return;
    _isSearchActive = false;
    _searchQuery = '';
    notifyListeners();
  }

  // Actualiza el texto de la búsqueda
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // --- MÉTODOS PARA EL FAB ---

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
