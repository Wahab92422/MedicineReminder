import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/meals/meal_statuses.dart';
import '../features/medicine_logs/medicine_log_entry.dart';
import '../features/medicine_logs/medicine_log_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/skeleton_placeholders.dart';
import '../widgets/medicine_log_entry_card.dart';
import 'add_update_medicine_log_screen.dart';

class MedicineLogsScreen extends ConsumerStatefulWidget {
  const MedicineLogsScreen({super.key});

  @override
  ConsumerState<MedicineLogsScreen> createState() => _MedicineLogsScreenState();
}

class _MedicineLogsScreenState extends ConsumerState<MedicineLogsScreen> {
  String? _statusFilter;
  String? _deletingEntryId;

  Future<void> _confirmDelete(MedicineLogEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medicine log?'),
        content: const Text(
          'If this dose was marked Taken, inventory will be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _deletingEntryId = entry.id);
    try {
      final repo = ref.read(medicineLogRepositoryProvider);
      final res = await repo.deleteEntry(userId: uid, entry: entry);
      if (!res.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ?? 'Could not delete medicine log.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
      }
    } finally {
      if (mounted) setState(() => _deletingEntryId = null);
    }
  }

  Future<void> _openFilters() async {
    String? status = _statusFilter;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.sm,
            bottom: MediaQuery.paddingOf(ctx).bottom + AppSpacing.lg,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filter logs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String?>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All statuses'),
                      ),
                      ...MealStatuses.all.map(
                        (item) => DropdownMenuItem<String?>(
                          value: item,
                          child: Text(item),
                        ),
                      ),
                    ],
                    onChanged: (value) => setModal(() => status = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      setState(() => _statusFilter = status);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _statusFilter = null);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _refresh(String uid) async {
    ref.invalidate(medicineLogsStreamProvider(uid));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final logsAsync = ref.watch(medicineLogsStreamProvider(uid));
    final filteredItems = logsAsync.maybeWhen(
      data: _applyFilters,
      orElse: () => <MedicineLogEntry>[],
    );
    final hasFilters = _statusFilter != null;
    final backgroundColor = Color.lerp(
      Theme.of(context).scaffoldBackgroundColor,
      AppColors.statBlue,
      0.03,
    );

    final entryCount = logsAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Medicine log'),
        actions: [
          IconButton(
            tooltip: hasFilters ? 'Filter active' : 'Filters',
            onPressed: _openFilters,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list_rounded),
                if (hasFilters)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.statGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => const AddUpdateMedicineLogScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log dose'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: _MedicineLogsOverviewCard(entryCount: entryCount),
          ),
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(_statusFilter!),
                  onDeleted: () => setState(() => _statusFilter = null),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refresh(uid),
              child: _buildBody(context, logsAsync, filteredItems, uid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<MedicineLogEntry>> logsAsync,
    List<MedicineLogEntry> filteredItems,
    String uid,
  ) {
    return logsAsync.when(
      loading: () => const ListLoadingSkeleton(),
      error: (e, _) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.4,
            child: Center(child: Text('Could not load logs: $e')),
          ),
        ],
      ),
      data: (items) {
        if (items.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.5,
                child: EmptyStateWidget(
                  title: 'No dose logs yet',
                  subtitle:
                      'Log doses from your inventory with Taken, Missed, or Scheduled. Taken reduces stock.',
                  icon: Icons.medication_outlined,
                ),
              ),
            ],
          );
        }

        if (filteredItems.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 280,
                child: EmptyStateWidget(
                  title: 'No logs match this filter',
                  subtitle: 'Try another status.',
                  icon: Icons.filter_list_off_rounded,
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            88,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return MedicineLogEntryCard(
              entry: item,
              isDeleting: _deletingEntryId == item.id,
              onTap: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => AddUpdateMedicineLogScreen(existing: item),
                  ),
                );
              },
              onDelete: () => _confirmDelete(item),
            );
          },
        );
      },
    );
  }

  List<MedicineLogEntry> _applyFilters(List<MedicineLogEntry> items) {
    if (_statusFilter == null) return items;
    return items.where((e) => e.status == _statusFilter).toList();
  }
}

class _MedicineLogsOverviewCard extends StatelessWidget {
  const _MedicineLogsOverviewCard({required this.entryCount});

  final int entryCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Color.lerp(scheme.surface, AppColors.statBlue, 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track doses from inventory',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            entryCount == 0
                ? 'Add a log to record taken, missed, or scheduled doses.'
                : '$entryCount log${entryCount == 1 ? '' : 's'}. Taken doses update inventory automatically.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
