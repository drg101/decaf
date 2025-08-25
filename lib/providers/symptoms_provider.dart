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
        // Define default symptoms in arrays for easier management
        final positiveSymptoms = [
          {'name': 'Energy', 'emoji': '⚡', 'enabled': true},
          {'name': 'Mood', 'emoji': '😊', 'enabled': true},
          {'name': 'Sleep Quality', 'emoji': '😴', 'enabled': true},
        ];
        
        final negativeSymptoms = [
          {'name': 'Brain Fog', 'emoji': '🌫️', 'enabled': true},
          {'name': 'Mid Day Crash', 'emoji': '💥', 'enabled': true},
          {'name': 'Anxiety', 'emoji': '😰', 'enabled': true},
        ];
        
        final additionalPositives = [
          {'name': 'Focus', 'emoji': '🎯'},
          {'name': 'Alertness', 'emoji': '👁️'},
          {'name': 'Motivation', 'emoji': '💪'},
          {'name': 'Productivity', 'emoji': '📈'},
          {'name': 'Confidence', 'emoji': '😎'},
          {'name': 'Sociability', 'emoji': '🗣️'},
          {'name': 'Creativity', 'emoji': '🎨'},
          {'name': 'Euphoria', 'emoji': '🥳'},
          {'name': 'Mental Clarity', 'emoji': '🔍'},
          {'name': 'Wakefulness', 'emoji': '👀'},
        ];
        
        final additionalNegatives = [
          {'name': 'Jitters', 'emoji': '🫨'},
          {'name': 'Heart Racing', 'emoji': '💓'},
          {'name': 'Sleep Issues', 'emoji': '😵‍💫'},
          {'name': 'Headache', 'emoji': '🤕'},
          {'name': 'Fatigue', 'emoji': '😪'},
          {'name': 'Stomach Upset', 'emoji': '🤢'},
          {'name': 'Irritability', 'emoji': '😤'},
          {'name': 'Restlessness', 'emoji': '😣'},
          {'name': 'Sweating', 'emoji': '💦'},
          {'name': 'Tremors', 'emoji': '🤲'},
          {'name': 'Dizziness', 'emoji': '😵'},
          {'name': 'Rapid Thoughts', 'emoji': '🧠'},
          {'name': 'Dehydration', 'emoji': '🏜️'},
        ];
        
        // Build the complete list with automatic ordering
        final allSymptoms = <Map<String, dynamic>>[];
        int order = 0;
        
        // Add enabled positive symptoms
        for (final symptom in positiveSymptoms) {
          allSymptoms.add(Symptom(
            name: symptom['name'] as String,
            emoji: symptom['emoji'] as String,
            connotation: SymptomConnotation.positive,
            order: order++,
            enabled: symptom['enabled'] as bool? ?? false,
          ).toMap());
        }
        
        // Add enabled negative symptoms
        for (final symptom in negativeSymptoms) {
          allSymptoms.add(Symptom(
            name: symptom['name'] as String,
            emoji: symptom['emoji'] as String,
            connotation: SymptomConnotation.negative,
            order: order++,
            enabled: symptom['enabled'] as bool? ?? false,
          ).toMap());
        }
        
        // Add additional positive symptoms (disabled by default)
        for (final symptom in additionalPositives) {
          allSymptoms.add(Symptom(
            name: symptom['name'] as String,
            emoji: symptom['emoji'] as String,
            connotation: SymptomConnotation.positive,
            order: order++,
            enabled: false,
          ).toMap());
        }
        
        // Add additional negative symptoms (disabled by default)
        for (final symptom in additionalNegatives) {
          allSymptoms.add(Symptom(
            name: symptom['name'] as String,
            emoji: symptom['emoji'] as String,
            connotation: SymptomConnotation.negative,
            order: order++,
            enabled: false,
          ).toMap());
        }
        
        await store.addAll(db, allSymptoms);
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
