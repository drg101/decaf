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
          return ListView.builder(
            itemCount: symptoms.length,
            itemBuilder: (context, index) {
              final symptom = symptoms[index];
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
            },
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
}
