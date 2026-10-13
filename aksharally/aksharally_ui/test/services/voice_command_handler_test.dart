import 'package:aksharally_ui/services/voice_command_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceCommandHandler', () {
    test(
      'normalizes supported English commands without matching fragments',
      () {
        expect(
          VoiceCommandHandler.parse(
            '  READ   THIS PAGE! ',
            languageCode: 'en-IN',
          ),
          VoiceCommandIntent.readCurrentPage,
        );
        expect(
          VoiceCommandHandler.parse('pause reading now', languageCode: 'en'),
          VoiceCommandIntent.unsupported,
        );
      },
    );

    test(
      'recognizes Hindi and Marathi commands by their selected language',
      () {
        expect(
          VoiceCommandHandler.parse('पढ़ना रोकें', languageCode: 'hi-IN'),
          VoiceCommandIntent.pauseReading,
        );
        expect(
          VoiceCommandHandler.parse('हळू वाचा', languageCode: 'mr-IN'),
          VoiceCommandIntent.decreaseSpeechRate,
        );
      },
    );

    test('provides language-specific feedback for unsupported commands', () {
      expect(
        VoiceCommandHandler.unsupportedFeedback('hi-IN'),
        contains('यह कमांड समझ नहीं आया'),
      );
      expect(
        VoiceCommandHandler.unsupportedFeedback('mr-IN'),
        contains('हा आदेश समजला नाही'),
      );
    });
  });
}
