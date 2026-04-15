import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/labs/lab_model.dart';

void main() {
  group('labFileBadgeFromExtension', () {
    test('maps known extensions', () {
      expect(labFileBadgeFromExtension('pdf'), LabFileBadge.pdf);
      expect(labFileBadgeFromExtension('.PDF'), LabFileBadge.pdf);
      expect(labFileBadgeFromExtension('png'), LabFileBadge.image);
      expect(labFileBadgeFromExtension('docx'), LabFileBadge.doc);
      expect(labFileBadgeFromExtension('xlsx'), LabFileBadge.spreadsheet);
      expect(labFileBadgeFromExtension('zip'), LabFileBadge.archive);
    });

    test('empty or unknown maps to other', () {
      expect(labFileBadgeFromExtension(''), LabFileBadge.other);
      expect(labFileBadgeFromExtension('dcm'), LabFileBadge.other);
    });
  });
}
