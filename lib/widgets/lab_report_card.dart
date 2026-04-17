import 'package:flutter/material.dart';

import '../features/labs/lab_report.dart';
import '../theme/app_spacing.dart';

class LabReportCard extends StatelessWidget {
  const LabReportCard({
    super.key,
    required this.report,
    required this.onTap,
    this.onDelete,
    this.isDeleting = false,
  });

  final LabReport report;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loc = MaterialLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: isDeleting ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: isDeleting ? null : onDelete,
                      icon: isDeleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.delete_outline_rounded, color: scheme.error),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                report.reportType,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.science_outlined, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Test: ${loc.formatMediumDate(report.testDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Report: ${loc.formatMediumDate(report.reportDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (report.attachments.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.attach_file_rounded, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${report.attachments.length} attachment(s)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
