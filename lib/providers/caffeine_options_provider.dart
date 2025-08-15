import 'package:decaf/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

class CaffeineOption {
  final int? id;
  final String name;
  final String emoji;
  final double caffeineAmount;
  final int order;
  final bool enabled;

  CaffeineOption({
    this.id,
    required this.name,
    required this.emoji,
    required this.caffeineAmount,
    this.order = 0,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emoji': emoji,
      'caffeineAmount': caffeineAmount,
      'order': order,
      'enabled': enabled,
    };
  }

  static CaffeineOption fromMap(Map<String, dynamic> map, int id) {
    return CaffeineOption(
      id: id,
      name: map['name'],
      emoji: map['emoji'],
      caffeineAmount: map['caffeineAmount'],
      order: map['order'] ?? 0,
      enabled: map['enabled'] ?? true,
    );
  }

  CaffeineOption copyWith({
    int? id,
    String? name,
    String? emoji,
    double? caffeineAmount,
    int? order,
    bool? enabled,
  }) {
    return CaffeineOption(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      caffeineAmount: caffeineAmount ?? this.caffeineAmount,
      order: order ?? this.order,
      enabled: enabled ?? this.enabled,
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
          // Common/Popular options (enabled by default)\
          CaffeineOption(
            name: 'Decaf',
            emoji: '☕',
            caffeineAmount: 3.0,
            order: 0,
            enabled: true,
          ).toMap(),
          CaffeineOption(
            name: 'Cup of Coffee',
            emoji: '☕',
            caffeineAmount: 95.0,
            order: 1,
            enabled: true,
          ).toMap(),
          CaffeineOption(
            name: 'Espresso Shot',
            emoji: '☕',
            caffeineAmount: 63.0,
            order: 2,
            enabled: true,
          ).toMap(),
          CaffeineOption(
            name: 'Green Tea',
            emoji: '🍵',
            caffeineAmount: 28.0,
            order: 3,
            enabled: true,
          ).toMap(),
          CaffeineOption(
            name: 'Black Tea',
            emoji: '🫖',
            caffeineAmount: 47.0,
            order: 4,
            enabled: true,
          ).toMap(),
          CaffeineOption(
            name: 'Energy Drink',
            emoji: '⚡',
            caffeineAmount: 80.0,
            order: 5,
            enabled: true,
          ).toMap(),

          // Coffee variations (disabled by default)
          CaffeineOption(
            name: 'Americano',
            emoji: '☕',
            caffeineAmount: 154.0,
            order: 6,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Latte',
            emoji: '🥛',
            caffeineAmount: 63.0,
            order: 7,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Cappuccino',
            emoji: '☕',
            caffeineAmount: 63.0,
            order: 8,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Macchiato',
            emoji: '☕',
            caffeineAmount: 63.0,
            order: 9,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Mocha',
            emoji: '☕',
            caffeineAmount: 95.0,
            order: 10,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Cold Brew',
            emoji: '🧊',
            caffeineAmount: 200.0,
            order: 11,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Iced Coffee',
            emoji: '🧊',
            caffeineAmount: 95.0,
            order: 12,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'French Press',
            emoji: '☕',
            caffeineAmount: 107.0,
            order: 13,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Pour Over',
            emoji: '☕',
            caffeineAmount: 145.0,
            order: 14,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Drip Coffee',
            emoji: '☕',
            caffeineAmount: 115.0,
            order: 15,
            enabled: false,
          ).toMap(),

          // Tea variations (disabled by default)
          CaffeineOption(
            name: 'Earl Grey',
            emoji: '🫖',
            caffeineAmount: 40.0,
            order: 16,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'White Tea',
            emoji: '🍵',
            caffeineAmount: 15.0,
            order: 17,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Oolong Tea',
            emoji: '🍵',
            caffeineAmount: 37.0,
            order: 18,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Matcha',
            emoji: '🍵',
            caffeineAmount: 70.0,
            order: 19,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Chai Tea',
            emoji: '🫖',
            caffeineAmount: 50.0,
            order: 20,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Iced Tea',
            emoji: '🧊',
            caffeineAmount: 47.0,
            order: 21,
            enabled: false,
          ).toMap(),

          // Energy drinks & supplements (disabled by default)
          CaffeineOption(
            name: 'Red Bull',
            emoji: '🪽',
            caffeineAmount: 80.0,
            order: 22,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Monster',
            emoji: '👹',
            caffeineAmount: 160.0,
            order: 23,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Bang Energy',
            emoji: '💥',
            caffeineAmount: 300.0,
            order: 24,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Pre-workout',
            emoji: '💪',
            caffeineAmount: 150.0,
            order: 25,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Caffeine Pill',
            emoji: '💊',
            caffeineAmount: 200.0,
            order: 26,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: '5-Hour Energy',
            emoji: '⚡',
            caffeineAmount: 200.0,
            order: 27,
            enabled: false,
          ).toMap(),

          // Sodas (disabled by default)
          CaffeineOption(
            name: 'Coke',
            emoji: '🥤',
            caffeineAmount: 34.0,
            order: 28,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Pepsi',
            emoji: '🥤',
            caffeineAmount: 38.0,
            order: 29,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Dr Pepper',
            emoji: '🥤',
            caffeineAmount: 41.0,
            order: 30,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Mountain Dew',
            emoji: '🥤',
            caffeineAmount: 54.0,
            order: 31,
            enabled: false,
          ).toMap(),

          // Chocolate & others (disabled by default)
          CaffeineOption(
            name: 'Dark Chocolate',
            emoji: '🍫',
            caffeineAmount: 12.0,
            order: 32,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Milk Chocolate',
            emoji: '🍫',
            caffeineAmount: 6.0,
            order: 33,
            enabled: false,
          ).toMap(),
          CaffeineOption(
            name: 'Coffee Ice Cream',
            emoji: '🍨',
            caffeineAmount: 30.0,
            order: 34,
            enabled: false,
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
      options.sort((a, b) => a.order.compareTo(b.order));
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

  Future<void> reorderOptions(List<CaffeineOption> reorderedOptions) async {
    await db.whenData((db) async {
      for (int i = 0; i < reorderedOptions.length; i++) {
        final option = reorderedOptions[i].copyWith(order: i);
        await store.record(option.id!).update(db, option.toMap());
      }
      _getOptions();
    });
  }

  Future<void> toggleOption(int id, bool enabled) async {
    await db.whenData((db) async {
      final snapshot = await store.record(id).get(db);
      if (snapshot != null) {
        final option = CaffeineOption.fromMap(snapshot, id);
        final updatedOption = option.copyWith(enabled: enabled);
        await store.record(id).update(db, updatedOption.toMap());
        _getOptions();
      }
    });
  }

  Future<void> resetToDefaults() async {
    await db.whenData((db) async {
      // Clear all existing options
      await store.drop(db);

      // Re-seed with default data
      await _seedDatabase();
    });
  }
}
