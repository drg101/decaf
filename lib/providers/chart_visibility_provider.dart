import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChartVisibilityState {
  final bool showCaffeine;
  final bool showPositives;
  final bool showNegatives;

  ChartVisibilityState({
    this.showCaffeine = true,
    this.showPositives = true,
    this.showNegatives = true,
  });

  ChartVisibilityState copyWith({
    bool? showCaffeine,
    bool? showPositives,
    bool? showNegatives,
  }) {
    return ChartVisibilityState(
      showCaffeine: showCaffeine ?? this.showCaffeine,
      showPositives: showPositives ?? this.showPositives,
      showNegatives: showNegatives ?? this.showNegatives,
    );
  }
}

class ChartVisibilityNotifier extends StateNotifier<ChartVisibilityState> {
  ChartVisibilityNotifier() : super(ChartVisibilityState());

  void toggleCaffeine() {
    state = state.copyWith(showCaffeine: !state.showCaffeine);
  }

  void togglePositives() {
    state = state.copyWith(showPositives: !state.showPositives);
  }

  void toggleNegatives() {
    state = state.copyWith(showNegatives: !state.showNegatives);
  }
}

final chartVisibilityProvider = StateNotifierProvider<ChartVisibilityNotifier, ChartVisibilityState>((ref) {
  return ChartVisibilityNotifier();
});