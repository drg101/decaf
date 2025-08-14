import 'package:decaf/providers/symptoms_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddOrEditSymptomDialog extends ConsumerStatefulWidget {
  final Symptom? symptom;

  const AddOrEditSymptomDialog({super.key, this.symptom});

  @override
  ConsumerState<AddOrEditSymptomDialog> createState() => _AddOrEditSymptomDialogState();
}

class _AddOrEditSymptomDialogState extends ConsumerState<AddOrEditSymptomDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _emoji;

  @override
  void initState() {
    super.initState();
    _name = widget.symptom?.name ?? '';
    _emoji = widget.symptom?.emoji ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.symptom == null ? 'Add Symptom' : 'Edit Symptom'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              onSaved: (value) => _name = value!,
            ),
            TextFormField(
              initialValue: _emoji,
              decoration: const InputDecoration(labelText: 'Emoji'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an emoji';
                }
                return null;
              },
              onSaved: (value) => _emoji = value!,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final newSymptom = Symptom(
                id: widget.symptom?.id,
                name: _name,
                emoji: _emoji,
              );
              if (widget.symptom == null) {
                ref.read(symptomsProvider.notifier).addSymptom(newSymptom);
              } else {
                ref.read(symptomsProvider.notifier).updateSymptom(newSymptom);
              }
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.symptom == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
