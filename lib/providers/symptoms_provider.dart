import 'package:decaf/providers/caffeine_options_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

enum SymptomConnotation { positive, negative }

final symptomsProvider = StateNotifierProvider<SymptomsNotifier, AsyncValue<List<Symptom>>>((ref) {
  return SymptomsNotifier(ref.watch(databaseProvider));
});

class Symptom {
  final int? id;
  final String name;
  final String emoji;
  final SymptomConnotation connotation;

  Symptom({this.id, required this.name, required this.emoji, this.connotation = SymptomConnotation.negative});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emoji': emoji,
      'connotation': connotation.name,
    };
  }

  static Symptom fromMap(Map<String, dynamic> map, int id) {
    return Symptom(
      id: id,
      name: map['name'],
      emoji: map['emoji'],
      connotation: SymptomConnotation.values.firstWhere(
        (e) => e.name == map['connotation'],
        orElse: () => SymptomConnotation.negative,
      ),
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
          Symptom(name: 'Anxiety', emoji: '😥', connotation: SymptomConnotation.negative).toMap(),
          Symptom(name: 'Headache', emoji: '🤕', connotation: SymptomConnotation.negative).toMap(),
          Symptom(name: 'Fatigue', emoji: '😴', connotation: SymptomConnotation.negative).toMap(),
          Symptom(name: 'Jitters', emoji: '🥴', connotation: SymptomConnotation.negative).toMap(),
          Symptom(name: 'Alertness', emoji: '🎯', connotation: SymptomConnotation.positive).toMap(),
          Symptom(name: 'Focus', emoji: '🧠', connotation: SymptomConnotation.positive).toMap(),
          Symptom(name: 'Energy', emoji: '⚡', connotation: SymptomConnotation.positive).toMap(),
          Symptom(name: 'Mood Boost', emoji: '😊', connotation: SymptomConnotation.positive).toMap(),
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
