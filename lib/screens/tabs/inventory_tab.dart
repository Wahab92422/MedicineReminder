import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/medicines/medicine_controller.dart';
import '../../features/medicines/medicine_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../edit_medicine_screen.dart';

int _compareInventoryPriority(Medicine a, Medicine b) {
  if (a.isOutOfStock != b.isOutOfStock) {
    return a.isOutOfStock ? -1 : 1;
  }
  if (a.isLowStock != b.isLowStock) {
    return a.isLowStock ? -1 : 1;
  }
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

class InventoryTab extends ConsumerWidget {
  const InventoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicinesAsync = ref.watch(medicineStreamProvider);

    return medicinesAsync.when(
      data: (medicines) {
        if (medicines.isEmpty) {
          return const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No inventory yet',
            subtitle: 'Add medicines under the Medicines tab to track stock here.',
          );
        }

        final sorted = [...medicines]..sort(_compareInventoryPriority);
        final lowCount = medicines.where((m) => m.isLowStock || m.isOutOfStock).length;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (lowCount > 0) ...[
              Material(
                color: AppColors.freePlanContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.freePlan),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          lowCount == 1
                              ? '1 medicine needs attention'
                              : '$lowCount medicines need attention',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SectionHeader(title: 'Stock levels'),
            const SizedBox(height: AppSpacing.sm),
            ...sorted.map(
              (m) => _InventoryMedicineCard(
                medicine: m,
                onEdit: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => EditMedicineScreen(
                        id: m.id,
                        name: m.name,
                        dose: m.dose,
                        time: m.time,
                        quantityOnHand: m.quantityOnHand,
                        lowStockThreshold: m.lowStockThreshold,
                        inventoryUnit: m.inventoryUnit,
                      ),
                    ),
                  );
                },
                onDelta: (delta) {
                  ref.read(medicineControllerProvider).adjustMedicineQuantity(
                        id: m.id,
                        delta: delta,
                      );
                },
                onRestock: () => _showRestockDialog(context, ref, m),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load inventory',
        subtitle: e.toString(),
      ),
    );
  }
}

Future<void> _showRestockDialog(
  BuildContext context,
  WidgetRef ref,
  Medicine medicine,
) async {
  final controller = TextEditingController(text: '30');
  final added = await showDialog<int>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Restock ${medicine.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Add ${medicine.inventoryUnit}',
            hintText: 'e.g. 30',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              if (n == null || n <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a positive number.')),
                );
                return;
              }
              Navigator.pop(ctx, n);
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
  controller.dispose();

  if (added != null && context.mounted) {
    await ref.read(medicineControllerProvider).adjustMedicineQuantity(
          id: medicine.id,
          delta: added,
        );
  }
}

class _InventoryMedicineCard extends StatelessWidget {
  const _InventoryMedicineCard({
    required this.medicine,
    required this.onEdit,
    required this.onDelta,
    required this.onRestock,
  });

  final Medicine medicine;
  final VoidCallback onEdit;
  final void Function(int delta) onDelta;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = medicine.lowStockThreshold;
    final maxForBar = t != null && t > 0 ? (t * 3).clamp(10, 500) : 100;
    final barValue = maxForBar > 0
        ? (medicine.quantityOnHand / maxForBar).clamp(0.0, 1.0)
        : 0.0;
    Color barColor = scheme.primary;
    if (medicine.isOutOfStock) {
      barColor = AppColors.missed;
    } else if (medicine.isLowStock) {
      barColor = AppColors.freePlan;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.medication_liquid_rounded, color: scheme.primary, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        medicine.dose,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit details',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  '${medicine.quantityOnHand}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    medicine.inventoryUnit,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
                if (t != null)
                  Text(
                    'Alert at ≤ $t',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                value: barValue,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                color: barColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: medicine.quantityOnHand > 0 ? () => onDelta(-1) : null,
                  icon: const Icon(Icons.remove_rounded),
                  tooltip: 'Use one',
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filledTonal(
                  onPressed: () => onDelta(1),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Add one',
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onRestock,
                  icon: const Icon(Icons.inventory_rounded, size: 20),
                  label: const Text('Restock'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
