import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/surgical_history/surgical_history_categories.dart';
import '../features/surgical_history/surgical_history_entry.dart';
import '../features/surgical_history/surgical_history_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/skeleton_placeholders.dart';
import '../widgets/surgical_history_entry_card.dart';
import 'add_update_surgical_history_screen.dart';

class SurgicalHistoryScreen extends ConsumerStatefulWidget {
  const SurgicalHistoryScreen({super.key});

  @override
  ConsumerState<SurgicalHistoryScreen> createState() =>
      _SurgicalHistoryScreenState();
}

class _SurgicalHistoryScreenState extends ConsumerState<SurgicalHistoryScreen> {
  final _scrollController = ScrollController();
  bool _loadMorePostFrameScheduled = false;
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(surgicalHistoryListProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels < 320) {
      if (_loadMorePostFrameScheduled) return;
      _loadMorePostFrameScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMorePostFrameScheduled = false;
        if (!mounted) return;
        ref.read(surgicalHistoryListProvider.notifier).loadMore();
      });
    }
  }

  Future<void> _confirmDelete(SurgicalHistoryEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete surgical history entry?'),
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
    if (ok == true && context.mounted) {
      await ref.read(surgicalHistoryListProvider.notifier).deleteEntry(entry);
    }
  }

  Future<void> _openFilters() async {
    String? category = _categoryFilter;

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
                    'Filter surgical history',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Focus on one category at a time.',
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
                      ...SurgicalHistoryCategories.all.map(
                        (item) => DropdownMenuItem<String?>(
                          value: item,
                          child: Text(item),
                        ),
                      ),
                    ],
                    onChanged: (value) => setModal(() => category = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      setState(() => _categoryFilter = category);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _categoryFilter = null);
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
    final state = ref.watch(surgicalHistoryListProvider);
    final notifier = ref.read(surgicalHistoryListProvider.notifier);
    final filteredItems = _applyFilters(state.items);
    final hasFilters = _categoryFilter != null;
    final backgroundColor = Color.lerp(
      Theme.of(context).scaffoldBackgroundColor,
      AppColors.seed,
      0.025,
    );

    ref.listen<SurgicalHistoryListUiState>(surgicalHistoryListProvider, (
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
        title: const Text('Surgical History'),
        actions: [
          IconButton(
            tooltip: hasFilters ? 'Filters active: 1' : 'Filters',
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
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => const AddUpdateSurgicalHistoryScreen(),
            ),
          );
          if (created == true && context.mounted) {
            notifier.refresh();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add history'),
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
            child: _SurgicalHistoryOverviewCard(entryCount: state.items.length),
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
                  Chip(
                    label: Text(_categoryFilter!),
                    onDeleted: () => setState(() => _categoryFilter = null),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.refresh(),
              child: _buildBody(context, state, notifier, filteredItems),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SurgicalHistoryListUiState state,
    SurgicalHistoryListNotifier notifier,
    List<SurgicalHistoryEntry> filteredItems,
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
              title: 'No surgical history yet',
              subtitle:
                  'Add past procedures, hospital stays, and outcomes your care team should know.',
              icon: Icons.medical_information_outlined,
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
              title: 'No entries match this filter',
              subtitle: 'Try another category or clear the filter.',
              icon: Icons.filter_list_off_rounded,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 88),
      itemCount: filteredItems.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= filteredItems.length) {
          return const SkeletonLoadMoreFooter();
        }

        final item = filteredItems[index];
        return SurgicalHistoryEntryCard(
          entry: item,
          isDeleting: state.deletingEntryId == item.id,
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => AddUpdateSurgicalHistoryScreen(existing: item),
              ),
            );
            if (changed == true && context.mounted) {
              notifier.refresh();
            }
          },
          onDelete: () => _confirmDelete(item),
        );
      },
    );
  }

  List<SurgicalHistoryEntry> _applyFilters(List<SurgicalHistoryEntry> items) {
    return items.where((entry) {
      if (_categoryFilter != null && entry.category != _categoryFilter) {
        return false;
      }
      return true;
    }).toList();
  }
}

class _SurgicalHistoryOverviewCard extends StatelessWidget {
  const _SurgicalHistoryOverviewCard({required this.entryCount});

  final int entryCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Color.lerp(scheme.surface, AppColors.seed, 0.035),
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
            'Keep procedures on record',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            entryCount == 0
                ? 'Log surgeries and key details so your history stays accurate over time.'
                : '$entryCount surgical histor${entryCount == 1 ? 'y entry is' : 'y entries are'} saved. Tap any card to update the details.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
