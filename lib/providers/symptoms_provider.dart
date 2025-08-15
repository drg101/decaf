import 'package:decaf/providers/database_provider.dart';
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
  final int order;
  final bool enabled;

  Symptom({this.id, required this.name, required this.emoji, this.connotation = SymptomConnotation.negative, this.order = 0, this.enabled = true});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emoji': emoji,
      'connotation': connotation.name,
      'order': order,
      'enabled': enabled,
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
      order: map['order'] ?? 0,
      enabled: map['enabled'] ?? true,
    );
  }

  Symptom copyWith({
    int? id,
    String? name,
    String? emoji,
    SymptomConnotation? connotation,
    int? order,
    bool? enabled,
  }) {
    return Symptom(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      connotation: connotation ?? this.connotation,
      order: order ?? this.order,
      enabled: enabled ?? this.enabled,
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
      symptoms.sort((a, b) => a.order.compareTo(b.order));
      state = AsyncValue.data(symptoms);
    });
  }

  Future<void> _seedDatabase() async {
    await db.whenData((db) async {
      final count = await store.count(db);
      if (count == 0) {
        await store.addAll(db, [
          // Common positive effects (enabled by default)
          Symptom(name: 'Alertness', emoji: '👁️', connotation: SymptomConnotation.positive, order: 0, enabled: true).toMap(),
          Symptom(name: 'Focus', emoji: '🎯', connotation: SymptomConnotation.positive, order: 1, enabled: true).toMap(),
          Symptom(name: 'Energy', emoji: '⚡', connotation: SymptomConnotation.positive, order: 2, enabled: true).toMap(),
          Symptom(name: 'Mood', emoji: '😊', connotation: SymptomConnotation.positive, order: 3, enabled: true).toMap(),
          
          // Common negative effects (enabled by default)
          Symptom(name: 'Anxiety', emoji: '😰', connotation: SymptomConnotation.negative, order: 4, enabled: true).toMap(),
          Symptom(name: 'Jitters', emoji: '🫨', connotation: SymptomConnotation.negative, order: 5, enabled: true).toMap(),
          Symptom(name: 'Headache', emoji: '🤕', connotation: SymptomConnotation.negative, order: 6, enabled: true).toMap(),
          Symptom(name: 'Fatigue', emoji: '😴', connotation: SymptomConnotation.negative, order: 7, enabled: true).toMap(),
          
          // Additional positive effects (disabled by default)
          Symptom(name: 'Motivation', emoji: '💪', connotation: SymptomConnotation.positive, order: 8, enabled: false).toMap(),
          Symptom(name: 'Productivity', emoji: '📈', connotation: SymptomConnotation.positive, order: 9, enabled: false).toMap(),
          Symptom(name: 'Confidence', emoji: '😎', connotation: SymptomConnotation.positive, order: 10, enabled: false).toMap(),
          Symptom(name: 'Sociability', emoji: '🗣️', connotation: SymptomConnotation.positive, order: 11, enabled: false).toMap(),
          Symptom(name: 'Creativity', emoji: '🎨', connotation: SymptomConnotation.positive, order: 12, enabled: false).toMap(),
          Symptom(name: 'Euphoria', emoji: '🥳', connotation: SymptomConnotation.positive, order: 13, enabled: false).toMap(),
          Symptom(name: 'Mental Clarity', emoji: '🔍', connotation: SymptomConnotation.positive, order: 14, enabled: false).toMap(),
          Symptom(name: 'Wakefulness', emoji: '👀', connotation: SymptomConnotation.positive, order: 15, enabled: false).toMap(),
          
          // Additional negative effects (disabled by default)
          Symptom(name: 'Heart Racing', emoji: '💓', connotation: SymptomConnotation.negative, order: 16, enabled: false).toMap(),
          Symptom(name: 'Sleep Issues', emoji: '😵‍💫', connotation: SymptomConnotation.negative, order: 17, enabled: false).toMap(),
          Symptom(name: 'Stomach Upset', emoji: '🤢', connotation: SymptomConnotation.negative, order: 18, enabled: false).toMap(),
          Symptom(name: 'Irritability', emoji: '😤', connotation: SymptomConnotation.negative, order: 19, enabled: false).toMap(),
          Symptom(name: 'Restlessness', emoji: '😣', connotation: SymptomConnotation.negative, order: 20, enabled: false).toMap(),
          Symptom(name: 'Sweating', emoji: '💦', connotation: SymptomConnotation.negative, order: 21, enabled: false).toMap(),
          Symptom(name: 'Tremors', emoji: '🤲', connotation: SymptomConnotation.negative, order: 22, enabled: false).toMap(),
          Symptom(name: 'Dizziness', emoji: '😵', connotation: SymptomConnotation.negative, order: 23, enabled: false).toMap(),
          Symptom(name: 'Rapid Thoughts', emoji: '🧠', connotation: SymptomConnotation.negative, order: 24, enabled: false).toMap(),
          Symptom(name: 'Dehydration', emoji: '🏜️', connotation: SymptomConnotation.negative, order: 25, enabled: false).toMap(),
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

  Future<void> reorderSymptoms(List<Symptom> reorderedSymptoms) async {
    await db.whenData((db) async {
      for (int i = 0; i < reorderedSymptoms.length; i++) {
        final symptom = reorderedSymptoms[i].copyWith(order: i);
        await store.record(symptom.id!).update(db, symptom.toMap());
      }
      _getSymptoms();
    });
  }

  Future<void> toggleSymptom(int id, bool enabled) async {
    await db.whenData((db) async {
      final snapshot = await store.record(id).get(db);
      if (snapshot != null) {
        final symptom = Symptom.fromMap(snapshot, id);
        final updatedSymptom = symptom.copyWith(enabled: enabled);
        await store.record(id).update(db, updatedSymptom.toMap());
        _getSymptoms();
      }
    });
  }

  Future<void> resetToDefaults() async {
    await db.whenData((db) async {
      // Clear all existing symptoms
      await store.drop(db);
      
      // Re-seed with default data
      await _seedDatabase();
    });
  }
}
