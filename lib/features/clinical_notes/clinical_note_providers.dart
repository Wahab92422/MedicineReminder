import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clinical_note_entry.dart';
import 'clinical_note_repository.dart';

const _sentinel = Object();

final _clinicalFirestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final clinicalNoteRepositoryProvider = Provider<ClinicalNoteRepository>(
  (ref) =>
      ClinicalNoteRepository(firestore: ref.watch(_clinicalFirestoreProvider)),
);

final clinicalNotesListProvider =
    NotifierProvider<ClinicalNotesListNotifier, ClinicalNotesListUiState>(
      ClinicalNotesListNotifier.new,
    );

@immutable
class ClinicalNotesListUiState {
  const ClinicalNotesListUiState({
    this.items = const [],
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.nextPageCursor,
    this.deletingEntryId,
  });

  final List<ClinicalNoteEntry> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final Object? nextPageCursor;
  final String? deletingEntryId;

  static const initial = ClinicalNotesListUiState();

  ClinicalNotesListUiState copyWith({
    Object? items = _sentinel,
    Object? isInitialLoading = _sentinel,
    Object? isLoadingMore = _sentinel,
    Object? error = _sentinel,
    bool clearError = false,
    Object? hasMore = _sentinel,
    Object? nextPageCursor = _sentinel,
    bool clearCursor = false,
    Object? deletingEntryId = _sentinel,
    bool clearDeleting = false,
  }) {
    return ClinicalNotesListUiState(
      items: items == _sentinel ? this.items : items as List<ClinicalNoteEntry>,
      isInitialLoading: isInitialLoading == _sentinel
          ? this.isInitialLoading
          : isInitialLoading as bool,
      isLoadingMore: isLoadingMore == _sentinel
          ? this.isLoadingMore
          : isLoadingMore as bool,
      error: clearError
          ? null
          : (error == _sentinel ? this.error : error as String?),
      hasMore: hasMore == _sentinel ? this.hasMore : hasMore as bool,
      nextPageCursor: clearCursor
          ? null
          : (nextPageCursor == _sentinel
                ? this.nextPageCursor
                : nextPageCursor),
      deletingEntryId: clearDeleting
          ? null
          : (deletingEntryId == _sentinel
                ? this.deletingEntryId
                : deletingEntryId as String?),
    );
  }
}

class ClinicalNotesListNotifier extends Notifier<ClinicalNotesListUiState> {
  @override
  ClinicalNotesListUiState build() => ClinicalNotesListUiState.initial;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> refresh({bool preserveItems = true}) async {
    state = state.copyWith(
      clearError: true,
      clearCursor: true,
      hasMore: true,
      items: preserveItems ? state.items : const <ClinicalNoteEntry>[],
    );
    await _fetchFirstPage(preserveItems: preserveItems);
  }

  Future<void> loadMore() async {
    final uid = _uid;
    if (uid == null) return;
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.isInitialLoading ||
        state.nextPageCursor == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final repo = ref.read(clinicalNoteRepositoryProvider);
      final page = await repo.getNotesPage(
        userId: uid,
        pageCursor: state.nextPageCursor,
      );
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...page.items],
        nextPageCursor: page.nextPageCursor,
        hasMore: page.nextPageCursor != null,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> deleteEntry(ClinicalNoteEntry entry) async {
    final uid = _uid;
    if (uid == null) return;
    state = state.copyWith(deletingEntryId: entry.id, clearError: true);
    try {
      final repo = ref.read(clinicalNoteRepositoryProvider);
      final res = await repo.deleteEntry(userId: uid, entryId: entry.id);
      if (!res.success) {
        state = state.copyWith(
          clearDeleting: true,
          error: res.errorMessage ?? 'Could not delete clinical note.',
        );
        return;
      }
      state = state.copyWith(
        clearDeleting: true,
        items: state.items.where((e) => e.id != entry.id).toList(),
      );
    } catch (e) {
      state = state.copyWith(clearDeleting: true, error: e.toString());
    }
  }

  Future<void> _fetchFirstPage({bool preserveItems = false}) async {
    final uid = _uid;
    if (uid == null) {
      state = state.copyWith(
        isInitialLoading: false,
        error: 'Not signed in',
        items: const <ClinicalNoteEntry>[],
        hasMore: false,
        clearCursor: true,
      );
      return;
    }

    state = state.copyWith(
      isInitialLoading: true,
      clearError: true,
      items: preserveItems ? state.items : const <ClinicalNoteEntry>[],
      clearCursor: true,
      hasMore: true,
    );

    try {
      final repo = ref.read(clinicalNoteRepositoryProvider);
      final page = await repo.getNotesPage(userId: uid);
      state = state.copyWith(
        isInitialLoading: false,
        items: page.items,
        nextPageCursor: page.nextPageCursor,
        hasMore: page.nextPageCursor != null,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialLoading: false,
        error: e.toString(),
        hasMore: false,
        clearCursor: true,
      );
    }
  }
}
