import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/navigation/shell_tab_request.dart';
import '../../features/medicines/medicine_controller.dart';
import '../../features/subscription/medicine_entitlement.dart';
import '../../providers/subscription_provider.dart';
import '../../services/notification_service.dart';
import '../add_medicine_screen.dart';
import '../home_screen.dart';
import '../tabs/dashboard_tab.dart';
import '../tabs/inventory_tab.dart';
import '../upgrade_plan_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _titles = ['Medicines', 'Insights', 'Inventory'];

  void _onAddMedicine() {
    final medicines = ref.read(medicineStreamProvider).value;
    final isPremium = ref.read(subscriptionProvider).asData?.value ?? true;
    final count = medicines?.length ?? 0;
    if (!MedicineEntitlement.canAddMore(
      isPremium: isPremium,
      medicineCount: count,
    )) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const UpgradePlanScreen()),
      );
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const AddMedicineScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showUpgrade = ref.watch(subscriptionProvider).when(
          data: (premium) => !premium,
          loading: () => false,
          error: (_, _) => false,
        );

    ref.listen<int?>(shellTabRequestProvider, (previous, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _index = next);
          ref.read(shellTabRequestProvider.notifier).clear();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          if (showUpgrade)
            IconButton(
              tooltip: 'Upgrade plan',
              icon: const Icon(Icons.workspace_premium_outlined),
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const UpgradePlanScreen(),
                  ),
                );
              },
            ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await NotificationService.cancelAllPendingNotifications();
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          DashboardTab(),
          InventoryTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.medication_liquid_outlined),
            selectedIcon: Icon(Icons.medication_liquid_rounded),
            label: 'Medicines',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Inventory',
          ),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _onAddMedicine,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
