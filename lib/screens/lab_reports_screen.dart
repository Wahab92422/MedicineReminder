import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/labs/lab_report.dart';
import '../features/labs/lab_report_providers.dart';
import '../features/labs/lab_report_types.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/lab_report_card.dart';
import '../widgets/skeleton_placeholders.dart';
import 'add_update_lab_report_screen.dart';

/// Paginated lab reports with search, filters, and FAB.
class LabReportsScreen extends ConsumerStatefulWidget {
  const LabReportsScreen({super.key});

  @override
  ConsumerState<LabReportsScreen> createState() => _LabReportsScreenState();
}

class _LabReportsScreenState extends ConsumerState<LabReportsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _loadMorePostFrameScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(labReportsListProvider.notifier).refresh();
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
        ref.read(labReportsListProvider.notifier).loadMore();
      });
    }
  }

  Future<void> _openFilters() async {
    final state = ref.read(labReportsListProvider);
    String? type = state.reportTypeFilter;
    DateTime? from = state.testDateFrom;
    DateTime? to = state.testDateTo;
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
                                'Refine your reports',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Filter by report type and test date range.',
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
                    decoration: const InputDecoration(labelText: 'Report type'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All types'),
                      ),
                      ...LabReportTypes.all.map(
                        (t) =>
                            DropdownMenuItem<String?>(value: t, child: Text(t)),
                      ),
                    ],
                    onChanged: (v) => setModal(() => type = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FilterDateTile(
                    label: 'Test date from',
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
                    label: 'Test date to',
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
                          .read(labReportsListProvider.notifier)
                          .applyFilters(
                            reportType: type,
                            testDateFrom: from,
                            testDateTo: to,
                            clearReportType: type == null,
                            clearTestDateFrom: from == null,
                            clearTestDateTo: to == null,
                          );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply'),
                  ),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(labReportsListProvider.notifier)
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

  Future<void> _confirmDelete(LabReport report) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete lab report?'),
        content: Text('Remove "${report.title}"? This cannot be undone.'),
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
      await ref.read(labReportsListProvider.notifier).deleteReport(report);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(labReportsListProvider);
    final notifier = ref.read(labReportsListProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = Color.lerp(
      Theme.of(context).scaffoldBackgroundColor,
      AppColors.statBlue,
      0.03,
    );
    final hasFilters =
        state.reportTypeFilter != null ||
        state.testDateFrom != null ||
        state.testDateTo != null;
    final activeFilterCount = [
      state.reportTypeFilter,
      state.testDateFrom,
      state.testDateTo,
    ].where((value) => value != null).length;

    ref.listen<LabReportsListUiState>(labReportsListProvider, (prev, next) {
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
        title: const Text('Lab Reports'),
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
            MaterialPageRoute(builder: (_) => const AddUpdateLabReportScreen()),
          );
          if (created == true && context.mounted) {
            notifier.refresh();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add report'),
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
                color: Color.lerp(scheme.surface, AppColors.statBlue, 0.03),
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
                    'Find and manage your reports',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    state.items.isEmpty
                        ? 'Add your first report to start building your history.'
                        : '${state.items.length} report${state.items.length == 1 ? '' : 's'} available.',
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
                  if (state.reportTypeFilter != null)
                    Chip(
                      label: Text(state.reportTypeFilter!),
                      onDeleted: () =>
                          notifier.applyFilters(clearReportType: true),
                    ),
                  if (state.testDateFrom != null)
                    Chip(
                      label: Text(
                        'From ${MaterialLocalizations.of(context).formatMediumDate(state.testDateFrom!)}',
                      ),
                      onDeleted: () =>
                          notifier.applyFilters(clearTestDateFrom: true),
                    ),
                  if (state.testDateTo != null)
                    Chip(
                      label: Text(
                        'To ${MaterialLocalizations.of(context).formatMediumDate(state.testDateTo!)}',
                      ),
                      onDeleted: () =>
                          notifier.applyFilters(clearTestDateTo: true),
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
    LabReportsListUiState state,
    LabReportsListNotifier notifier,
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
              title: 'No lab reports yet',
              subtitle:
                  'Build your history by saving PDFs, scans, and important report dates in one tidy place.',
              icon: Icons.biotech_outlined,
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
        final r = state.items[index];
        return LabReportCard(
          report: r,
          isDeleting: state.deletingReportId == r.id,
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => AddUpdateLabReportScreen(existing: r),
              ),
            );
            if (changed == true && context.mounted) {
              notifier.refresh();
            }
          },
          onDelete: () => _confirmDelete(r),
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
