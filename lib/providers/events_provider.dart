import 'package:decaf/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

enum EventType { caffeine, symptom }

class Event {
  Event({
    required this.id,
    required this.type,
    required this.name,
    required this.value,
    required this.timestamp,
  });

  final String id;
  final EventType type;
  final String name;
  final double value;
  final int timestamp;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        'value': value,
        'timestamp': timestamp,
      };

  static Event fromJson(Map<String, dynamic> json, String id) => Event(
        id: id,
        type: EventType.values.byName(json['type'] as String),
        name: json['name'] as String,
        value: (json['value'] as num).toDouble(),
        timestamp: json['timestamp'] as int,
      );
}

class EventNotifier extends AsyncNotifier<List<Event>> {
  final _store = stringMapStoreFactory.store('events');
  final _uuid = const Uuid();

  @override
  Future<List<Event>> build() async {
    return _loadEvents();
  }

  Future<List<Event>> _loadEvents() async {
    final db = await ref.read(databaseProvider.future);
    final snapshots = await _store.find(db);
    return snapshots
        .map((snapshot) => Event.fromJson(snapshot.value, snapshot.key))
        .toList();
  }

  Future<void> addEvent(
    EventType type,
    String name,
    double value,
    DateTime timestamp,
  ) async {
    final db = await ref.read(databaseProvider.future);
    final eventData = {
      'type': type.name,
      'name': name,
      'value': value,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };

    final newId = _uuid.v4();
    await _store.record(newId).add(db, eventData);

    final newEvent = Event(
      id: newId,
      type: type,
      name: name,
      value: value,
      timestamp: timestamp.millisecondsSinceEpoch,
    );

    final previousState = await future;
    state = AsyncData([...previousState, newEvent]);
  }

  Future<void> updateEvent(Event updatedEvent) async {
    final db = await ref.read(databaseProvider.future);
    await _store.record(updatedEvent.id).put(db, updatedEvent.toJson());
    final previousState = await future;
    state = AsyncData(previousState.map((event) => event.id == updatedEvent.id ? updatedEvent : event).toList());
  }

  Future<void> deleteEvent(String eventId) async {
    final db = await ref.read(databaseProvider.future);
    await _store.record(eventId).delete(db);
    final previousState = await future;
    state = AsyncData(previousState.where((event) => event.id != eventId).toList());
  }

  Future<void> clearAllEvents() async {
    final db = await ref.read(databaseProvider.future);
    await _store.drop(db);
    state = const AsyncData([]);
  }
}

final eventsProvider = AsyncNotifierProvider<EventNotifier, List<Event>>(() {
  return EventNotifier();
});
