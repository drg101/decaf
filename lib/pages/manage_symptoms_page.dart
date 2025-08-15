import 'package:decaf/constants/colors.dart';
import 'package:decaf/providers/symptoms_provider.dart';
import 'package:decaf/widgets/add_or_edit_symptom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManageSymptomsPage extends ConsumerWidget {
  const ManageSymptomsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptoms = ref.watch(symptomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Symptoms'),
      ),
      body: symptoms.when(
        data: (symptoms) {
          final positiveSymptoms = symptoms.where((s) => s.connotation == SymptomConnotation.positive).toList();
          final negativeSymptoms = symptoms.where((s) => s.connotation == SymptomConnotation.negative).toList();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (positiveSymptoms.isNotEmpty)
                  _buildSymptomCard(
                    context,
                    ref,
                    'Positive Effects',
                    positiveSymptoms,
                    AppColors.positiveEffectLight,
                  ),
                if (positiveSymptoms.isNotEmpty && negativeSymptoms.isNotEmpty)
                  const SizedBox(height: 16),
                if (negativeSymptoms.isNotEmpty)
                  _buildSymptomCard(
                    context,
                    ref,
                    'Negative Effects',
                    negativeSymptoms,
                    AppColors.negativeEffectLight,
                  ),
                if (symptoms.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No symptoms added yet'),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddOrEditSymptomDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSymptomCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<Symptom> symptoms,
    Color backgroundColor,
  ) {
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final reorderedSymptoms = List<Symptom>.from(symptoms);
                final symptom = reorderedSymptoms.removeAt(oldIndex);
                reorderedSymptoms.insert(newIndex, symptom);
                ref.read(symptomsProvider.notifier).reorderSymptoms(reorderedSymptoms);
              },
              children: symptoms.map((symptom) => _buildSymptomTile(context, ref, symptom)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomTile(BuildContext context, WidgetRef ref, Symptom symptom) {
    return ListTile(
      key: ValueKey(symptom.id),
      contentPadding: EdgeInsets.zero,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drag_handle, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(symptom.emoji, style: const TextStyle(fontSize: 24)),
        ],
      ),
      title: Text(
        symptom.name,
        style: TextStyle(
          color: symptom.enabled ? null : Colors.grey,
          fontWeight: symptom.enabled ? FontWeight.normal : FontWeight.w300,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: symptom.enabled,
            onChanged: (value) {
              ref.read(symptomsProvider.notifier).toggleSymptom(symptom.id!, value);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddOrEditSymptomDialog(symptom: symptom),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              ref.read(symptomsProvider.notifier).deleteSymptom(symptom.id!);
            },
          ),
        ],
      ),
    );
  }
}
