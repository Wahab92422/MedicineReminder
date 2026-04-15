import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Requests [MainShell] to select a bottom-nav index (e.g. open Medicines from Insights).
final shellTabRequestProvider =
    NotifierProvider<ShellTabRequestNotifier, int?>(ShellTabRequestNotifier.new);

class ShellTabRequestNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void requestTab(int index) {
    state = index;
  }

  void clear() {
    state = null;
  }
}
