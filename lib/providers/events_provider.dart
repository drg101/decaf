
import 'package:riverpod/riverpod.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

enum EventName {
  caffeine,
  headache,
  brainFog,
  anxiety,
  fatigue,
}

class Event {
  Event({required this.name, required this.value, required this.timestamp});

  final EventName name;
  final double value;
  final int timestamp;

  Map<String, dynamic> toJson() => {
    'name': name.name,
    'value': value,
    'timestamp': timestamp,
  };

  static Event fromJson(Map<String, dynamic> json) => Event(
    name: EventName.values.byName(json['name'] as String),
    value: (json['value'] as num).toDouble(),
    timestamp: json['timestamp'] as int,
  );
}

class EventNotifier extends AsyncNotifier<List<Event>> {
  Database? _db;
  final _store = stringMapStoreFactory.store('events');

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
    return snapshots.map((snapshot) {
      final event = Event.fromJson(snapshot.value);
      return event;
    }).toList();
  }

  Future<void> addEvent(EventName name, double value) async {
    final event = Event(
      name: name,
      value: value,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _store.add(_db!, event.toJson());

    final previousState = await future;
    state = AsyncData([...previousState, event]);
  }
}

final eventsProvider = AsyncNotifierProvider<EventNotifier, List<Event>>(() {
  return EventNotifier();
});
