import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/services/debouncer.dart';

void main() {
  test('Debouncer emits only last value after duration', () async {
    final values = <String>[];
    final d = Debouncer(
      duration: const Duration(milliseconds: 50),
      onValue: values.add,
    );

    d('a');
    d('b');
    d('c');

    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(values, ['c']);
    d.dispose();
  });
}
