import 'package:flutter/material.dart';
import '../pages/clientes_page.dart';

class NavigationProvider with ChangeNotifier {
  Widget _currentPage = const ClientesPage();
  String _currentPageTitle = 'Clientes';
  VoidCallback? _fabAction;

  // Propiedades para la búsqueda
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }


  Widget get currentPage => _currentPage;
  String get currentPageTitle => _currentPageTitle;
  VoidCallback? get fabAction => _fabAction;

  void changePage(Widget page, String title) {
    _currentPage = page;
    _currentPageTitle = title;
    _fabAction = null; // Reseteamos la acción al cambiar de página
    updateSearchQuery(''); // Y también reseteamos la búsqueda
    notifyListeners();
  }

  void registerFabAction(VoidCallback action) {
    // Usamos un post-frame callback para evitar errores de "setState durante un build"
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
