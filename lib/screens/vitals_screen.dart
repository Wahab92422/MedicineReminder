import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/vitals/vital_entry.dart';
import '../features/vitals/vital_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/skeleton_placeholders.dart';
import '../widgets/vital_entry_card.dart';
import '../widgets/vitals_overview_card.dart';
import 'add_update_vitals_screen.dart';
import 'add_vitals_screen.dart';

/// Chronological list of vitals with pull-to-refresh and add.
class VitalsScreen extends ConsumerStatefulWidget {
  const VitalsScreen({super.key});

  @override
  ConsumerState<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
  final _scrollController = ScrollController();
  bool _loadMorePostFrameScheduled = false;
  String? _metricFilter;
  DateTime? _fromDateFilter;
  DateTime? _toDateFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vitalsListProvider.notifier).refresh();
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
    final pos = _scrollController.position;
    if (pos.maxScrollExtent - pos.pixels < 320) {
      if (_loadMorePostFrameScheduled) return;
      _loadMorePostFrameScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMorePostFrameScheduled = false;
        if (!mounted) return;
        ref.read(vitalsListProvider.notifier).loadMore();
      });
    }
  }

  Future<void> _confirmDelete(VitalEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete vitals entry?'),
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
      await ref.read(vitalsListProvider.notifier).deleteEntry(entry);
    }
  }

  Future<void> _openFilters() async {
    String? metric = _metricFilter;
    DateTime? from = _fromDateFilter;
    DateTime? to = _toDateFilter;

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
                    'Filter vitals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Show entries that include a specific reading or fall within a date range.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String?>(
                    initialValue: metric,
                    decoration: const InputDecoration(labelText: 'Reading'),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All readings'),
                      ),
                      DropdownMenuItem<String?>(
                        value: _VitalMetricFilter.bloodPressure,
                        child: Text('Blood pressure'),
                      ),
                      DropdownMenuItem<String?>(
                        value: _VitalMetricFilter.heartRate,
                        child: Text('Heart rate'),
                      ),
                      DropdownMenuItem<String?>(
                        value: _VitalMetricFilter.temperature,
                        child: Text('Temperature'),
                      ),
                      DropdownMenuItem<String?>(
                        value: _VitalMetricFilter.weight,
                        child: Text('Weight'),
                      ),
                      DropdownMenuItem<String?>(
                        value: _VitalMetricFilter.height,
                        child: Text('Height'),
                      ),
                      DropdownMenuItem<String?>(
                        value: _VitalMetricFilter.glucose,
                        child: Text('Glucose'),
                      ),
                      DropdownMenuItem<String?>(
                        value: _VitalMetricFilter.spo2,
                        child: Text('SpO2'),
                      ),
                    ],
                    onChanged: (value) => setModal(() => metric = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _VitalsFilterDateTile(
                    label: 'From date',
                    value: from == null
                        ? 'Any'
                        : MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(from!),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: from ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime(DateTime.now().year + 2),
                      );
                      if (picked != null) {
                        setModal(() => from = picked);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _VitalsFilterDateTile(
                    label: 'To date',
                    value: to == null
                        ? 'Any'
                        : MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(to!),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: to ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime(DateTime.now().year + 2),
                      );
                      if (picked != null) {
                        setModal(() => to = picked);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _metricFilter = metric;
                        _fromDateFilter = from;
                        _toDateFilter = to;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _metricFilter = null;
                        _fromDateFilter = null;
                        _toDateFilter = null;
                      });
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
    final state = ref.watch(vitalsListProvider);
    final notifier = ref.read(vitalsListProvider.notifier);
    final filteredItems = _applyFilters(state.items);
    final scheme = Theme.of(context).colorScheme;
    final hasFilters =
        _metricFilter != null ||
        _fromDateFilter != null ||
        _toDateFilter != null;
    final activeFilterCount = [
      _metricFilter,
      _fromDateFilter,
      _toDateFilter,
    ].where((value) => value != null).length;
    final backgroundColor = Color.lerp(
      Theme.of(context).scaffoldBackgroundColor,
      scheme.primary,
      0.04,
    );

    ref.listen<VitalsListUiState>(vitalsListProvider, (prev, next) {
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
        title: const Text('Vitals'),
        actions: [
          IconButton(
            tooltip: hasFilters
                ? 'Filters active: $activeFilterCount'
                : 'Filters',
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
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 1.5),
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
            MaterialPageRoute<bool>(builder: (_) => const AddVitalsScreen()),
          );
          if (created == true && context.mounted) {
            notifier.refresh();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add vitals'),
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
            child: VitalsOverviewCard(entryCount: state.items.length),
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
                  if (_metricFilter != null)
                    Chip(
                      label: Text(_metricLabel(_metricFilter!)),
                      onDeleted: () => setState(() => _metricFilter = null),
                    ),
                  if (_fromDateFilter != null)
                    Chip(
                      label: Text(
                        'From ${MaterialLocalizations.of(context).formatMediumDate(_fromDateFilter!)}',
                      ),
                      onDeleted: () => setState(() => _fromDateFilter = null),
                    ),
                  if (_toDateFilter != null)
                    Chip(
                      label: Text(
                        'To ${MaterialLocalizations.of(context).formatMediumDate(_toDateFilter!)}',
                      ),
                      onDeleted: () => setState(() => _toDateFilter = null),
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
    VitalsListUiState state,
    VitalsListNotifier notifier,
    List<VitalEntry> filteredItems,
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
              title: 'No vitals yet',
              subtitle: 'Record blood pressure, heart rate, glucose, and more.',
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
              title: 'No vitals match these filters',
              subtitle: 'Try a different reading or date range.',
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
        final e = filteredItems[index];
        return VitalEntryCard(
          entry: e,
          isDeleting: state.deletingEntryId == e.id,
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => AddUpdateVitalsScreen(existing: e),
              ),
            );
            if (changed == true && context.mounted) {
              notifier.refresh();
            }
          },
          onDelete: () => _confirmDelete(e),
        );
      },
    );
  }

  List<VitalEntry> _applyFilters(List<VitalEntry> items) {
    return items.where((entry) {
      if (_metricFilter != null && !_matchesMetric(entry, _metricFilter!)) {
        return false;
      }
      if (_fromDateFilter != null &&
          _isBeforeDay(entry.recordedAt, _fromDateFilter!)) {
        return false;
      }
      if (_toDateFilter != null &&
          _isAfterDay(entry.recordedAt, _toDateFilter!)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool _matchesMetric(VitalEntry entry, String metric) {
    switch (metric) {
      case _VitalMetricFilter.bloodPressure:
        return entry.systolicMmHg != null || entry.diastolicMmHg != null;
      case _VitalMetricFilter.heartRate:
        return entry.heartRateBpm != null;
      case _VitalMetricFilter.temperature:
        return entry.temperatureCelsius != null;
      case _VitalMetricFilter.weight:
        return entry.weightKg != null;
      case _VitalMetricFilter.height:
        return entry.heightCm != null;
      case _VitalMetricFilter.glucose:
        return entry.glucoseMgDl != null;
      case _VitalMetricFilter.spo2:
        return entry.spo2Percent != null;
      default:
        return true;
    }
  }

  bool _isBeforeDay(DateTime value, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return value.isBefore(start);
  }

  bool _isAfterDay(DateTime value, DateTime day) {
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
    return value.isAfter(end);
  }

  String _metricLabel(String metric) {
    switch (metric) {
      case _VitalMetricFilter.bloodPressure:
        return 'Blood pressure';
      case _VitalMetricFilter.heartRate:
        return 'Heart rate';
      case _VitalMetricFilter.temperature:
        return 'Temperature';
      case _VitalMetricFilter.weight:
        return 'Weight';
      case _VitalMetricFilter.height:
        return 'Height';
      case _VitalMetricFilter.glucose:
        return 'Glucose';
      case _VitalMetricFilter.spo2:
        return 'SpO2';
      default:
        return metric;
    }
  }
}

abstract final class _VitalMetricFilter {
  static const bloodPressure = 'bloodPressure';
  static const heartRate = 'heartRate';
  static const temperature = 'temperature';
  static const weight = 'weight';
  static const height = 'height';
  static const glucose = 'glucose';
  static const spo2 = 'spo2';
}

class _VitalsFilterDateTile extends StatelessWidget {
  const _VitalsFilterDateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
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
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: scheme.primary,
                  size: 20,
                ),
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
