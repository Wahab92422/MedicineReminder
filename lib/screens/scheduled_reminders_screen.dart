import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/schedule/scheduled_reminders_catalog_provider.dart';
import '../services/reminder_notification_payload.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/app_date_time_format.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/skeleton_placeholders.dart';
import 'reminder_indicator_screen.dart';

/// Lists scheduled reminders (meals, appointments, doses, agenda) with search and type filter.
class ScheduledRemindersScreen extends ConsumerStatefulWidget {
  const ScheduledRemindersScreen({super.key});

  @override
  ConsumerState<ScheduledRemindersScreen> createState() =>
      _ScheduledRemindersScreenState();
}

class _ScheduledRemindersScreenState
    extends ConsumerState<ScheduledRemindersScreen> {
  final _searchController = TextEditingController();
  /// `null` = all types.
  ScheduledReminderRowKind? _filterKind;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ScheduledReminderRow> _filter(
    List<ScheduledReminderRow> all,
    String q,
  ) {
    var list = all;
    if (_filterKind != null) {
      list = list.where((e) => e.kind == _filterKind).toList();
    }
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return list;
    return list
        .where((e) => e.title.toLowerCase().contains(t))
        .toList();
  }

  String _kindLabel(ScheduledReminderRowKind k) {
    return switch (k) {
      ScheduledReminderRowKind.meal => 'Meal',
      ScheduledReminderRowKind.appointment => 'Appointment',
      ScheduledReminderRowKind.medicineLog => 'Medicine',
      ScheduledReminderRowKind.agenda => 'General',
    };
  }

  ReminderPayloadKind _toPayloadKind(ScheduledReminderRowKind k) {
    return switch (k) {
      ScheduledReminderRowKind.meal => ReminderPayloadKind.meal,
      ScheduledReminderRowKind.appointment => ReminderPayloadKind.appointment,
      ScheduledReminderRowKind.medicineLog => ReminderPayloadKind.medicineLog,
      ScheduledReminderRowKind.agenda => ReminderPayloadKind.agenda,
    };
  }

  Future<void> _openFilters() async {
    ScheduledReminderRowKind? kind = _filterKind;

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
                    'Filter reminders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Show only one reminder type, or all types.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Reminder type',
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ScheduledReminderRowKind?>(
                        isExpanded: true,
                        value: kind,
                        hint: const Text('All types'),
                        items: [
                          const DropdownMenuItem<ScheduledReminderRowKind?>(
                            value: null,
                            child: Text('All types'),
                          ),
                          for (final k in ScheduledReminderRowKind.values)
                            DropdownMenuItem<ScheduledReminderRowKind?>(
                              value: k,
                              child: Text(_kindLabel(k)),
                            ),
                        ],
                        onChanged: (value) => setModal(() => kind = value),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      setState(() => _filterKind = kind);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _filterKind = null);
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
    final async = ref.watch(scheduledRemindersCatalogProvider);
    final hasFilters = _filterKind != null;
    final activeFilterCount = hasFilters ? 1 : 0;

    return Scaffold(
      appBar: AppScreenHeader(
        title: 'Notifications',
        subtitle:
            'Due now or within the last 12 hours — open one to log or mark status.',
        icon: Icons.notifications_active_outlined,
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by title',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  Chip(
                    label: Text(_kindLabel(_filterKind!)),
                    onDeleted: () => setState(() => _filterKind = null),
                  ),
                ],
              ),
            ),
          SizedBox(height: hasFilters ? AppSpacing.sm : AppSpacing.md),
          Expanded(
            child: async.when(
              loading: () => const ListLoadingSkeleton(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  88,
                ),
              ),
              error: (e, _) => Center(child: Text('$e')),
              data: (all) {
                final filtered =
                    _filter(all, _searchController.text);
                if (filtered.isEmpty) {
                  final q = _searchController.text.trim();
                  final emptyMessage = all.isEmpty
                      ? 'No scheduled reminders.'
                      : (hasFilters && q.isEmpty
                          ? 'No reminders of this type in the last 12 hours.'
                          : 'No matches.');
                  return Center(
                    child: Text(
                      emptyMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(scheduledRemindersCatalogProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final row = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(_kindLabel(row.kind)[0]),
                          ),
                          title: Text(row.title),
                          subtitle: Text(
                            '${_kindLabel(row.kind)} · ${AppDateTimeFormat.formatDateTime(row.at)} · ${row.statusLabel}',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            final payload = ReminderNotificationPayload(
                              kind: _toPayloadKind(row.kind),
                              entityId: row.id,
                              scheduledAtMs: row.at.millisecondsSinceEpoch,
                            );
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ReminderIndicatorScreen(payload: payload),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
