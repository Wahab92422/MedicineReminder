import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/utils/speech_text_merge.dart';

void main() {
  group('appendDictatedPhrase', () {
    test('empty existing uses phrase only', () {
      expect(appendDictatedPhrase('', 'hello'), 'hello');
      expect(appendDictatedPhrase('   ', 'hello'), 'hello');
    });

    test('empty phrase leaves existing', () {
      expect(appendDictatedPhrase('a', '  '), 'a');
    });

    test('adds space between words', () {
      expect(appendDictatedPhrase('Hi', 'there'), 'Hi there');
    });

    test('no extra space if existing ends with space', () {
      expect(appendDictatedPhrase('Hi ', 'there'), 'Hi there');
    });

    test('newline does not add space', () {
      expect(appendDictatedPhrase('Line1\n', 'Line2'), 'Line1\nLine2');
    });
  });
}
