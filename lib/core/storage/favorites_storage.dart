import 'package:hive/hive.dart';
import 'playlist_storage.dart';

class FavoritesStorage {
  static const _boxName = 'toney_favorites';
  static const _listKey = 'list';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  List<PlaylistReference> load() {
    final box = _box;
    if (box == null) return [];
    
    final raw = box.get(_listKey);
    if (raw is! List) return [];

    return raw.map((item) {
      try {
        return PlaylistReference.fromJson(item);
      } catch (_) {
        return null;
      }
    }).whereType<PlaylistReference>().toList();
  }

  Future<void> save(List<PlaylistReference> favorites) async {
    final box = _box;
    if (box == null) return;
    await box.put(_listKey, favorites.map((e) => e.toJson()).toList());
  }
}
