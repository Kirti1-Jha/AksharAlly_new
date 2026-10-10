enum VoiceCommandIntent {
  readCurrentPage,
  pauseReading,
  resumeReading,
  stopReading,
  repeatSentence,
  increaseFontSize,
  decreaseFontSize,
  changeColors,
  unsupported,
}

/// Deterministic command matching for short reading-control phrases.
///
/// Matching is deliberately exact after punctuation and whitespace
/// normalization. A partial or multi-command phrase is rejected rather than
/// accidentally triggering an unrelated action.
class VoiceCommandHandler {
  static const Map<String, Map<VoiceCommandIntent, List<String>>> _phrases = {
    'en': {
      VoiceCommandIntent.readCurrentPage: [
        'read this page',
        'read page',
        'read this',
        'start reading',
        'read aloud',
        'start reading aloud',
      ],
      VoiceCommandIntent.pauseReading: ['pause', 'pause reading'],
      VoiceCommandIntent.resumeReading: [
        'resume',
        'resume reading',
        'continue reading',
        'continue',
      ],
      VoiceCommandIntent.stopReading: ['stop', 'stop reading'],
      VoiceCommandIntent.repeatSentence: [
        'repeat that sentence',
        'repeat the sentence',
        'repeat sentence',
      ],
      VoiceCommandIntent.increaseFontSize: [
        'increase font size',
        'make font bigger',
        'make text bigger',
        'increase text size',
      ],
      VoiceCommandIntent.decreaseFontSize: [
        'decrease font size',
        'make font smaller',
        'make text smaller',
        'decrease text size',
      ],
      VoiceCommandIntent.changeColors: [
        'change background color',
        'change background colour',
        'change text color',
        'change text colour',
        'change colors',
        'change colours',
        'next color theme',
        'next colour theme',
      ],
    },
    'hi': {
      VoiceCommandIntent.readCurrentPage: [
        'यह पेज पढ़ें',
        'इस पृष्ठ को पढ़ें',
        'पढ़ना शुरू करें',
        'पढ़कर सुनाएं',
      ],
      VoiceCommandIntent.pauseReading: ['पढ़ना रोकें', 'पढ़ना रोक दीजिए'],
      VoiceCommandIntent.resumeReading: [
        'पढ़ना जारी रखें',
        'फिर से पढ़ना शुरू करें',
        'जारी रखें',
      ],
      VoiceCommandIntent.stopReading: ['पढ़ना बंद करें', 'पढ़ना बंद करो'],
      VoiceCommandIntent.repeatSentence: [
        'यह वाक्य दोहराएं',
        'वाक्य दोहराएं',
        'फिर से वाक्य पढ़ें',
      ],
      VoiceCommandIntent.increaseFontSize: [
        'अक्षर का आकार बढ़ाएं',
        'फॉन्ट बड़ा करें',
        'फ़ॉन्ट बड़ा करें',
        'अक्षर बड़े करें',
        'टेक्स्ट बड़ा करें',
      ],
      VoiceCommandIntent.decreaseFontSize: [
        'अक्षर का आकार घटाएं',
        'फॉन्ट छोटा करें',
        'फ़ॉन्ट छोटा करें',
        'अक्षर छोटे करें',
        'टेक्स्ट छोटा करें',
      ],
      VoiceCommandIntent.changeColors: [
        'रंग बदलें',
        'पृष्ठभूमि का रंग बदलें',
        'पृष्ठभूमि बदलें',
        'टेक्स्ट का रंग बदलें',
      ],
    },
    'mr': {
      VoiceCommandIntent.readCurrentPage: [
        'हे पान वाचा',
        'हे पृष्ठ वाचा',
        'वाचायला सुरू करा',
        'मोठ्याने वाचा',
      ],
      VoiceCommandIntent.pauseReading: [
        'वाचन थोडावेळ थांबवा',
        'थोडा वेळ थांबा',
      ],
      VoiceCommandIntent.resumeReading: [
        'वाचन पुन्हा सुरू करा',
        'वाचणे सुरू ठेवा',
        'पुढे वाचा',
      ],
      VoiceCommandIntent.stopReading: ['वाचन बंद करा', 'वाचन थांबवा'],
      VoiceCommandIntent.repeatSentence: [
        'हे वाक्य पुन्हा वाचा',
        'वाक्य पुन्हा सांगा',
        'वाक्य पुन्हा वाचा',
      ],
      VoiceCommandIntent.increaseFontSize: [
        'अक्षरांचा आकार वाढवा',
        'फॉन्ट मोठा करा',
        'मजकूर मोठा करा',
      ],
      VoiceCommandIntent.decreaseFontSize: [
        'अक्षरांचा आकार कमी करा',
        'फॉन्ट लहान करा',
        'मजकूर लहान करा',
      ],
      VoiceCommandIntent.changeColors: [
        'रंग बदला',
        'पार्श्वभूमीचा रंग बदला',
        'पार्श्वभूमी बदला',
        'मजकुराचा रंग बदला',
      ],
    },
  };

  static VoiceCommandIntent parse(
    String transcript, {
    required String languageCode,
  }) {
    final language = languageCode
        .toLowerCase()
        .replaceAll('_', '-')
        .split('-')
        .first;
    final commands = _phrases[language];
    if (commands == null) return VoiceCommandIntent.unsupported;

    final normalized = _normalize(transcript);
    if (normalized.isEmpty) return VoiceCommandIntent.unsupported;

    for (final entry in commands.entries) {
      if (entry.value.any((phrase) => _normalize(phrase) == normalized)) {
        return entry.key;
      }
    }
    return VoiceCommandIntent.unsupported;
  }

  static String _normalize(String value) {
    var normalized = value.toLowerCase();
    for (final punctuation in const [
      '.',
      ',',
      '!',
      '?',
      ';',
      ':',
      '(',
      ')',
      '[',
      ']',
      '{',
      '}',
      '"',
      '“',
      '”',
      '‘',
      '’',
      '।',
      '॥',
      '…',
    ]) {
      normalized = normalized.replaceAll(punctuation, ' ');
    }
    return normalized.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
