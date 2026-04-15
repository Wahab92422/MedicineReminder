import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/medicines/medicine_controller.dart';
import 'package:medicine_app/features/medicines/medicine_model.dart';

void main() {
  test('medicinesForDailyReminderScheduling keeps repeatDaily only', () {
    final meds = [
      Medicine(
        id: '1',
        name: 'A',
        dose: '1',
        time: '09:00',
        userId: 'u',
        repeatDaily: false,
      ),
      Medicine(
        id: '2',
        name: 'B',
        dose: '1',
        time: '10:00',
        userId: 'u',
      ),
    ];

    final eligible = medicinesForDailyReminderScheduling(meds);
    expect(eligible, hasLength(1));
    expect(eligible.single.id, '2');
  });
}
