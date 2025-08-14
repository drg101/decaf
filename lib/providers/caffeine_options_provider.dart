import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  final appDir = await getApplicationDocumentsDirectory();
  final dbPath = join(appDir.path, 'caffeineOptions.db');
  final dbFactory = databaseFactoryIo;
  return await dbFactory.openDatabase(dbPath);
});

class CaffeineOption {
  final int? id;
  final String name;
  final String emoji;
  final double caffeineAmount;

  CaffeineOption({
    this.id,
    required this.name,
    required this.emoji,
    required this.caffeineAmount,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'emoji': emoji, 'caffeineAmount': caffeineAmount};
  }

  static CaffeineOption fromMap(Map<String, dynamic> map, int id) {
    return CaffeineOption(
      id: id,
      name: map['name'],
      emoji: map['emoji'],
      caffeineAmount: map['caffeineAmount'],
    );
  }
}

final caffeineOptionsProvider = StateNotifierProvider<
  CaffeineOptionsNotifier,
  AsyncValue<List<CaffeineOption>>
>((ref) {
  return CaffeineOptionsNotifier(ref.watch(databaseProvider));
});

class CaffeineOptionsNotifier
    extends StateNotifier<AsyncValue<List<CaffeineOption>>> {
  final store = intMapStoreFactory.store('caffeine_options');
  AsyncValue<Database> db;

  CaffeineOptionsNotifier(this.db) : super(const AsyncValue.loading()) {
    _getOptions();
    _seedDatabase();
  }

  Future<void> _seedDatabase() async {
    await db.whenData((db) async {
      final count = await store.count(db);
      if (count == 0) {
        await store.addAll(db, [
          CaffeineOption(
            name: 'Espresso',
            emoji: '☕',
            caffeineAmount: 60.0,
          ).toMap(),
          CaffeineOption(
            name: 'Coffee',
            emoji: '☕',
            caffeineAmount: 90.0,
          ).toMap(),
          CaffeineOption(
            name: 'Black Tea',
            emoji: '🍵',
            caffeineAmount: 50.0,
          ).toMap(),
          CaffeineOption(
            name: 'Green Tea',
            emoji: '🍵',
            caffeineAmount: 30.0,
          ).toMap(),
          CaffeineOption(
            name: 'Cola',
            emoji: '🥤',
            caffeineAmount: 20.0,
          ).toMap(),
          CaffeineOption(
            name: 'Energy Drink',
            emoji: '⚡',
            caffeineAmount: 80.0,
          ).toMap(),
        ]);
        _getOptions();
      }
    });
  }

  Future<void> _getOptions() async {
    db.whenData((db) async {
      final snapshots = await store.find(db);
      final options =
          snapshots.map((snapshot) {
            return CaffeineOption.fromMap(snapshot.value, snapshot.key);
          }).toList();
      state = AsyncValue.data(options);
    });
  }

  Future<void> addOption(CaffeineOption option) async {
    await db.whenData((db) async {
      await store.add(db, option.toMap());
      _getOptions();
    });
  }

  Future<void> updateOption(CaffeineOption option) async {
    await db.whenData((db) async {
      await store.record(option.id!).update(db, option.toMap());
      _getOptions();
    });
  }

  Future<void> deleteOption(int id) async {
    await db.whenData((db) async {
      await store.record(id).delete(db);
      _getOptions();
    });
  }
}
