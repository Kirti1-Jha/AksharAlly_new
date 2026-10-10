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

    test('matches repeat and speed commands in the selected language', () {
      expect(
        VoiceCommandHandler.parse(
          'Repeat the passage!',
          languageCode: 'en-US',
        ),
        VoiceCommandIntent.repeatPassage,
      );
      expect(
        VoiceCommandHandler.parse('read slower', languageCode: 'en'),
        VoiceCommandIntent.decreaseSpeechRate,
      );
      expect(
        VoiceCommandHandler.parse('पढ़ने की गति बढ़ाएं', languageCode: 'hi-IN'),
        VoiceCommandIntent.increaseSpeechRate,
      );
      expect(
        VoiceCommandHandler.parse('हळू वाचा।', languageCode: 'mr-IN'),
        VoiceCommandIntent.decreaseSpeechRate,
      );
      expect(
        VoiceCommandHandler.parse(
          'संपूर्ण उतारा पुन्हा वाचा',
          languageCode: 'mr',
        ),
        VoiceCommandIntent.repeatPassage,
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
      expect(
        VoiceCommandHandler.parse(
          'please pause reading now',
          languageCode: 'en',
        ),
        VoiceCommandIntent.unsupported,
      );
      expect(
        VoiceCommandHandler.parse('read slower', languageCode: 'mr'),
        VoiceCommandIntent.unsupported,
      );
      expect(
        VoiceCommandHandler.parse('next sentence', languageCode: 'en'),
        VoiceCommandIntent.unsupported,
      );
    });

    test('provides selected-language help for unsupported commands', () {
      expect(
        VoiceCommandHandler.unsupportedFeedback('mr-IN'),
        contains('हळू वाचा'),
      );
      expect(
        VoiceCommandHandler.unsupportedFeedback('en-US'),
        contains('Sentence navigation is not available yet'),
      );
    });
  });
}
