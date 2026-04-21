import 'package:flutter/material.dart';

import 'appointments_screen.dart';
import 'clinical_notes_screen.dart';
import 'family_history_screen.dart';
import 'lab_reports_screen.dart';
import 'meals_screen.dart';
import 'medical_history_screen.dart';
import 'medicine_inventory_screen.dart';
import 'medicine_logs_screen.dart';
import 'notifications_screen.dart';
import 'schedule_screen.dart';
import 'social_history_screen.dart';
import 'surgical_history_screen.dart';
import 'vitals_screen.dart';

/// One dashboard or drawer shortcut (same [QuickActionButton] styling everywhere).
class DashboardQuickActionSpec {
  DashboardQuickActionSpec({
    required this.icon,
    required this.label,
    required this.navigate,
  });

  final IconData icon;
  final String label;
  final void Function(BuildContext context) navigate;
}

/// Core tracking: shown on the dashboard grid (highest day-to-day value).
final List<DashboardQuickActionSpec> dashboardPrimaryQuickActions = [
  DashboardQuickActionSpec(
    icon: Icons.monitor_heart_rounded,
    label: 'Vitals',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const VitalsScreen()),
      );
    },
  ),
  DashboardQuickActionSpec(
    icon: Icons.calendar_month_rounded,
    label: 'Schedules',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const ScheduleScreen()),
      );
    },
  ),
  DashboardQuickActionSpec(
    icon: Icons.restaurant_menu_rounded,
    label: 'Meals',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const MealsScreen()),
      );
    },
  ),
  DashboardQuickActionSpec(
    icon: Icons.fact_check_outlined,
    label: 'Medicines',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const MedicineLogsScreen()),
      );
    },
  ),
  DashboardQuickActionSpec(
    icon: Icons.event_available_rounded,
    label: 'Appointments',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const AppointmentsScreen()),
      );
    },
  ),
  DashboardQuickActionSpec(
    icon: Icons.biotech_rounded,
    label: 'Lab reports',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const LabReportsScreen()),
      );
    },
  ),
  DashboardQuickActionSpec(
    icon: Icons.note_alt_rounded,
    label: 'Clinical notes',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const ClinicalNotesScreen()),
      );
    },
  ),
  DashboardQuickActionSpec(
    icon: Icons.local_pharmacy_rounded,
    label: 'Inventory',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const MedicineInventoryScreen(),
        ),
      );
    },
  ),
];

/// Longitudinal / history modules: same tiles in the drawer (alphabetically grouped by theme).
final List<DashboardQuickActionSpec> dashboardDrawerQuickActions = [
  DashboardQuickActionSpec(
    icon: Icons.family_restroom_rounded,
    label: 'Family history',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const FamilyHistoryScreen()),
      );
    },
  ),
  DashboardQuickActionSpec(
    icon: Icons.medical_information_rounded,
    label: 'Medical history',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const MedicalHistoryScreen()),
      );
    },
  ),
  DashboardQuickActionSpec(
    icon: Icons.notifications_active_rounded,
    label: 'Alerts',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      );
    },
  ),
  DashboardQuickActionSpec(
    icon: Icons.calendar_month_rounded,
    label: 'Schedules',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const ScheduleScreen()),
      );
    },
  ),
  DashboardQuickActionSpec(
    icon: Icons.groups_2_rounded,
    label: 'Social history',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const SocialHistoryScreen()),
      );
    },
  ),
  DashboardQuickActionSpec(
    icon: Icons.medical_services_rounded,
    label: 'Surgical history',
    navigate: (c) {
      Navigator.of(c).push<void>(
        MaterialPageRoute<void>(builder: (_) => const SurgicalHistoryScreen()),
      );
    },
  ),
];
