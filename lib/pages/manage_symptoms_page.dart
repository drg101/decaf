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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (positiveSymptoms.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Positive Effects',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...positiveSymptoms.map((symptom) => _buildSymptomTile(context, ref, symptom)),
                ],
                if (negativeSymptoms.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Negative Effects',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...negativeSymptoms.map((symptom) => _buildSymptomTile(context, ref, symptom)),
                ],
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

  Widget _buildSymptomTile(BuildContext context, WidgetRef ref, Symptom symptom) {
    return ListTile(
      leading: Text(symptom.emoji, style: const TextStyle(fontSize: 24)),
      title: Text(symptom.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
