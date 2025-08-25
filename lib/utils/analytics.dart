import 'package:beaverlog_flutter/beaverlog_flutter.dart';

enum AnalyticsEvent {
  addCaffeineEntry,
  deleteCaffeineEntry,
  recordSymptomIntensity,
  toggleCaffeineOption,
  addCustomCaffeineOption,
  editCaffeineOption,
  deleteCaffeineOption,
  toggleSymptom,
  addCustomSymptom,
  editSymptom,
  deleteSymptom,
  toggleChartVisibility,
  navigateDate,
  requestAppReview,
  resetAccount,
}

class Analytics {
  static void track(AnalyticsEvent event, [Map<String, Object>? metadata]) {
    BeaverLog().event(
      eventName: event.name,
      meta: metadata,
    );
  }
}