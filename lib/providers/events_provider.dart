import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

enum EventType { caffeine, headache, brainFog, anxiety, fatigue }

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
  Database? _db;
  final _store = stringMapStoreFactory.store('events');
  final _uuid = const Uuid();

  @override
  Future<List<Event>> build() async {
    await _initDb();
    return _loadEvents();
  }

  Future<void> _initDb() async {
    if (_db != null) return;
    final appDir = await getApplicationDocumentsDirectory();
    await appDir.create(recursive: true);
    final dbPath = join(appDir.path, 'events.db');
    _db = await databaseFactoryIo.openDatabase(dbPath);
  }

  Future<List<Event>> _loadEvents() async {
    final snapshots = await _store.find(_db!);
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
    final eventData = {
      'type': type.name,
      'name': name,
      'value': value,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };

    final newId = _uuid.v4();
    await _store.record(newId).add(_db!, eventData);

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
    await _store.record(updatedEvent.id).put(_db!, updatedEvent.toJson());
    final previousState = await future;
    state = AsyncData(previousState.map((event) => event.id == updatedEvent.id ? updatedEvent : event).toList());
  }

  Future<void> deleteEvent(String eventId) async {
    await _store.record(eventId).delete(_db!);
    final previousState = await future;
    state = AsyncData(previousState.where((event) => event.id != eventId).toList());
  }
}

final eventsProvider = AsyncNotifierProvider<EventNotifier, List<Event>>(() {
  return EventNotifier();
});
