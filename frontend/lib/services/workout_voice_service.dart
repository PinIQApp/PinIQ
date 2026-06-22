import 'workout_voice_service_stub.dart'
    if (dart.library.html) 'workout_voice_service_web.dart' as impl;

void speakWorkoutCue(String message) => impl.speakWorkoutCue(message);

void stopWorkoutCue() => impl.stopWorkoutCue();
