import 'package:flutter/foundation.dart';
import '../models/catalog_item.dart';

class CatalogService extends ChangeNotifier {
  static final CatalogService _instance = CatalogService._internal();
  factory CatalogService() => _instance;
  CatalogService._internal();

  final List<CatalogItem> _items = [
    CatalogItem(
      id: '1',
      name: 'Make Glamour Dourada',
      category: 'Maquiagem',
      imageUrl: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=600&auto=format&fit=crop&q=80',
      description: 'Sombra perolada com delineado marcado e iluminador suave.',
      isSaved: false,
    ),
    CatalogItem(
      id: '2',
      name: 'Morena Iluminada Mel',
      category: 'Cores de Cabelo',
      imageUrl: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&auto=format&fit=crop&q=80',
      description: 'Mechas em tom de mel quente que valorizam o tom de pele.',
      isSaved: false,
    ),
    CatalogItem(
      id: '3',
      name: 'Batom Vermelho Clássico',
      category: 'Maquiagem',
      imageUrl: 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=600&auto=format&fit=crop&q=80',
      description: 'Acabamento matte aveludado e pele radiante natural.',
      isSaved: true,
    ),
    CatalogItem(
      id: '4',
      name: 'Corte Bob Francês Moderno',
      category: 'Cortes',
      imageUrl: 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?w=600&auto=format&fit=crop&q=80',
      description: 'Corte curto sofisticado na linha da mandíbula.',
      isSaved: false,
    ),
    CatalogItem(
      id: '5',
      name: 'Loiro Champagne Platinado',
      category: 'Cores de Cabelo',
      imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=600&auto=format&fit=crop&q=80',
      description: 'Tonalidade fria de alta luminosidade com raiz esfumada.',
      isSaved: false,
    ),
    CatalogItem(
      id: '6',
      name: 'Cachos Definidos & Volume',
      category: 'Penteados',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop&q=80',
      description: 'Finalização fitagem com brilho intenso e volume estruturado.',
      isSaved: true,
    ),
  ];

  List<CatalogItem> get items => List.unmodifiable(_items);

  List<CatalogItem> get savedGallery =>
      _items.where((element) => element.isSaved).toList();

  List<String> get categories => [
        'Todos',
        'Maquiagem',
        'Cores de Cabelo',
        'Cortes',
        'Penteados',
      ];

  void toggleSave(String id) {
    final index = _items.indexWhere((element) => element.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        isSaved: !_items[index].isSaved,
      );
      notifyListeners();
    }
  }

  void addItem({
    required String name,
    required String category,
    required String imageUrl,
    String description = '',
  }) {
    final newItem = CatalogItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: category,
      imageUrl: imageUrl.trim().isEmpty
          ? 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&auto=format&fit=crop&q=80'
          : imageUrl.trim(),
      description: description,
    );
    _items.insert(0, newItem);
    notifyListeners();
  }

  void updateItem({
    required String id,
    required String name,
    required String category,
    required String imageUrl,
    String description = '',
  }) {
    final index = _items.indexWhere((element) => element.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        name: name,
        category: category,
        imageUrl: imageUrl.trim().isEmpty ? _items[index].imageUrl : imageUrl.trim(),
        description: description,
      );
      notifyListeners();
    }
  }

  void deleteItem(String id) {
    _items.removeWhere((element) => element.id == id);
    notifyListeners();
  }
}
