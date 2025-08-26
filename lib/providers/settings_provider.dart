import 'package:decaf/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

class AppSettings {
  final bool taperPlanningEnabled;

  const AppSettings({
    this.taperPlanningEnabled = false,
  });

  Map<String, dynamic> toJson() => {
        'taperPlanningEnabled': taperPlanningEnabled,
      };

  static AppSettings fromJson(Map<String, dynamic>? json) => AppSettings(
        taperPlanningEnabled: json?['taperPlanningEnabled'] as bool? ?? false,
      );

  AppSettings copyWith({
    bool? taperPlanningEnabled,
  }) {
    return AppSettings(
      taperPlanningEnabled: taperPlanningEnabled ?? this.taperPlanningEnabled,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  final _store = stringMapStoreFactory.store('settings');
  static const String _settingsKey = 'app_settings';

  @override
  Future<AppSettings> build() async {
    return _loadSettings();
  }

  Future<AppSettings> _loadSettings() async {
    final db = await ref.read(databaseProvider.future);
    final snapshot = await _store.record(_settingsKey).get(db);
    return AppSettings.fromJson(snapshot);
  }

  Future<void> _saveSettings(AppSettings settings) async {
    final db = await ref.read(databaseProvider.future);
    await _store.record(_settingsKey).put(db, settings.toJson());
  }

  Future<void> enableTaperPlanning() async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(taperPlanningEnabled: true);
    await _saveSettings(newSettings);
    state = AsyncData(newSettings);
  }

  Future<void> disableTaperPlanning() async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(taperPlanningEnabled: false);
    await _saveSettings(newSettings);
    state = AsyncData(newSettings);
  }

  Future<void> toggleTaperPlanning() async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(
      taperPlanningEnabled: !currentSettings.taperPlanningEnabled,
    );
    await _saveSettings(newSettings);
    state = AsyncData(newSettings);
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});