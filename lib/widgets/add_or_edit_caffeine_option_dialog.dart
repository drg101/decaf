import 'package:decaf/providers/caffeine_options_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddOrEditCaffeineOptionDialog extends ConsumerStatefulWidget {
  final CaffeineOption? option;

  const AddOrEditCaffeineOptionDialog({super.key, this.option});

  @override
  ConsumerState<AddOrEditCaffeineOptionDialog> createState() => _AddOrEditCaffeineOptionDialogState();
}

class _AddOrEditCaffeineOptionDialogState extends ConsumerState<AddOrEditCaffeineOptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _emoji;
  late double _caffeineAmount;

  @override
  void initState() {
    super.initState();
    _name = widget.option?.name ?? '';
    _emoji = widget.option?.emoji ?? '';
    _caffeineAmount = widget.option?.caffeineAmount ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.option == null ? 'Add Option' : 'Edit Option'),
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
            TextFormField(
              initialValue: _caffeineAmount.toString(),
              decoration: const InputDecoration(labelText: 'Caffeine Amount (mg)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onSaved: (value) => _caffeineAmount = double.parse(value!),
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
              final newOption = CaffeineOption(
                id: widget.option?.id,
                name: _name,
                emoji: _emoji,
                caffeineAmount: _caffeineAmount,
              );
              if (widget.option == null) {
                ref.read(caffeineOptionsProvider.notifier).addOption(newOption);
              } else {
                ref.read(caffeineOptionsProvider.notifier).updateOption(newOption);
              }
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.option == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
