import 'package:decaf/providers/events_provider.dart';
import 'package:decaf/providers/symptoms_provider.dart';

class SymptomScores {
  final double positiveScore;
  final double negativeScore;
  final int positiveCount;
  final int negativeCount;

  const SymptomScores({
    required this.positiveScore,
    required this.negativeScore,
    required this.positiveCount,
    required this.negativeCount,
  });
}

class SymptomCalculator {
  static SymptomScores calculateDailyScores({
    required List<Event> events,
    required List<Symptom> symptoms,
    required DateTime date,
  }) {
    final positiveSymptoms = symptoms
        .where((s) => s.connotation == SymptomConnotation.positive && s.enabled)
        .toList();
    final negativeSymptoms = symptoms
        .where((s) => s.connotation == SymptomConnotation.negative && s.enabled)
        .toList();

    double positiveSum = 0;
    int positiveCount = 0;
    double negativeSum = 0;
    int negativeCount = 0;

    // Calculate positive symptoms
    for (final symptom in positiveSymptoms) {
      final symptomEvents = _getSymptomEventsForDate(events, symptom.name, date);
      if (symptomEvents.isNotEmpty && symptomEvents.first.value > 0) {
        positiveSum += symptomEvents.first.value - 1;
        positiveCount++;
      }
    }

    // Calculate negative symptoms
    for (final symptom in negativeSymptoms) {
      final symptomEvents = _getSymptomEventsForDate(events, symptom.name, date);
      if (symptomEvents.isNotEmpty && symptomEvents.first.value > 0) {
        negativeSum += symptomEvents.first.value - 1;
        negativeCount++;
      }
    }

    final positiveScore = positiveCount > 0 ? positiveSum / positiveCount : 0.0;
    final negativeScore = negativeCount > 0 ? negativeSum / negativeCount : 0.0;

    return SymptomScores(
      positiveScore: positiveScore,
      negativeScore: negativeScore,
      positiveCount: positiveCount,
      negativeCount: negativeCount,
    );
  }

  static List<Event> _getSymptomEventsForDate(
    List<Event> events,
    String symptomName,
    DateTime date,
  ) {
    return events.where((event) {
      final eventDate = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
      final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
      final targetDay = DateTime(date.year, date.month, date.day);
      
      return event.type == EventType.symptom &&
          event.name == symptomName &&
          eventDay == targetDay;
    }).toList();
  }
}