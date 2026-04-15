import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/surgical_history/surgical_history_model.dart';
import '../features/surgical_history/surgical_history_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/surgical_history_card.dart';
import 'add_surgical_history_screen.dart';

class SurgicalHistoryScreen extends ConsumerWidget {
  const SurgicalHistoryScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this record?'),
        content: const Text(
          'This surgical history entry will be removed permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SurgicalHistoryRecord r,
  ) async {
    if (!await _confirmDelete(context) || !context.mounted) return;
    try {
      await ref.read(surgicalHistoryControllerProvider).delete(r.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(surgicalHistoryStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Surgical history')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const AddSurgicalHistoryScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add procedure'),
      ),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.local_hospital_outlined,
              title: 'No surgical history',
              subtitle:
                  'Record past procedures, dates, facilities, and operative notes.',
              actionLabel: 'Add procedure',
              onAction: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AddSurgicalHistoryScreen(),
                  ),
                );
              },
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 88),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final r = list[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: SurgicalHistoryCard(
                  record: r,
                  onEdit: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AddSurgicalHistoryScreen(existing: r),
                      ),
                    );
                  },
                  onDelete: () => _delete(context, ref, r),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load surgical history',
          subtitle: e.toString(),
        ),
      ),
    );
  }
}
