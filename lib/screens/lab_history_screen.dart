import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/labs/lab_controller.dart';
import '../features/labs/lab_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import 'add_lab_screen.dart';

String formatLabFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

IconData labFileIcon(LabFileBadge badge) {
  return switch (badge) {
    LabFileBadge.pdf => Icons.picture_as_pdf_rounded,
    LabFileBadge.image => Icons.image_rounded,
    LabFileBadge.doc => Icons.description_rounded,
    LabFileBadge.spreadsheet => Icons.table_chart_rounded,
    LabFileBadge.archive => Icons.folder_zip_rounded,
    LabFileBadge.other => Icons.insert_drive_file_rounded,
  };
}

Color labBadgeColor(LabFileBadge badge, ColorScheme scheme) {
  return switch (badge) {
    LabFileBadge.pdf => AppColors.statRed,
    LabFileBadge.image => AppColors.statBlue,
    LabFileBadge.doc => scheme.primary,
    LabFileBadge.spreadsheet => AppColors.statGreen,
    LabFileBadge.archive => AppColors.freePlan,
    LabFileBadge.other => scheme.onSurfaceVariant,
  };
}

Future<bool> confirmLabDelete(BuildContext context) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete lab report?'),
      content: const Text('The file will be removed from storage and this list.'),
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

Future<void> openLabReportFile(BuildContext context, LabReport report) async {
  final ext = report.fileExtension.toLowerCase();
  final url = report.fileUrl;

  if (ext == 'pdf') {
    if (!context.mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _LabPdfViewerPage(
          url: url,
          title: report.reportName,
        ),
      ),
    );
    return;
  }

  if (ext == 'jpg' ||
      ext == 'jpeg' ||
      ext == 'png' ||
      ext == 'gif' ||
      ext == 'webp' ||
      ext == 'bmp' ||
      ext == 'heic') {
    if (!context.mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _LabImageViewerPage(
          url: url,
          title: report.reportName,
        ),
      ),
    );
    return;
  }

  try {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    }
  } catch (_) {}

  try {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final dir = await getTemporaryDirectory();
    final safe = p.basename(report.fileName).replaceAll(RegExp(r'[/\\]'), '_');
    final file = File('${dir.path}/lab_${report.id}_$safe');
    await file.writeAsBytes(res.bodyBytes);
    await OpenFilex.open(file.path);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
    }
  }
}

class _LabPdfViewerPage extends StatefulWidget {
  const _LabPdfViewerPage({required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<_LabPdfViewerPage> createState() => _LabPdfViewerPageState();
}

class _LabPdfViewerPageState extends State<_LabPdfViewerPage> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(
        http.readBytes(Uri.parse(widget.url)),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: PdfViewPinch(controller: _controller),
    );
  }
}

class _LabImageViewerPage extends StatelessWidget {
  const _LabImageViewerPage({required this.url, required this.title});

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            url,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

class LabHistoryScreen extends ConsumerWidget {
  const LabHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(labReportsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab reports'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const AddLabScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add report'),
      ),
      body: async.when(
        data: (reports) {
          if (reports.isEmpty) {
            return EmptyState(
              icon: Icons.science_outlined,
              title: 'No lab reports',
              subtitle: 'Upload any file type — PDF, images, Office, DICOM, zip, and more.',
              actionLabel: 'Add report',
              onAction: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const AddLabScreen()),
                );
              },
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              88,
            ),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index];
              return Consumer(
                builder: (context, ref, _) {
                  Future<void> doDelete() async {
                    try {
                      await ref.read(labControllerProvider).deleteLabReport(r);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not delete: $e')),
                        );
                      }
                    }
                  }

                  return _LabReportCard(
                    report: r,
                    onTap: () => openLabReportFile(context, r),
                    onEdit: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => AddLabScreen(existing: r),
                        ),
                      );
                    },
                    onDeletePressed: () async {
                      if (!await confirmLabDelete(context) || !context.mounted) {
                        return;
                      }
                      await doDelete();
                    },
                    confirmDismissDelete: () => confirmLabDelete(context),
                    onDismissedDelete: doDelete,
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load reports',
          subtitle: e.toString(),
        ),
      ),
    );
  }
}

class _LabReportCard extends StatelessWidget {
  const _LabReportCard({
    required this.report,
    required this.onTap,
    required this.onEdit,
    required this.onDeletePressed,
    required this.confirmDismissDelete,
    required this.onDismissedDelete,
  });

  final LabReport report;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Future<void> Function() onDeletePressed;
  final Future<bool> Function() confirmDismissDelete;
  final Future<void> Function() onDismissedDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badge = report.fileBadge;
    final badgeColor = labBadgeColor(badge, scheme);

    return Dismissible(
      key: ValueKey(report.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDismissDelete(),
      onDismissed: (_) => onDismissedDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Icon(Icons.delete_outline_rounded, color: scheme.onError),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Material(
          color: scheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(labFileIcon(badge), color: badgeColor, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.reportName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          report.testName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: Icon(
                                Icons.category_outlined,
                                size: 16,
                                color: scheme.primary,
                              ),
                              label: Text(report.reportType),
                              labelStyle: Theme.of(context).textTheme.labelMedium,
                            ),
                            Chip(
                              visualDensity: VisualDensity.compact,
                              backgroundColor: badgeColor.withValues(alpha: 0.12),
                              label: Text(
                                labFileBadgeLabel(badge),
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '.${report.fileExtension}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              formatLabFileSize(report.fileSize),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        if (report.testDate != null || report.resultDate != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            [
                              if (report.testDate != null)
                                'Test: ${report.testDate!.year}-${report.testDate!.month.toString().padLeft(2, '0')}-${report.testDate!.day.toString().padLeft(2, '0')}',
                              if (report.resultDate != null)
                                'Result: ${report.resultDate!.year}-${report.resultDate!.month.toString().padLeft(2, '0')}-${report.resultDate!.day.toString().padLeft(2, '0')}',
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => onDeletePressed(),
                        icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
