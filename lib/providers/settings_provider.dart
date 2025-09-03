import 'package:decaf/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

class AppSettings {
  final bool taperPlanningEnabled;
  final DateTime? firstAppUsage;
  final bool feedbackPopupShown;

  const AppSettings({
    this.taperPlanningEnabled = false,
    this.firstAppUsage,
    this.feedbackPopupShown = false,
  });

  Map<String, dynamic> toJson() => {
        'taperPlanningEnabled': taperPlanningEnabled,
        'firstAppUsage': firstAppUsage?.millisecondsSinceEpoch,
        'feedbackPopupShown': feedbackPopupShown,
      };

  static AppSettings fromJson(Map<String, dynamic>? json) => AppSettings(
        taperPlanningEnabled: json?['taperPlanningEnabled'] as bool? ?? false,
        firstAppUsage: json?['firstAppUsage'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(json!['firstAppUsage'] as int)
            : null,
        feedbackPopupShown: json?['feedbackPopupShown'] as bool? ?? false,
      );

  AppSettings copyWith({
    bool? taperPlanningEnabled,
    DateTime? firstAppUsage,
    bool? feedbackPopupShown,
  }) {
    return AppSettings(
      taperPlanningEnabled: taperPlanningEnabled ?? this.taperPlanningEnabled,
      firstAppUsage: firstAppUsage ?? this.firstAppUsage,
      feedbackPopupShown: feedbackPopupShown ?? this.feedbackPopupShown,
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

  Future<void> recordFirstAppUsage() async {
    final currentSettings = await future;
    if (currentSettings.firstAppUsage == null) {
      final newSettings = currentSettings.copyWith(
        firstAppUsage: DateTime.now(),
      );
      await _saveSettings(newSettings);
      state = AsyncData(newSettings);
    }
  }

  Future<void> markFeedbackPopupShown() async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(
      feedbackPopupShown: true,
    );
    await _saveSettings(newSettings);
    state = AsyncData(newSettings);
  }

  bool shouldShowFeedbackPopup(List<dynamic> events) {
    final settings = state.value;
    if (settings == null) return false;
    
    // Don't show if already shown
    if (settings.feedbackPopupShown) return false;
    
    // Don't show if no first usage recorded
    if (settings.firstAppUsage == null) return false;
    
    // Check if it's been at least 1 full day since first usage
    final daysSinceFirst = DateTime.now().difference(settings.firstAppUsage!).inDays;
    if (daysSinceFirst < 1) return false;
    
    // Check if user has added caffeine events
    final caffeineEvents = events.where((event) => 
      event.toString().contains('caffeine') || event.toString().contains('EventType.caffeine')
    ).toList();
    
    return caffeineEvents.isNotEmpty;
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});