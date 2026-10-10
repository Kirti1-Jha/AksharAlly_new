import 'package:flutter_test/flutter_test.dart';
import 'package:aksharally_ui/services/voice_command_handler.dart';

void main() {
  group('VoiceCommandHandler', () {
    test('matches English reading commands despite punctuation', () {
      expect(
        VoiceCommandHandler.parse('Pause reading!', languageCode: 'en-US'),
        VoiceCommandIntent.pauseReading,
      );
      expect(
        VoiceCommandHandler.parse('Read this page.', languageCode: 'en'),
        VoiceCommandIntent.readCurrentPage,
      );
    });

    test('matches Hindi commands', () {
      expect(
        VoiceCommandHandler.parse('पढ़ना जारी रखें।', languageCode: 'hi-IN'),
        VoiceCommandIntent.resumeReading,
      );
      expect(
        VoiceCommandHandler.parse('फ़ॉन्ट बड़ा करें', languageCode: 'hi'),
        VoiceCommandIntent.increaseFontSize,
      );
    });

    test('matches Marathi commands', () {
      expect(
        VoiceCommandHandler.parse('वाचन बंद करा', languageCode: 'mr-IN'),
        VoiceCommandIntent.stopReading,
      );
      expect(
        VoiceCommandHandler.parse('पार्श्वभूमी बदला', languageCode: 'mr'),
        VoiceCommandIntent.changeColors,
      );
    });

    test('rejects ambiguous, combined, and unsupported phrases', () {
      expect(
        VoiceCommandHandler.parse(
          'pause reading and increase font size',
          languageCode: 'en',
        ),
        VoiceCommandIntent.unsupported,
      );
      expect(
        VoiceCommandHandler.parse('do something', languageCode: 'en'),
        VoiceCommandIntent.unsupported,
      );
      expect(
        VoiceCommandHandler.parse('read this page', languageCode: 'fr'),
        VoiceCommandIntent.unsupported,
      );
    });
  });
}
