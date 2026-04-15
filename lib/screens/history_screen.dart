import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/history/history_controller.dart';
import '../features/history/history_model.dart';
import '../features/history/widgets/history_entry_dismissible_card.dart';
import '../features/history/widgets/medication_history_add_sheet.dart';
import '../features/history/widgets/medication_history_edit_sheet.dart';
import '../services/date_calendar_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static Future<void> openAddSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => MedicationHistoryAddSheet(
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  static Future<void> openEditSheet(
    BuildContext context,
    WidgetRef ref,
    History record,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => MedicationHistoryEditSheet(
        record: record,
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(medicationHistoryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication history'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openAddSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add record'),
      ),
      body: async.when(
        data: (records) {
          if (records.isEmpty) {
            return EmptyState(
              icon: Icons.history_rounded,
              title: 'No history yet',
              subtitle: 'Mark doses as taken from your list, or add a record manually.',
              actionLabel: 'Add record',
              onAction: () => openAddSheet(context, ref),
            );
          }
          final sections = DateCalendarService.groupByLocalDateKey<History>(
            records,
            (h) => h.createdAt.toLocal(),
          );
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl + 48,
            ),
            itemCount: sections.length,
            itemBuilder: (context, si) {
              final section = sections[si];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: si == 0 ? 0 : AppSpacing.md,
                      bottom: AppSpacing.sm,
                    ),
                    child: Text(
                      DateCalendarService.sectionTitle(section.key),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  ...section.items.map(
                    (h) => HistoryEntryDismissibleCard(
                      record: h,
                      onEdit: () => openEditSheet(context, ref, h),
                      onDelete: () =>
                          ref.read(historyControllerProvider).deleteHistory(h.id),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load history',
          subtitle: e.toString(),
        ),
      ),
    );
  }
}
