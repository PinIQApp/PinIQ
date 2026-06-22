// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

void speakWorkoutCue(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return;

  final synth = html.window.speechSynthesis;
  if (synth == null) return;

  final utterance = html.SpeechSynthesisUtterance(trimmed)
    ..lang = 'en-US'
    ..rate = 1.0
    ..pitch = 1.0
    ..volume = 1.0;
  synth.cancel();
  synth.speak(utterance);
}

void stopWorkoutCue() {
  final synth = html.window.speechSynthesis;
  if (synth == null) return;
  synth.cancel();
}
