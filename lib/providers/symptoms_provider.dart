import 'package:decaf/providers/caffeine_options_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

final symptomsProvider = StateNotifierProvider<SymptomsNotifier, AsyncValue<List<Symptom>>>((ref) {
  return SymptomsNotifier(ref.watch(databaseProvider));
});

class Symptom {
  final int? id;
  final String name;
  final String emoji;

  Symptom({this.id, required this.name, required this.emoji});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emoji': emoji,
    };
  }

  static Symptom fromMap(Map<String, dynamic> map, int id) {
    return Symptom(
      id: id,
      name: map['name'],
      emoji: map['emoji'],
    );
  }
}

class SymptomsNotifier extends StateNotifier<AsyncValue<List<Symptom>>> {
  final store = intMapStoreFactory.store('symptoms');
  AsyncValue<Database> db;

  SymptomsNotifier(this.db) : super(const AsyncValue.loading()) {
    _getSymptoms();
    _seedDatabase();
  }

  Future<void> _getSymptoms() async {
    db.whenData((db) async {
      final snapshots = await store.find(db);
      final symptoms = snapshots.map((snapshot) {
        return Symptom.fromMap(snapshot.value, snapshot.key);
      }).toList();
      state = AsyncValue.data(symptoms);
    });
  }

  Future<void> _seedDatabase() async {
    await db.whenData((db) async {
      final count = await store.count(db);
      if (count == 0) {
        await store.addAll(db, [
          Symptom(name: 'Anxiety', emoji: '😥').toMap(),
          Symptom(name: 'Headache', emoji: '🤕').toMap(),
          Symptom(name: 'Fatigue', emoji: '😴').toMap(),
          Symptom(name: 'Jitters', emoji: '🥴').toMap(),
        ]);
        _getSymptoms();
      }
    });
  }

  Future<void> addSymptom(Symptom symptom) async {
    await db.whenData((db) async {
      await store.add(db, symptom.toMap());
      _getSymptoms();
    });
  }

  Future<void> updateSymptom(Symptom symptom) async {
    await db.whenData((db) async {
      await store.record(symptom.id!).update(db, symptom.toMap());
      _getSymptoms();
    });
  }

  Future<void> deleteSymptom(int id) async {
    await db.whenData((db) async {
      await store.record(id).delete(db);
      _getSymptoms();
    });
  }
}
