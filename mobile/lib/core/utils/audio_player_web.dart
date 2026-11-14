// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Plays notification audio on Flutter Web respecting browser autoplay policies.
void playWebAudio(String assetPath) {
  try {
    final audio = html.AudioElement(assetPath);
    audio.play().catchError((error) {
      // Gracefully catch browser autoplay restrictions (NotAllowedError)
      // Browsers disallow unprompted audio until user interacts with the page.
    });
  } catch (_) {
    // Graceful fallback if audio element initialization fails
  }
}
