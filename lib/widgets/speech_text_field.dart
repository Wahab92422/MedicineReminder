import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../theme/app_spacing.dart';
import '../utils/speech_text_merge.dart';

final stt.SpeechToText _speech = stt.SpeechToText();
bool _speechInitAttempted = false;
bool _speechReady = false;

/// Multiline text field with typing and optional speech-to-text (mic).
/// Matches [CustomTextField] decoration; adds a dictate control when speech is available.
class SpeechTextField extends StatefulWidget {
  const SpeechTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.maxLines = 4,
    this.textInputAction,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final int maxLines;
  final TextInputAction? textInputAction;
  final bool autocorrect;

  @override
  State<SpeechTextField> createState() => _SpeechTextFieldState();
}

class _SpeechTextFieldState extends State<SpeechTextField> {
  bool _listening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    if (_speechInitAttempted) {
      if (mounted) setState(() => _speechAvailable = _speechReady);
      return;
    }
    _speechInitAttempted = true;
    final ok = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _speechAvailable = false);
      },
      onStatus: (status) {
        if (status == stt.SpeechToText.notListeningStatus ||
            status == stt.SpeechToText.doneStatus) {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    _speechReady = ok;
    if (mounted) setState(() => _speechAvailable = ok);
  }

  Future<void> _toggleDictation() async {
    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) return;
    }
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    if (mounted) setState(() => _listening = true);

    await _speech.listen(
      onResult: (result) {
        if (!result.finalResult) return;
        final merged = appendDictatedPhrase(
          widget.controller.text,
          result.recognizedWords,
        );
        widget.controller.value = TextEditingValue(
          text: merged,
          selection: TextSelection.collapsed(offset: merged.length),
        );
        if (mounted) setState(() {});
      },
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 4),
      listenOptions: stt.SpeechListenOptions(
        partialResults: false,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  @override
  void dispose() {
    if (_listening) {
      _speech.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: widget.controller,
      maxLines: widget.maxLines,
      keyboardType: TextInputType.multiline,
      textInputAction: widget.textInputAction ?? TextInputAction.newline,
      autocorrect: widget.autocorrect,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        alignLabelWithHint: true,
        suffixIcon: _speechAvailable
            ? Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: IconButton(
                  tooltip: _listening ? 'Stop dictation' : 'Dictate',
                  onPressed: _toggleDictation,
                  icon: Icon(
                    _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _listening
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              )
            : null,
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }
}
