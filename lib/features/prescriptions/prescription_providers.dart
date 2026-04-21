import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/debouncer.dart';
import 'prescription.dart';
import 'prescription_repository.dart';

const _sentinel = Object();

final _prescriptionFirestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final _prescriptionStorageProvider = Provider<FirebaseStorage>(
  (_) => FirebaseStorage.instance,
);

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return PrescriptionRepository(
    firestore: ref.watch(_prescriptionFirestoreProvider),
    storage: ref.watch(_prescriptionStorageProvider),
  );
});

final prescriptionsListProvider =
    NotifierProvider<PrescriptionsListNotifier, PrescriptionsListUiState>(
      PrescriptionsListNotifier.new,
    );

@immutable
class PrescriptionsListUiState {
  const PrescriptionsListUiState({
    this.items = const [],
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.nextPageCursor,
    this.searchDraft = '',
    this.appliedSearchQuery = '',
    this.prescriptionTypeFilter,
    this.prescribedDateFrom,
    this.prescribedDateTo,
    this.deletingPrescriptionId,
  });

  final List<Prescription> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final Object? nextPageCursor;
  final String searchDraft;
  final String appliedSearchQuery;
  final String? prescriptionTypeFilter;
  final DateTime? prescribedDateFrom;
  final DateTime? prescribedDateTo;
  final String? deletingPrescriptionId;

  static const initial = PrescriptionsListUiState();

  PrescriptionsListUiState copyWith({
    Object? items = _sentinel,
    Object? isInitialLoading = _sentinel,
    Object? isLoadingMore = _sentinel,
    Object? error = _sentinel,
    bool clearError = false,
    Object? hasMore = _sentinel,
    Object? nextPageCursor = _sentinel,
    bool clearCursor = false,
    Object? searchDraft = _sentinel,
    Object? appliedSearchQuery = _sentinel,
    Object? prescriptionTypeFilter = _sentinel,
    bool clearPrescriptionType = false,
    Object? prescribedDateFrom = _sentinel,
    bool clearPrescribedDateFrom = false,
    Object? prescribedDateTo = _sentinel,
    bool clearPrescribedDateTo = false,
    Object? deletingPrescriptionId = _sentinel,
    bool clearDeleting = false,
  }) {
    return PrescriptionsListUiState(
      items: items == _sentinel ? this.items : items as List<Prescription>,
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
      searchDraft: searchDraft == _sentinel
          ? this.searchDraft
          : searchDraft as String,
      appliedSearchQuery: appliedSearchQuery == _sentinel
          ? this.appliedSearchQuery
          : appliedSearchQuery as String,
      prescriptionTypeFilter: clearPrescriptionType
          ? null
          : (prescriptionTypeFilter == _sentinel
                ? this.prescriptionTypeFilter
                : prescriptionTypeFilter as String?),
      prescribedDateFrom: clearPrescribedDateFrom
          ? null
          : (prescribedDateFrom == _sentinel
                ? this.prescribedDateFrom
                : prescribedDateFrom as DateTime?),
      prescribedDateTo: clearPrescribedDateTo
          ? null
          : (prescribedDateTo == _sentinel
                ? this.prescribedDateTo
                : prescribedDateTo as DateTime?),
      deletingPrescriptionId: clearDeleting
          ? null
          : (deletingPrescriptionId == _sentinel
                ? this.deletingPrescriptionId
                : deletingPrescriptionId as String?),
    );
  }
}

class PrescriptionsListNotifier extends Notifier<PrescriptionsListUiState> {
  Debouncer? _searchDebouncer;

  @override
  PrescriptionsListUiState build() {
    _searchDebouncer ??= Debouncer(
      duration: const Duration(milliseconds: 400),
      onValue: (value) {
        state = state.copyWith(appliedSearchQuery: value, clearCursor: true);
        _fetchFirstPage();
      },
    );
    ref.onDispose(() {
      _searchDebouncer?.dispose();
    });
    return PrescriptionsListUiState.initial;
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> refresh({bool preserveItems = true}) async {
    state = state.copyWith(
      clearError: true,
      clearCursor: true,
      hasMore: true,
      items: preserveItems ? state.items : const <Prescription>[],
    );
    await _fetchFirstPage(preserveItems: preserveItems);
  }

  void setSearchDraft(String value) {
    state = state.copyWith(searchDraft: value);
    _searchDebouncer?.call(value);
  }

  void applyFilters({
    String? prescriptionType,
    DateTime? prescribedDateFrom,
    DateTime? prescribedDateTo,
    bool clearPrescriptionType = false,
    bool clearPrescribedDateFrom = false,
    bool clearPrescribedDateTo = false,
  }) {
    state = state.copyWith(
      prescriptionTypeFilter: prescriptionType,
      clearPrescriptionType: clearPrescriptionType,
      prescribedDateFrom: prescribedDateFrom,
      clearPrescribedDateFrom: clearPrescribedDateFrom,
      prescribedDateTo: prescribedDateTo,
      clearPrescribedDateTo: clearPrescribedDateTo,
      clearCursor: true,
    );
    _fetchFirstPage();
  }

  void clearAllFilters() {
    state = state.copyWith(
      clearPrescriptionType: true,
      clearPrescribedDateFrom: true,
      clearPrescribedDateTo: true,
      appliedSearchQuery: '',
      searchDraft: '',
      clearCursor: true,
      items: const <Prescription>[],
      hasMore: true,
    );
    _fetchFirstPage();
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
      final repo = ref.read(prescriptionRepositoryProvider);
      final page = await repo.getPrescriptionsPage(
        userId: uid,
        pageCursor: state.nextPageCursor,
        prescriptionType: state.prescriptionTypeFilter,
        prescribedDateFrom: state.prescribedDateFrom,
        prescribedDateTo: state.prescribedDateTo,
        titleSearch: state.appliedSearchQuery,
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

  Future<void> deletePrescription(Prescription p) async {
    final uid = _uid;
    if (uid == null) return;
    state = state.copyWith(deletingPrescriptionId: p.id, clearError: true);
    try {
      final repo = ref.read(prescriptionRepositoryProvider);
      final res = await repo.deletePrescription(
        userId: uid,
        prescriptionId: p.id,
        attachmentUrls: p.attachments.map((e) => e.url).toList(),
      );
      if (!res.success) {
        state = state.copyWith(
          clearDeleting: true,
          error: res.errorMessage ?? 'Could not delete prescription.',
        );
        return;
      }
      state = state.copyWith(
        clearDeleting: true,
        items: state.items.where((e) => e.id != p.id).toList(),
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
        items: const <Prescription>[],
        hasMore: false,
        clearCursor: true,
      );
      return;
    }

    state = state.copyWith(
      isInitialLoading: true,
      clearError: true,
      items: preserveItems ? state.items : const <Prescription>[],
      clearCursor: true,
      hasMore: true,
    );

    try {
      final repo = ref.read(prescriptionRepositoryProvider);
      final page = await repo.getPrescriptionsPage(
        userId: uid,
        prescriptionType: state.prescriptionTypeFilter,
        prescribedDateFrom: state.prescribedDateFrom,
        prescribedDateTo: state.prescribedDateTo,
        titleSearch: state.appliedSearchQuery,
      );
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
