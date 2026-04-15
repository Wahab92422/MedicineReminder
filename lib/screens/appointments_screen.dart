import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/appointments/appointment_model.dart';
import '../features/appointments/appointment_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/appointment_card.dart';
import '../widgets/empty_state.dart';
import 'add_appointment_screen.dart';

enum _AppointmentListFilter {
  all,
  attended,
  missed,
}

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _AppointmentListFilter _filter = _AppointmentListFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete appointment?'),
        content: const Text('This appointment will be removed from your list.'),
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

  Future<void> _delete(BuildContext context, AppointmentRecord a) async {
    if (!await _confirmDelete(context) || !context.mounted) return;
    try {
      await ref.read(appointmentControllerProvider).delete(a.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment deleted')),
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

  Future<void> _setStatus(
    BuildContext context,
    AppointmentRecord a,
    AppointmentStatus status,
  ) async {
    try {
      await ref.read(appointmentControllerProvider).setStatus(
            record: a,
            status: status,
          );
      if (context.mounted) {
        final msg = switch (status) {
          AppointmentStatus.attended => 'Marked as attended',
          AppointmentStatus.missed => 'Marked as missed',
          AppointmentStatus.scheduled => 'Updated',
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e')),
        );
      }
    }
  }

  List<AppointmentRecord> _applyFilter(List<AppointmentRecord> all) {
    return switch (_filter) {
      _AppointmentListFilter.all => all,
      _AppointmentListFilter.attended =>
        all.where((a) => a.status == AppointmentStatus.attended).toList(),
      _AppointmentListFilter.missed =>
        all.where((a) => a.status == AppointmentStatus.missed).toList(),
    };
  }

  ({List<AppointmentRecord> upcoming, List<AppointmentRecord> past}) _split(
    List<AppointmentRecord> filtered,
  ) {
    final now = DateTime.now();
    final upcoming = filtered.where((a) => a.isFutureSlot(now)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final past = filtered.where((a) => !a.isFutureSlot(now)).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return (upcoming: upcoming, past: past);
  }

  String _filterDisplayLabel() {
    return switch (_filter) {
      _AppointmentListFilter.all => 'All appointments',
      _AppointmentListFilter.attended => 'Attended only',
      _AppointmentListFilter.missed => 'Missed only',
    };
  }

  Future<void> _openFilterModal(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Text(
                    'Filter list',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.list_alt_rounded),
                  title: const Text('All appointments'),
                  trailing: _filter == _AppointmentListFilter.all
                      ? Icon(Icons.check_rounded, color: scheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _filter = _AppointmentListFilter.all);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.check_circle_outline_rounded, color: scheme.primary),
                  title: const Text('Attended only'),
                  trailing: _filter == _AppointmentListFilter.attended
                      ? Icon(Icons.check_rounded, color: scheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _filter = _AppointmentListFilter.attended);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.event_busy_rounded, color: scheme.error),
                  title: const Text('Missed only'),
                  trailing: _filter == _AppointmentListFilter.missed
                      ? Icon(Icons.check_rounded, color: scheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _filter = _AppointmentListFilter.missed);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterBar(BuildContext context, ColorScheme scheme) {
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: InkWell(
        onTap: () => _openFilterModal(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: scheme.primary,
                size: 26,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      _filterDisplayLabel(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appointmentList(
    BuildContext context,
    List<AppointmentRecord> items,
    String emptyMessage,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 88),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final a = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppointmentCard(
            record: a,
            onEdit: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AddAppointmentScreen(existing: a),
                ),
              );
            },
            onDelete: () => _delete(context, a),
            onMarkAttended: () => _setStatus(context, a, AppointmentStatus.attended),
            onMarkMissed: () => _setStatus(context, a, AppointmentStatus.missed),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(appointmentsStreamProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            tooltip: 'Filter appointments',
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _openFilterModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const AddAppointmentScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Schedule'),
      ),
      body: async.when(
        data: (all) {
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.event_available_outlined,
              title: 'No appointments',
              subtitle:
                  'Schedule visits with date, time, doctor, and location. Mark attended or missed after each visit.',
              actionLabel: 'Schedule appointment',
              onAction: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AddAppointmentScreen(),
                  ),
                );
              },
            );
          }

          final filtered = _applyFilter(all);
          final split = _split(filtered);
          final upcoming = split.upcoming;
          final past = split.past;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _filterBar(context, scheme),
              Material(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Upcoming (${upcoming.length})'),
                    Tab(text: 'Past & completed (${past.length})'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _appointmentList(
                      context,
                      upcoming,
                      _filter == _AppointmentListFilter.all
                          ? 'No upcoming appointments.'
                          : 'No upcoming appointments match this filter.',
                    ),
                    _appointmentList(
                      context,
                      past,
                      _filter == _AppointmentListFilter.all
                          ? 'No past appointments yet.'
                          : 'No past appointments match this filter.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load appointments',
          subtitle: e.toString(),
        ),
      ),
    );
  }
}
