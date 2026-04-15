import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/clinical_notes/clinical_note_model.dart';
import '../features/clinical_notes/clinical_note_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/clinical_note_card.dart';
import '../widgets/empty_state.dart';
import 'add_clinical_note_screen.dart';

class ClinicalNotesHistoryScreen extends ConsumerWidget {
  const ClinicalNotesHistoryScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text(
          'This clinical note will be removed permanently. This cannot be undone.',
        ),
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

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    ClinicalNote note,
  ) async {
    if (!await _confirmDelete(context) || !context.mounted) return;
    try {
      await ref.read(clinicalNoteControllerProvider).deleteNote(note.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
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

  void _openEditor(BuildContext context, ClinicalNote note) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddClinicalNoteScreen(existing: note),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(clinicalNotesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical notes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const AddClinicalNoteScreen()),
          );
        },
        icon: const Icon(Icons.note_add_rounded),
        label: const Text('Add note'),
      ),
      body: async.when(
        data: (notes) {
          if (notes.isEmpty) {
            return EmptyState(
              icon: Icons.note_alt_outlined,
              title: 'No clinical notes',
              subtitle:
                  'Record progress notes, visit summaries, phone messages, and other documentation.',
              actionLabel: 'Add note',
              onAction: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AddClinicalNoteScreen(),
                  ),
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
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ClinicalNoteCard(
                  note: note,
                  onEdit: () => _openEditor(context, note),
                  onDelete: () => _deleteNote(context, ref, note),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load notes',
          subtitle: e.toString(),
        ),
      ),
    );
  }
}
