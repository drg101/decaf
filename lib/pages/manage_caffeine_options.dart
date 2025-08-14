
import 'package:decaf/providers/caffeine_options_provider.dart';
import 'package:decaf/widgets/add_or_edit_caffeine_option_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManageCaffeineOptionsPage extends ConsumerWidget {
  const ManageCaffeineOptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(caffeineOptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Caffeine Options'),
      ),
      body: options.when(
        data: (options) {
          return ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return ListTile(
                leading: Text(option.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(option.name),
                subtitle: Text('${option.caffeineAmount}mg'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddOrEditCaffeineOptionDialog(option: option),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        ref.read(caffeineOptionsProvider.notifier).deleteOption(option.id!);
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
            builder: (context) => const AddOrEditCaffeineOptionDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
