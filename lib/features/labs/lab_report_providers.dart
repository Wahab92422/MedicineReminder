import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/debouncer.dart';
import 'lab_report.dart';
import 'lab_report_repository.dart';

const _sentinel = Object();

final _firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final _storageProvider = Provider<FirebaseStorage>(
  (_) => FirebaseStorage.instance,
);

final labReportRepositoryProvider = Provider<LabReportRepository>((ref) {
  return LabReportRepository(
    firestore: ref.watch(_firestoreProvider),
    storage: ref.watch(_storageProvider),
  );
});

final labReportsListProvider =
    NotifierProvider<LabReportsListNotifier, LabReportsListUiState>(
      LabReportsListNotifier.new,
    );

@immutable
class LabReportsListUiState {
  const LabReportsListUiState({
    this.items = const [],
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.nextPageCursor,
    this.searchDraft = '',
    this.appliedSearchQuery = '',
    this.reportTypeFilter,
    this.testDateFrom,
    this.testDateTo,
    this.deletingReportId,
  });

  final List<LabReport> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final Object? nextPageCursor;
  final String searchDraft;
  final String appliedSearchQuery;
  final String? reportTypeFilter;
  final DateTime? testDateFrom;
  final DateTime? testDateTo;
  final String? deletingReportId;

  static const initial = LabReportsListUiState();

  LabReportsListUiState copyWith({
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
    Object? reportTypeFilter = _sentinel,
    bool clearReportType = false,
    Object? testDateFrom = _sentinel,
    bool clearTestDateFrom = false,
    Object? testDateTo = _sentinel,
    bool clearTestDateTo = false,
    Object? deletingReportId = _sentinel,
    bool clearDeleting = false,
  }) {
    return LabReportsListUiState(
      items: items == _sentinel ? this.items : items as List<LabReport>,
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
      reportTypeFilter: clearReportType
          ? null
          : (reportTypeFilter == _sentinel
                ? this.reportTypeFilter
                : reportTypeFilter as String?),
      testDateFrom: clearTestDateFrom
          ? null
          : (testDateFrom == _sentinel
                ? this.testDateFrom
                : testDateFrom as DateTime?),
      testDateTo: clearTestDateTo
          ? null
          : (testDateTo == _sentinel
                ? this.testDateTo
                : testDateTo as DateTime?),
      deletingReportId: clearDeleting
          ? null
          : (deletingReportId == _sentinel
                ? this.deletingReportId
                : deletingReportId as String?),
    );
  }
}

class LabReportsListNotifier extends Notifier<LabReportsListUiState> {
  Debouncer? _searchDebouncer;

  @override
  LabReportsListUiState build() {
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
    return LabReportsListUiState.initial;
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> refresh({bool preserveItems = true}) async {
    state = state.copyWith(
      clearError: true,
      clearCursor: true,
      hasMore: true,
      items: preserveItems ? state.items : const <LabReport>[],
    );
    await _fetchFirstPage(preserveItems: preserveItems);
  }

  void setSearchDraft(String value) {
    state = state.copyWith(searchDraft: value);
    _searchDebouncer?.call(value);
  }

  void applyFilters({
    String? reportType,
    DateTime? testDateFrom,
    DateTime? testDateTo,
    bool clearReportType = false,
    bool clearTestDateFrom = false,
    bool clearTestDateTo = false,
  }) {
    state = state.copyWith(
      reportTypeFilter: reportType,
      clearReportType: clearReportType,
      testDateFrom: testDateFrom,
      clearTestDateFrom: clearTestDateFrom,
      testDateTo: testDateTo,
      clearTestDateTo: clearTestDateTo,
      clearCursor: true,
    );
    _fetchFirstPage();
  }

  void clearAllFilters() {
    state = state.copyWith(
      clearReportType: true,
      clearTestDateFrom: true,
      clearTestDateTo: true,
      appliedSearchQuery: '',
      searchDraft: '',
      clearCursor: true,
      items: const <LabReport>[],
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
      final repo = ref.read(labReportRepositoryProvider);
      final page = await repo.getReportsPage(
        userId: uid,
        pageCursor: state.nextPageCursor,
        reportType: state.reportTypeFilter,
        testDateFrom: state.testDateFrom,
        testDateTo: state.testDateTo,
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

  Future<void> deleteReport(LabReport report) async {
    final uid = _uid;
    if (uid == null) return;
    state = state.copyWith(deletingReportId: report.id, clearError: true);
    try {
      final repo = ref.read(labReportRepositoryProvider);
      final res = await repo.deleteReport(
        userId: uid,
        reportId: report.id,
        attachmentUrls: report.attachments.map((e) => e.url).toList(),
      );
      if (!res.success) {
        state = state.copyWith(
          clearDeleting: true,
          error: res.errorMessage ?? 'Could not delete report.',
        );
        return;
      }
      state = state.copyWith(
        clearDeleting: true,
        items: state.items.where((e) => e.id != report.id).toList(),
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
        items: const <LabReport>[],
        hasMore: false,
        clearCursor: true,
      );
      return;
    }

    state = state.copyWith(
      isInitialLoading: true,
      clearError: true,
      items: preserveItems ? state.items : const <LabReport>[],
      clearCursor: true,
      hasMore: true,
    );

    try {
      final repo = ref.read(labReportRepositoryProvider);
      final page = await repo.getReportsPage(
        userId: uid,
        reportType: state.reportTypeFilter,
        testDateFrom: state.testDateFrom,
        testDateTo: state.testDateTo,
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
