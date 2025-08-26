import 'package:decaf/models/taper_plan.dart';
import 'package:decaf/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

class TaperPlanNotifier extends AsyncNotifier<TaperPlan?> {
  final _store = stringMapStoreFactory.store('taper_plans');
  final _uuid = const Uuid();

  @override
  Future<TaperPlan?> build() async {
    return _loadActivePlan();
  }

  Future<TaperPlan?> _loadActivePlan() async {
    final db = await ref.read(databaseProvider.future);
    final snapshots = await _store.find(db);
    
    // Find the most recent active plan
    final activePlans = snapshots
        .map((snapshot) => TaperPlan.fromJson(snapshot.value, snapshot.key))
        .where((plan) => plan.isActive)
        .toList();
    
    if (activePlans.isEmpty) return null;
    
    // Sort by creation date and return the most recent
    activePlans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return activePlans.first;
  }

  Future<void> createPlan(TaperPlan plan) async {
    final db = await ref.read(databaseProvider.future);
    
    // Deactivate any existing active plans
    await _deactivateAllPlans();
    
    // Create new plan with generated ID if needed
    final newPlan = plan.id.isEmpty 
        ? plan.copyWith(id: _uuid.v4())
        : plan;
    
    await _store.record(newPlan.id).put(db, newPlan.toJson());
    state = AsyncData(newPlan);
  }

  Future<void> updatePlan(TaperPlan updatedPlan) async {
    final db = await ref.read(databaseProvider.future);
    await _store.record(updatedPlan.id).put(db, updatedPlan.toJson());
    state = AsyncData(updatedPlan);
  }

  Future<void> deactivateCurrentPlan() async {
    final currentPlan = await future;
    if (currentPlan != null) {
      final deactivatedPlan = currentPlan.copyWith(isActive: false);
      await updatePlan(deactivatedPlan);
      state = const AsyncData(null);
    }
  }

  Future<void> _deactivateAllPlans() async {
    final db = await ref.read(databaseProvider.future);
    final snapshots = await _store.find(db);
    
    for (final snapshot in snapshots) {
      final plan = TaperPlan.fromJson(snapshot.value, snapshot.key);
      if (plan.isActive) {
        final deactivatedPlan = plan.copyWith(isActive: false);
        await _store.record(plan.id).put(db, deactivatedPlan.toJson());
      }
    }
  }

  Future<void> deletePlan(String planId) async {
    final db = await ref.read(databaseProvider.future);
    await _store.record(planId).delete(db);
    
    final currentPlan = await future;
    if (currentPlan?.id == planId) {
      state = const AsyncData(null);
    }
  }

  Future<List<TaperPlan>> getAllPlans() async {
    final db = await ref.read(databaseProvider.future);
    final snapshots = await _store.find(db);
    
    final plans = snapshots
        .map((snapshot) => TaperPlan.fromJson(snapshot.value, snapshot.key))
        .toList();
    
    // Sort by creation date, most recent first
    plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return plans;
  }

  Future<void> clearAllPlans() async {
    final db = await ref.read(databaseProvider.future);
    await _store.drop(db);
    state = const AsyncData(null);
  }
}

final taperPlanProvider = AsyncNotifierProvider<TaperPlanNotifier, TaperPlan?>(() {
  return TaperPlanNotifier();
});