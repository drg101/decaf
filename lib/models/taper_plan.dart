import 'package:decaf/models/taper_preset.dart';

class TaperPlan {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final double startingAmount;
  final TaperPreset preset;
  final Map<String, dynamic> presetConfig;
  final DateTime createdAt;
  final bool isActive;

  TaperPlan({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.startingAmount,
    required this.preset,
    this.presetConfig = const {},
    required this.createdAt,
    this.isActive = true,
  });

  int get totalDays => endDate.difference(startDate).inDays + 1;

  Map<String, dynamic> toJson() => {
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
        'startingAmount': startingAmount,
        'preset': preset.name,
        'presetConfig': presetConfig,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isActive': isActive,
      };

  static TaperPlan fromJson(Map<String, dynamic> json, String id) => TaperPlan(
        id: id,
        startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] as int),
        endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] as int),
        startingAmount: (json['startingAmount'] as num).toDouble(),
        preset: TaperPreset.values.byName(json['preset'] as String),
        presetConfig: Map<String, dynamic>.from(json['presetConfig'] as Map? ?? {}),
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        isActive: json['isActive'] as bool? ?? true,
      );

  TaperPlan copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    double? startingAmount,
    TaperPreset? preset,
    Map<String, dynamic>? presetConfig,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return TaperPlan(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startingAmount: startingAmount ?? this.startingAmount,
      preset: preset ?? this.preset,
      presetConfig: presetConfig ?? this.presetConfig,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}