import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/medicine_inventory/medicine_categories.dart';
import '../features/medicine_inventory/medicine_entry.dart';
import '../features/medicine_inventory/medicine_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/medicine_entry_card.dart';
import '../widgets/skeleton_placeholders.dart';
import 'add_update_medicine_screen.dart';

class MedicineInventoryScreen extends ConsumerStatefulWidget {
  const MedicineInventoryScreen({super.key});

  @override
  ConsumerState<MedicineInventoryScreen> createState() =>
      _MedicineInventoryScreenState();
}

class _MedicineInventoryScreenState
    extends ConsumerState<MedicineInventoryScreen> {
  String? _deletingEntryId;

  Future<void> _refresh() async {
    ref.invalidate(medicinesInventoryStreamProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      ref.invalidate(allMedicinesStreamProvider(uid));
    }
  }

  Future<void> _confirmDelete(MedicineEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: const Text('This cannot be undone.'),
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
    if (ok != true || !mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _deletingEntryId = entry.id);
    try {
      final res = await ref
          .read(medicineRepositoryProvider)
          .deleteEntry(userId: uid, entryId: entry.id);
      if (!res.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ?? 'Failed to delete medicine'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    } finally {
      if (mounted) setState(() => _deletingEntryId = null);
    }
  }

  Future<void> _openFilters() async {
    final initial = ref.read(medicineInventoryCategoryFilterProvider);
    String? category = initial;

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
                    'Filter medicines',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Narrow the list by category.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String?>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ...MedicineCategories.all.map(
                        (cat) => DropdownMenuItem<String?>(
                          value: cat,
                          child: Text(cat),
                        ),
                      ),
                    ],
                    onChanged: (value) => setModal(() => category = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(
                            medicineInventoryCategoryFilterProvider.notifier,
                          )
                          .setFilter(category);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply'),
                  ),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(
                            medicineInventoryCategoryFilterProvider.notifier,
                          )
                          .setFilter(null);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Clear all'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicinesInventoryStreamProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final lowStockAsync = ref.watch(lowStockMedicinesProvider(uid));
    final expiringAsync = ref.watch(expiringMedicinesProvider(uid));
    final categoryFilter = ref.watch(medicineInventoryCategoryFilterProvider);
    final hasFilters = categoryFilter != null;

    return Scaffold(
      appBar: const AppScreenHeader(
        title: 'Medicine Inventory',
        subtitle: 'Track and manage your medications.',
        icon: Icons.medication_rounded,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAlertsSection(lowStockAsync, expiringAsync),
              const SizedBox(height: AppSpacing.md),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          ref
                              .read(
                                medicineInventoryNameSearchProvider.notifier,
                              )
                              .setQuery(value.trim().isEmpty ? null : value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search medicines...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      onPressed: _openFilters,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.tune_rounded),
                          if (hasFilters)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: const Text('Filter'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: medicinesAsync.when(
                  loading: () => const InventoryListLoadingSkeleton(),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: Text('Could not load medicines: $e'),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.medication_rounded,
                        title: 'No medicines yet',
                        subtitle:
                            'Start by adding your first medicine to the inventory.',
                        actionLabel: 'Add Medicine',
                        onAction: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute<bool>(
                              builder: (_) =>
                                  const AddUpdateMedicineScreen(existing: null),
                            ),
                          );
                          if (result == true && mounted) await _refresh();
                        },
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final medicine = items[index];
                        return MedicineEntryCard(
                          entry: medicine,
                          isDeleting: _deletingEntryId == medicine.id,
                          onTap: () async {
                            final result = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute<bool>(
                                    builder: (_) => AddUpdateMedicineScreen(
                                      existing: medicine,
                                    ),
                                  ),
                                );
                            if (result == true && mounted) await _refresh();
                          },
                          onDelete: () => _confirmDelete(medicine),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => const AddUpdateMedicineScreen(existing: null),
            ),
          );
          if (result == true && mounted) await _refresh();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildAlertsSection(
    AsyncValue<List<MedicineEntry>> lowStockAsync,
    AsyncValue<List<MedicineEntry>> expiringAsync,
  ) {
    return Column(
      children: [
        lowStockAsync.when(
          data: (medicines) {
            if (medicines.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD).withValues(alpha: 0.4),
                    border: Border.all(color: const Color(0xFFFFD89B)),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: Color(0xFFFFC107),
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Low Stock Alert',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${medicines.length} medicine${medicines.length == 1 ? '' : 's'} running low',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(height: 88, child: InlineFormSkeleton(lines: 2)),
          ),
          error: (e, st) => const SizedBox.shrink(),
        ),
        expiringAsync.when(
          data: (medicines) {
            if (medicines.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ).copyWith(top: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8D7DA).withValues(alpha: 0.4),
                    border: Border.all(color: const Color(0xFFF5C6CB)),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC3545),
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry Alert',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${medicines.length} medicine${medicines.length == 1 ? '' : 's'} expiring soon or expired',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: SizedBox(height: 88, child: InlineFormSkeleton(lines: 2)),
          ),
          error: (e, st) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
