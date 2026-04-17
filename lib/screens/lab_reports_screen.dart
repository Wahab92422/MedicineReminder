import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/labs/lab_report.dart';
import '../features/labs/lab_report_providers.dart';
import '../features/labs/lab_report_types.dart';
import '../theme/app_spacing.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/lab_report_card.dart';
import '../widgets/loading_widget.dart';
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
      ref.read(labReportsListProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilters() async {
    final state = ref.read(labReportsListProvider);
    String? type = state.reportTypeFilter;
    DateTime? from = state.testDateFrom;
    DateTime? to = state.testDateTo;

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
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String?>(
                    // ignore: deprecated_member_use
                    value: type,
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Test date from'),
                    subtitle: Text(
                      from == null
                          ? 'Any'
                          : MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(from!),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Test date to'),
                    subtitle: Text(
                      to == null
                          ? 'Any'
                          : MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(to!),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
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

    ref.listen<LabReportsListUiState>(labReportsListProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab reports'),
        actions: [
          IconButton(
            tooltip: 'Filters',
            icon: const Icon(Icons.filter_list_rounded),
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
            child: CustomSearchField(
              controller: _searchController,
              hint: 'Search by title',
              onChanged: notifier.setSearchDraft,
            ),
          ),
          if (state.reportTypeFilter != null ||
              state.testDateFrom != null ||
              state.testDateTo != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
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
      return const LoadingWidget(message: 'Loading reports…');
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: EmptyStateWidget(
              title: 'No lab reports yet',
              subtitle: 'Add a report with attachments using the + button.',
              actionLabel: 'Add report',
              onAction: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const AddUpdateLabReportScreen(),
                  ),
                );
                if (ok == true && context.mounted) {
                  notifier.refresh();
                }
              },
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
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
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
