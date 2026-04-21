import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/prescriptions/prescription.dart';
import '../features/prescriptions/prescription_providers.dart';
import '../features/prescriptions/prescription_types.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/prescription_card.dart';
import '../widgets/skeleton_placeholders.dart';
import 'add_update_prescription_screen.dart';

/// Paginated prescriptions with search, filters, and FAB (mirrors lab reports).
class PrescriptionsScreen extends ConsumerStatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  ConsumerState<PrescriptionsScreen> createState() =>
      _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends ConsumerState<PrescriptionsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _loadMorePostFrameScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(prescriptionsListProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent - pos.pixels < 320) {
      if (_loadMorePostFrameScheduled) return;
      _loadMorePostFrameScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMorePostFrameScheduled = false;
        if (!mounted) return;
        ref.read(prescriptionsListProvider.notifier).loadMore();
      });
    }
  }

  Future<void> _openFilters() async {
    final state = ref.read(prescriptionsListProvider);
    String? type = state.prescriptionTypeFilter;
    DateTime? from = state.prescribedDateFrom;
    DateTime? to = state.prescribedDateTo;
    final scheme = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.seed.withValues(alpha: 0.18),
                          AppColors.statBlue.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Refine prescriptions',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Filter by type and prescribed date range.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String?>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Prescription type',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All types'),
                      ),
                      ...PrescriptionTypes.all.map(
                        (t) =>
                            DropdownMenuItem<String?>(value: t, child: Text(t)),
                      ),
                    ],
                    onChanged: (v) => setModal(() => type = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FilterDateTile(
                    label: 'Prescribed date from',
                    value: from == null
                        ? 'Any'
                        : MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(from!),
                    icon: Icons.calendar_today_outlined,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: from ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime(DateTime.now().year + 2),
                      );
                      if (d != null) setModal(() => from = d);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _FilterDateTile(
                    label: 'Prescribed date to',
                    value: to == null
                        ? 'Any'
                        : MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(to!),
                    icon: Icons.event_note_outlined,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: to ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime(DateTime.now().year + 2),
                      );
                      if (d != null) setModal(() => to = d);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(prescriptionsListProvider.notifier)
                          .applyFilters(
                            prescriptionType: type,
                            prescribedDateFrom: from,
                            prescribedDateTo: to,
                            clearPrescriptionType: type == null,
                            clearPrescribedDateFrom: from == null,
                            clearPrescribedDateTo: to == null,
                          );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply'),
                  ),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(prescriptionsListProvider.notifier)
                          .clearAllFilters();
                      _searchController.clear();
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

  Future<void> _confirmDelete(Prescription p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete prescription?'),
        content: Text('Remove "${p.title}"? This cannot be undone.'),
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
    if (ok == true && context.mounted) {
      await ref.read(prescriptionsListProvider.notifier).deletePrescription(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prescriptionsListProvider);
    final notifier = ref.read(prescriptionsListProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = Color.lerp(
      Theme.of(context).scaffoldBackgroundColor,
      AppColors.seed,
      0.03,
    );
    final hasFilters =
        state.prescriptionTypeFilter != null ||
        state.prescribedDateFrom != null ||
        state.prescribedDateTo != null;
    final activeFilterCount = [
      state.prescriptionTypeFilter,
      state.prescribedDateFrom,
      state.prescribedDateTo,
    ].where((value) => value != null).length;

    ref.listen<PrescriptionsListUiState>(prescriptionsListProvider, (
      prev,
      next,
    ) {
      if (next.error != null && next.error != prev?.error) {
        final message = next.error!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        });
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Prescriptions'),
        actions: [
          IconButton(
            tooltip: hasFilters
                ? 'Filters active: $activeFilterCount'
                : 'Filters',
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
                        border: Border.all(color: scheme.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openFilters,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const AddUpdatePrescriptionScreen(),
            ),
          );
          if (created == true && context.mounted) {
            notifier.refresh();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add prescription'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Color.lerp(scheme.surface, AppColors.seed, 0.03),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
                    'Your prescriptions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    state.items.isEmpty
                        ? 'Add your first prescription to keep a personal record.'
                        : '${state.items.length} prescription${state.items.length == 1 ? '' : 's'} listed.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: CustomSearchField(
                          controller: _searchController,
                          hint: 'Search by title',
                          onChanged: notifier.setSearchDraft,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: _openFilters,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          side: BorderSide(color: scheme.outlineVariant),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        icon: Icon(
                          hasFilters
                              ? Icons.filter_alt_rounded
                              : Icons.tune_rounded,
                        ),
                        label: Text(
                          hasFilters ? '$activeFilterCount active' : 'Filter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (state.prescriptionTypeFilter != null)
                    Chip(
                      label: Text(state.prescriptionTypeFilter!),
                      onDeleted: () =>
                          notifier.applyFilters(clearPrescriptionType: true),
                    ),
                  if (state.prescribedDateFrom != null)
                    Chip(
                      label: Text(
                        'From ${MaterialLocalizations.of(context).formatMediumDate(state.prescribedDateFrom!)}',
                      ),
                      onDeleted: () =>
                          notifier.applyFilters(clearPrescribedDateFrom: true),
                    ),
                  if (state.prescribedDateTo != null)
                    Chip(
                      label: Text(
                        'To ${MaterialLocalizations.of(context).formatMediumDate(state.prescribedDateTo!)}',
                      ),
                      onDeleted: () =>
                          notifier.applyFilters(clearPrescribedDateTo: true),
                    ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.refresh(),
              child: _buildBody(context, state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PrescriptionsListUiState state,
    PrescriptionsListNotifier notifier,
  ) {
    if (state.isInitialLoading && state.items.isEmpty) {
      return const ListLoadingSkeleton();
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: EmptyStateWidget(
              title: 'No prescriptions yet',
              subtitle:
                  'Save medication names, dates, and photos or PDFs in one place.',
              icon: Icons.medication_outlined,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        88,
      ),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const SkeletonLoadMoreFooter();
        }
        final p = state.items[index];
        return PrescriptionCard(
          prescription: p,
          isDeleting: state.deletingPrescriptionId == p.id,
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => AddUpdatePrescriptionScreen(existing: p),
              ),
            );
            if (changed == true && context.mounted) {
              notifier.refresh();
            }
          },
          onDelete: () => _confirmDelete(p),
        );
      },
    );
  }
}

class _FilterDateTile extends StatelessWidget {
  const _FilterDateTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: scheme.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
