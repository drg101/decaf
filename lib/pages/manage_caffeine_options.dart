
import 'package:decaf/providers/caffeine_options_provider.dart';
import 'package:decaf/utils/analytics.dart';
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
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: options.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final reorderedOptions = List<CaffeineOption>.from(options);
              final option = reorderedOptions.removeAt(oldIndex);
              reorderedOptions.insert(newIndex, option);
              ref.read(caffeineOptionsProvider.notifier).reorderOptions(reorderedOptions);
            },
            itemBuilder: (context, index) {
              final option = options[index];
              return ListTile(
                key: ValueKey(option.id),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drag_handle, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(option.emoji, style: const TextStyle(fontSize: 24)),
                  ],
                ),
                title: Text(
                  option.name,
                  style: TextStyle(
                    color: option.enabled ? null : Colors.grey,
                    fontWeight: option.enabled ? FontWeight.normal : FontWeight.w300,
                  ),
                ),
                subtitle: Text(
                  '${option.caffeineAmount}mg',
                  style: TextStyle(
                    color: option.enabled ? null : Colors.grey,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: option.enabled,
                      onChanged: (value) {
                        Analytics.track(
                          AnalyticsEvent.toggleCaffeineOption,
                          {
                            'option_name': option.name,
                            'enabled': value,
                            'amount': option.caffeineAmount,
                          },
                        );
                        ref.read(caffeineOptionsProvider.notifier).toggleOption(option.id!, value);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Analytics.track(
                          AnalyticsEvent.editCaffeineOption,
                          {
                            'option_name': option.name,
                            'amount': option.caffeineAmount,
                          },
                        );
                        showDialog(
                          context: context,
                          builder: (context) => AddOrEditCaffeineOptionDialog(option: option),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        Analytics.track(
                          AnalyticsEvent.deleteCaffeineOption,
                          {
                            'option_name': option.name,
                            'amount': option.caffeineAmount,
                          },
                        );
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
          Analytics.track(AnalyticsEvent.addCustomCaffeineOption);
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
