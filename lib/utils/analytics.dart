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
  startPlanCreation,
  selectTaperPreset,
  completePlanCreation,
  resetTaperPlan,
  modifyStartingAmount,
  adjustPlanDuration,
  configureStepDown,
  customizeTargets,
  viewActivePlan,
  tapProgressCard,
}

class Analytics {
  static void track(AnalyticsEvent event, [Map<String, Object>? metadata]) {
    BeaverLog().event(
      eventName: event.name,
      meta: metadata,
    );
  }
}