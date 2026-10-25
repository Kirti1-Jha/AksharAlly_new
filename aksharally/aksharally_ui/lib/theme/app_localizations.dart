import 'app_settings.dart';

/// Small shared English/Hindi string catalog for the app's interface.
///
/// Reading content and the user's OCR/reading-language preference are kept
/// separate from these interface labels.
class AppLocalizations {
  AppLocalizations._();

  static bool get isHindi => AppSettings.interfaceLanguage == 'hi';

  static String text(String english) {
    if (!isHindi) return english;

    final translated = _hindi[english];
    if (translated != null) return translated;

    const dynamicPrefixes = [
      'Unable to process the image:',
      'Connection failed:',
      'Could not start speech recognition:',
      'Could not listen:',
      'Could not process that command:',
      'Speech recognition error:',
    ];
    for (final prefix in dynamicPrefixes) {
      if (english.startsWith(prefix)) {
        final detail = english.substring(prefix.length).trimLeft();
        return '${_hindi[prefix]} ${text(detail)}';
      }
    }
    return english;
  }

  static String choose(String english, String hindi) =>
      isHindi ? hindi : english;

  static String explanation(String setting) {
    final explanations = isHindi ? _hindiExplanations : _englishExplanations;
    return explanations[setting] ?? '';
  }

  static const Map<String, String> _englishExplanations = {
    'Reading profile':
        'Choose a reading profile to set comfortable text and spacing.',
    'Font Family': 'Choose the font you would feel the most comfortable with.',
    'Font Size': 'Adjust how large the reading text appears.',
    'Letter Spacing': 'Adjust the space between letters.',
    'Word Spacing': 'Adjust the space between words.',
    'Line Height': 'Adjust the space between lines.',
    'Paragraph Spacing': 'Adjust the space between paragraphs.',
    'Color Theme': 'Choose a background and text colour combination.',
    'Accessibility Features':
        'Turn reading and visual accessibility features on or off.',
    'Word Highlighting during TTS':
        'Highlight each word as it is spoken aloud.',
    'Auto Read': 'Automatically start reading new content aloud.',
    'Focus Window': 'Dim surrounding text to help you follow one line.',
    'Syllable Breakdown (Experimental)':
        'Show breaks between syllables to make longer words easier to read.',
    'Larger Touch Targets':
        'Make buttons and controls easier to tap.',
    'Reduce Motion / Animations':
        'Reduce movement and animation on the reading screen.',
    'Interface language':
        'Choose the language used for app menus and messages.',
    'Dyslexia Profiles':
        'Choose a preset with a comfortable font, spacing, and colours.',
    'Typography': 'Adjust the app font and text spacing.',
    'Colour Themes': 'Choose a background and text colour combination.',
    'Color Themes': 'Choose a background and text colour combination.',
    'Text Colour': 'Choose the colour used for text.',
    'Background Colour': 'Choose the page background colour.',
    'Accessibility Options':
        'Adjust visual comfort and touch accessibility settings.',
    'Bold UI Text': 'Make app interface text bolder.',
    'Reduced Animations': 'Reduce animation throughout the app.',
    'High Contrast Mode': 'Increase contrast in app interface text.',
    'Reading language': 'Choose the language of the text you want to read.',
    'Interface language setting':
        'Choose the language used for app menus and messages.',
    'Reading History': 'Review and manage your saved readings.',
    'Account': 'Manage your current AksharAlly session.',
    'Customize Reading Experience':
        'Adjust fonts, spacing, colours, and accessibility features for a more comfortable reading experience.',
    'Live Preview':
        'Preview your current accessibility settings before applying them.',
  };

  static const Map<String, String> _hindiExplanations = {
    'Reading profile':
        'पाठ और दूरी को आरामदायक बनाने के लिए पढ़ने की शैली चुनें।',
    'Font Family': 'वह फ़ॉन्ट चुनें जिसमें आपको पढ़ना सबसे आरामदायक लगे।',
    'Font Size': 'पढ़ने वाले पाठ का आकार बदलें।',
    'Letter Spacing': 'अक्षरों के बीच की दूरी बदलें।',
    'Word Spacing': 'शब्दों के बीच की दूरी बदलें।',
    'Line Height': 'पंक्तियों के बीच की दूरी बदलें।',
    'Paragraph Spacing': 'अनुच्छेदों के बीच की दूरी बदलें।',
    'Color Theme': 'पृष्ठभूमि और पाठ के रंगों का संयोजन चुनें।',
    'Accessibility Features':
        'पढ़ने और देखने की सुलभता सुविधाएँ चालू या बंद करें।',
    'Word Highlighting during TTS':
        'आवाज़ में पढ़े जा रहे हर शब्द को हाइलाइट करें।',
    'Auto Read': 'नई सामग्री खुलने पर उसे अपने-आप पढ़ें।',
    'Focus Window': 'एक पंक्ति पर ध्यान रखने के लिए आसपास के पाठ को धुँधला करें।',
    'Syllable Breakdown (Experimental)':
        'लंबे शब्दों को पढ़ना आसान बनाने के लिए अक्षरों के बीच विराम दिखाएँ।',
    'Larger Touch Targets': 'बटन और नियंत्रणों को छूना आसान बनाएँ।',
    'Reduce Motion / Animations':
        'रीडिंग स्क्रीन पर गति और एनिमेशन कम करें।',
    'Interface language':
        'ऐप के मेनू और संदेशों की भाषा चुनें।',
    'Dyslexia Profiles':
        'आरामदायक फ़ॉन्ट, दूरी और रंगों वाली शैली चुनें।',
    'Typography': 'ऐप का फ़ॉन्ट और पाठ की दूरी बदलें।',
    'Colour Themes': 'पृष्ठभूमि और पाठ के रंगों का संयोजन चुनें।',
    'Color Themes': 'पृष्ठभूमि और पाठ के रंगों का संयोजन चुनें।',
    'Text Colour': 'पाठ का रंग चुनें।',
    'Background Colour': 'पृष्ठ का पृष्ठभूमि रंग चुनें।',
    'Accessibility Options':
        'देखने के आराम और टच सुलभता की सेटिंग बदलें।',
    'Bold UI Text': 'ऐप के इंटरफ़ेस का पाठ मोटा करें।',
    'Reduced Animations': 'ऐप में एनिमेशन कम करें।',
    'High Contrast Mode': 'ऐप के इंटरफ़ेस के पाठ का कंट्रास्ट बढ़ाएँ।',
    'Reading language': 'पढ़ी जाने वाली सामग्री की भाषा चुनें।',
    'Interface language setting':
        'ऐप के मेनू और संदेशों की भाषा चुनें।',
    'Reading History': 'सहेजी गई रीडिंग देखें और प्रबंधित करें।',
    'Account': 'अपने मौजूदा AksharAlly सत्र का प्रबंधन करें।',
    'Customize Reading Experience':
        'आरामदायक पढ़ने के लिए फ़ॉन्ट, दूरी, रंग और सुलभता सुविधाएँ बदलें।',
    'Live Preview':
        'लागू करने से पहले अपनी मौजूदा सुलभता सेटिंग का पूर्वावलोकन करें।',
  };

  static const Map<String, String> _hindi = {
    'Choose language': 'भाषा चुनें',
    'Welcome to AksharAlly, your personalised reading companion. Read with confidence. Select Let’s Begin to get started.':
        'अक्षरअली में आपका स्वागत है, आपका व्यक्तिगत पढ़ने का साथी। आत्मविश्वास के साथ पढ़ें। शुरू करने के लिए “शुरू करें” चुनें।',
    'Read with confidence.': 'आत्मविश्वास के साथ पढ़ें।',
    'Let’s Begin': 'शुरू करें',
    'Let\'s Begin': 'शुरू करें',
    'Repeat welcome message': 'स्वागत संदेश दोहराएँ',
    'Voice assistant on': 'वॉइस सहायक चालू',
    'Voice assistant off': 'वॉइस सहायक बंद',
    'Voice on': 'वॉइस चालू',
    'Voice off': 'वॉइस बंद',
    'AksharAlly logo': 'अक्षरअली लोगो',
    'Login': 'लॉग इन',
    'Register': 'पंजीकरण',
    'Welcome Back!': 'वापसी पर स्वागत है!',
    'Create Account': 'खाता बनाएँ',
    'Sign in to continue reading.': 'पढ़ना जारी रखने के लिए लॉग इन करें।',
    'Create your account to personalise your reading.':
        'पढ़ने का अनुभव व्यक्तिगत बनाने के लिए अपना खाता बनाएँ।',
    'Email': 'ईमेल',
    'Password': 'पासवर्ड',
    'Show password': 'पासवर्ड दिखाएँ',
    'Hide password': 'पासवर्ड छिपाएँ',
    'Or continue with': 'या इसके साथ जारी रखें',
    'Continue with Google': 'Google के साथ जारी रखें',
    'Continue with Apple': 'Apple के साथ जारी रखें',
    'Please enter email & password': 'कृपया ईमेल और पासवर्ड दर्ज करें',
    'That email is already registered. Try logging in instead.':
        'यह ईमेल पहले से पंजीकृत है। इसके बजाय लॉग इन करें।',
    'Please enter a valid email address.':
        'कृपया मान्य ईमेल पता दर्ज करें।',
    'Choose a stronger password with at least 6 characters.':
        'कम-से-कम 6 अक्षरों वाला मज़बूत पासवर्ड चुनें।',
    'The email or password is incorrect.':
        'ईमेल या पासवर्ड गलत है।',
    'No account was found for that email.':
        'इस ईमेल के लिए कोई खाता नहीं मिला।',
    'Network error. Check your connection and try again.':
        'नेटवर्क त्रुटि। अपना कनेक्शन जाँचें और फिर कोशिश करें।',
    'An account already exists with a different sign-in method.':
        'इस खाते के लिए कोई दूसरा साइन-इन तरीका पहले से मौजूद है।',
    'This sign-in method is not enabled in Firebase yet.':
        'यह साइन-इन तरीका अभी Firebase में चालू नहीं है।',
    'Too many attempts. Please wait a moment and try again.':
        'बहुत ज़्यादा कोशिशें हुईं। थोड़ी देर बाद फिर कोशिश करें।',
    'Authentication failed. Please try again.':
        'प्रमाणीकरण विफल हुआ। कृपया फिर कोशिश करें।',
    'Apple Sign-In is not configured for this device yet.':
        'इस डिवाइस पर Apple से साइन-इन अभी कॉन्फ़िगर नहीं है।',
    'Apple Sign-In on Android needs its Apple service configuration.':
        'Android पर Apple से साइन-इन के लिए Apple सेवा कॉन्फ़िगरेशन चाहिए।',
    'Something went wrong. Please try again.':
        'कुछ गड़बड़ हुई। कृपया फिर कोशिश करें।',
    'Voice assistance is unavailable on this device.':
        'इस डिवाइस पर वॉइस सहायता उपलब्ध नहीं है।',
    'Voice assistant could not read this screen. Turn it off and on to retry.':
        'वॉइस सहायक यह स्क्रीन नहीं पढ़ सका। फिर कोशिश करने के लिए इसे बंद करके चालू करें।',
    'Home': 'होम',
    'Library': 'पुस्तकालय',
    'Settings': 'सेटिंग्स',
    'Listen to explanation': 'विवरण सुनें',
    'On': 'चालू',
    'Off': 'बंद',
    'Cream': 'क्रीम',
    'Black': 'काला',
    'Dark gray': 'गहरा धूसर',
    'Charcoal': 'चारकोल',
    'Brown': 'भूरा',
    'Indigo': 'इंडिगो',
    'Dark green': 'गहरा हरा',
    'Burgundy': 'बरगंडी',
    'Pale yellow': 'हल्का पीला',
    'Pale blue': 'हल्का नीला',
    'Pale green': 'हल्का हरा',
    'Peach': 'आड़ू रंग',
    'Lavender': 'लैवेंडर',
    'White': 'सफ़ेद',
    'Purple': 'बैंगनी',
    'Pink': 'गुलाबी',
    'Font Family': 'फ़ॉन्ट परिवार',
    'Font Size': 'फ़ॉन्ट आकार',
    'Letter Spacing': 'अक्षरों के बीच दूरी',
    'Word Spacing': 'शब्दों के बीच दूरी',
    'Line Height': 'पंक्ति की ऊँचाई',
    'Paragraph Spacing': 'अनुच्छेदों के बीच दूरी',
    'OpenDyslexic': 'ओपनडिस्लेक्सिक',
    'Lexend': 'लेक्सेंड',
    'Atkinson': 'एटकिंसन',
    'Atkinson Hyperlegible': 'एटकिंसन हाइपरलेजेबल',
    'Noto Sans': 'नोटो सैन्स',
    'Inter': 'इंटर',
    'Roboto': 'रोबोटो',
    'Comic Neue': 'कॉमिक न्यू',
    'Verdana': 'वर्दाना',
    'Tahoma': 'तहोमा',
    'Arial': 'एरियल',
    'Georgia': 'जॉर्जिया',
    'Trebuchet MS': 'ट्रेबुशेट एमएस',
    'Mukta': 'मुक्ता',
    'Noto Sans Devanagari': 'नोटो सैन्स देवनागरी',
    'Hind': 'हिंद',
    'Baloo 2': 'बालू 2',
    'Tiro Devanagari Hindi': 'टिरो देवनागरी हिंदी',
    'System Default': 'सिस्टम डिफ़ॉल्ट',
    'OpenDyslexic · Cream · Generous spacing':
        'ओपनडिस्लेक्सिक · क्रीम · अधिक दूरी',
    'Inter · Soft Yellow · Reduced glare':
        'इंटर · हल्का पीला · कम चमक',
    'Monospace · White · Large, spaced text':
        'मोनोस्पेस · सफ़ेद · बड़ा और दूर-दूर पाठ',
    'OpenDyslexic · Light Blue · Very large text':
        'ओपनडिस्लेक्सिक · हल्का नीला · बहुत बड़ा पाठ',
    'pixels': 'पिक्सेल',
    'Font Family': 'फ़ॉन्ट परिवार',
    'Selected color': 'चुना हुआ रंग',
    'Hindi': 'हिंदी',
    'Marathi': 'मराठी',
    'English': 'अंग्रेज़ी',
    'Good Morning': 'सुप्रभात',
    'Good Afternoon': 'नमस्कार',
    'Good Evening': 'शुभ संध्या',
    'Welcome Back': 'वापसी पर स्वागत है',
    'New Reading': 'नई रीडिंग',
    'Scan, type, or upload content for dyslexia-friendly reading.':
        'डिस्लेक्सिया-अनुकूल पढ़ने के लिए सामग्री स्कैन करें, टाइप करें या अपलोड करें।',
    'Total Readings': 'कुल रीडिंग',
    'Continue Reading': 'पढ़ना जारी रखें',
    'No readings yet — start one above.':
        'अभी कोई रीडिंग नहीं है — ऊपर से शुरू करें।',
    'Image': 'छवि',
    'Document': 'दस्तावेज़',
    'Typed Text': 'टाइप किया गया पाठ',
    'Simplified Text': 'सरल किया गया पाठ',
    'Just now': 'अभी',
    'Yesterday': 'कल',
    'Accessibility Center': 'सुलभता केंद्र',
    'Customise how AksharAlly looks — preview changes before applying.':
        'अक्षरअली का रूप बदलें — लागू करने से पहले बदलावों का पूर्वावलोकन करें।',
    'Dyslexia Profiles': 'डिस्लेक्सिया प्रोफ़ाइल',
    'Choose a starting point optimised for your accessibility needs.':
        'अपनी सुलभता आवश्यकताओं के अनुसार शुरुआती विकल्प चुनें।',
    'Accessibility Options': 'सुलभता विकल्प',
    'Further settings for visual comfort and motor accessibility.':
        'दृश्य आराम और उपयोग-सुलभता के लिए अतिरिक्त सेटिंग्स।',
    'Bold UI Text': 'इंटरफ़ेस का पाठ मोटा करें',
    'Reduced Animations': 'एनिमेशन कम करें',
    'Larger Touch Targets': 'बड़े टच क्षेत्र',
    'High Contrast Mode': 'उच्च कंट्रास्ट मोड',
    'Reading language': 'पढ़ने की सामग्री की भाषा',
    'Interface language': 'इंटरफ़ेस की भाषा',
    'Typography': 'टाइपोग्राफी',
    'Color Themes': 'रंग थीम',
    'Custom Appearance': 'कस्टम रूप',
    'Live Preview': 'लाइव पूर्वावलोकन',
    'Language': 'भाषा',
    'Reading History': 'पढ़ने का इतिहास',
    'Account': 'खाता',
    'Most Popular': 'सबसे लोकप्रिय',
    'High Contrast': 'उच्च कंट्रास्ट',
    'Dyslexia Recommended': 'डिस्लेक्सिया के लिए सुझाया गया',
    'Extreme Contrast': 'अत्यधिक कंट्रास्ट',
    'Study Mode': 'अध्ययन मोड',
    'हिंदी': 'हिंदी',
    'Reset to Default': 'डिफ़ॉल्ट पर रीसेट करें',
    'Changes not yet applied': 'बदलाव अभी लागू नहीं हुए हैं',
    'The Live Preview below reflects your selections. Press Apply Now to update the entire app.':
        'नीचे का लाइव पूर्वावलोकन आपके चयन दिखाता है। पूरे ऐप में बदलाव लागू करने के लिए “अभी लागू करें” दबाएँ।',
    'Reset Preview': 'पूर्वावलोकन रीसेट करें',
    'Apply Now': 'अभी लागू करें',
    'Reflects your current selections only. Press Apply Now to update the app.':
        'यह केवल आपके मौजूदा चयन दिखाता है। ऐप में बदलाव लागू करने के लिए “अभी लागू करें” दबाएँ।',
    'Clear Reading History': 'पढ़ने का इतिहास मिटाएँ',
    'Clear reading history?': 'पढ़ने का इतिहास मिटाएँ?',
    'Cancel': 'रद्द करें',
    'Clear All': 'सभी मिटाएँ',
    'Reading history cleared.': 'पढ़ने का इतिहास मिटा दिया गया।',
    'Reading history is already empty.': 'पढ़ने का इतिहास पहले से खाली है।',
    'Manage your current AksharAlly session.': 'अपने मौजूदा अक्षरअली सत्र का प्रबंधन करें।',
    'Log Out': 'लॉग आउट',
    'Log out?': 'लॉग आउट करें?',
    'Are you sure you want to log out of AksharAlly?':
        'क्या आप वाकई अक्षरअली से लॉग आउट करना चाहते हैं?',
    'Unable to log out right now. Please try again.':
        'अभी लॉग आउट नहीं हो सका। कृपया फिर से प्रयास करें।',
    'Delete reading?': 'रीडिंग मिटाएँ?',
    'Delete': 'मिटाएँ',
    'No saved readings yet': 'अभी कोई रीडिंग सहेजी नहीं गई है',
    'will be permanently removed from your library.':
        'आपकी लाइब्रेरी से हमेशा के लिए हटा दी जाएगी।',
    'Scan': 'स्कैन',
    'Type': 'टाइप करें',
    'Upload': 'अपलोड',
    'Camera': 'कैमरा',
    'Gallery': 'गैलरी',
    'No image selected yet.\nUse Camera or Gallery above.':
        'अभी कोई छवि नहीं चुनी गई।\nऊपर कैमरा या गैलरी चुनें।',
    'Type or paste your text here…': 'यहाँ पाठ टाइप या पेस्ट करें…',
    'Choose File  (PDF · DOCX · TXT · Image)':
        'फ़ाइल चुनें (PDF · DOCX · TXT · छवि)',
    'No file selected yet.\nSupports PDF, DOCX, TXT, and images.':
        'अभी कोई फ़ाइल नहीं चुनी गई।\nPDF, DOCX, TXT और छवियाँ समर्थित हैं।',
    'Processing Mode': 'प्रोसेसिंग मोड',
    'Format Only': 'केवल फ़ॉर्मैट करें',
    'Dyslexia-friendly layout. No AI. Words never changed.':
        'डिस्लेक्सिया-अनुकूल रूप। AI नहीं। शब्द नहीं बदले जाएँगे।',
    'Simplify + Format': 'सरल करें + फ़ॉर्मैट करें',
    'AI simplifies the text, then formats it for easier reading.':
        'AI पाठ को सरल बनाता है, फिर पढ़ने में आसानी के लिए फ़ॉर्मैट करता है।',
    'Continue': 'जारी रखें',
    'Image selected': 'छवि चुनी गई',
    'File selected': 'फ़ाइल चुनी गई',
    'Ready to process': 'प्रोसेस करने के लिए तैयार',
    'Remove': 'हटाएँ',
    'Clear': 'साफ़ करें',
    'Start': 'शुरू करें',
    'Stop': 'रोकें',
    'Pause': 'विराम दें',
    'Resume': 'फिर शुरू करें',
    'Nothing to read yet': 'अभी पढ़ने के लिए कुछ नहीं है',
    'Go back and scan, type, or upload some content first.':
        'पहले वापस जाकर सामग्री स्कैन करें, टाइप करें या अपलोड करें।',
    'Go Back': 'वापस जाएँ',
    'View original OCR': 'मूल OCR देखें',
    'Profile': 'प्रोफ़ाइल',
    'Font': 'फ़ॉन्ट',
    'Size': 'आकार',
    'Letter': 'अक्षर',
    'Word': 'शब्द',
    'Line': 'पंक्ति',
    'Para': 'अनुच्छेद',
    'Theme': 'थीम',
    'Mild': 'हल्का',
    'Moderate': 'मध्यम',
    'Severe': 'गंभीर',
    'Mild profile description':
        'आरामदायक शुरुआत के लिए हल्की दूरी और क्रीम पृष्ठभूमि।',
    'Moderate profile description':
        'आसान पढ़ने के लिए बड़ा पाठ, अधिक दूरी और हल्की पीली पृष्ठभूमि।',
    'Severe profile description':
        'अधिक सहायता के लिए बहुत बड़ा पाठ, अधिक दूरी और उच्च-कंट्रास्ट सफ़ेद पृष्ठभूमि।',
    'Customize Reading Experience': 'पढ़ने का अनुभव अपने अनुसार बदलें',
    'English Reading Fonts': 'अंग्रेज़ी पढ़ने के फ़ॉन्ट',
    'Hindi & Marathi Fonts': 'हिंदी और मराठी फ़ॉन्ट',
    'Reading Test Preview': 'पढ़ने के नमूने का पूर्वावलोकन',
    'pixels': 'पिक्सेल',
    'times': 'गुना',
    'Customize': 'अपने अनुसार बदलें',
    'Custom': 'कस्टम',
    'reading profile': 'रीडिंग प्रोफ़ाइल',
    'reading font': 'पढ़ने का फ़ॉन्ट',
    'color theme': 'रंग थीम',
    'Playback speed': 'पढ़ने की गति',
    'Previous section': 'पिछला अनुभाग',
    'Next section': 'अगला अनुभाग',
    'Original OCR': 'मूल OCR',
    'Save as Default': 'डिफ़ॉल्ट के रूप में सहेजें',
    'Delete reading': 'रीडिंग मिटाएँ',
    'Enter Text': 'पाठ दर्ज करें',
    'Type or paste text here...': 'यहाँ पाठ टाइप या पेस्ट करें...',
    'Simplify Text': 'पाठ सरल करें',
    'Upload File': 'फ़ाइल अपलोड करें',
    'Choose File': 'फ़ाइल चुनें',
    'Format File': 'फ़ाइल फ़ॉर्मैट करें',
    'Please enter some text first': 'कृपया पहले कुछ पाठ दर्ज करें',
    'Please select a file first': 'कृपया पहले फ़ाइल चुनें',
    'Please enter some text before continuing.':
        'जारी रखने से पहले कृपया कुछ पाठ दर्ज करें।',
    'Please capture or select an image first.':
        'कृपया पहले छवि लें या चुनें।',
    'Please select a file first.': 'कृपया पहले फ़ाइल चुनें।',
    'Could not open file picker.': 'फ़ाइल चुनने का विकल्प नहीं खुल सका।',
    'The camera did not return a readable image.':
        'कैमरे से पढ़ने योग्य छवि नहीं मिली।',
    'The captured image is empty. Please scan it again.':
        'ली गई छवि खाली है। कृपया फिर से स्कैन करें।',
    'The selected image is no longer available. Please scan it again.':
        'चुनी गई छवि अब उपलब्ध नहीं है। कृपया फिर से स्कैन करें।',
    'Low Eye Strain': 'आँखों पर कम दबाव',
    'Maximum Clarity': 'अधिकतम स्पष्टता',
    'Beginner Reader': 'शुरुआती पाठक',
    'OpenDyslexic · Cream · Generous spacing':
        'OpenDyslexic · क्रीम · अधिक अक्षर दूरी',
    'Inter · Soft Yellow · Reduced glare':
        'Inter · हल्का पीला · कम चमक',
    'Monospace · White · Large, spaced text':
        'Monospace · सफ़ेद · बड़ा और खुला पाठ',
    'OpenDyslexic · Light Blue · Very large text':
        'OpenDyslexic · हल्का नीला · बहुत बड़ा पाठ',
    '✓ Applied': '✓ लागू',
    'Previewing': 'पूर्वावलोकन',
    'Select': 'चुनें',
    'Adjust fonts and spacing so text is comfortable to read.':
        'पाठ को आराम से पढ़ने के लिए फ़ॉन्ट और दूरी बदलें।',
    'Font Family': 'फ़ॉन्ट परिवार',
    'Font Size': 'फ़ॉन्ट आकार',
    'Letter Spacing': 'अक्षरों के बीच दूरी',
    'Word Spacing': 'शब्दों के बीच दूरी',
    'Line Height': 'पंक्ति की ऊँचाई',
    'Colour Themes': 'रंग थीम',
    'Pick a background and text colour combination proven to reduce eye strain.':
        'आँखों पर दबाव कम करने वाला पृष्ठभूमि और पाठ का रंग चुनें।',
    'Premium Themes': 'प्रीमियम थीम',
    'Cream + Black': 'क्रीम + काला',
    'Soft Yellow + Black': 'हल्का पीला + काला',
    'Pale Blue + Navy': 'हल्का नीला + नेवी',
    'Pale Green + Dark Gray': 'हल्का हरा + गहरा धूसर',
    'Peach + Black': 'आड़ू रंग + काला',
    'White + Black': 'सफ़ेद + काला',
    'Pale Green + Gray': 'हल्का हरा + धूसर',
    'Lavender + Purple': 'लैवेंडर + बैंगनी',
    'Black + White': 'काला + सफ़ेद',
    'White + Navy': 'सफ़ेद + नेवी',
    'Navy + White': 'नेवी + सफ़ेद',
    'Dark Gray + White': 'गहरा धूसर + सफ़ेद',
    'Yellow + Black': 'पीला + काला',
    'Black + Yellow': 'काला + पीला',
    'Cyan + Black': 'सियान + काला',
    'Black + Cyan': 'काला + सियान',
    'Dark Blue + Yellow': 'गहरा नीला + पीला',
    'Sepia': 'सेपिया',
    'Kindle Dark': 'Kindle डार्क',
    'Slate': 'स्लेट',
    'Graphite': 'ग्रेफाइट',
    'Midnight': 'मिडनाइट',
    'Dark Mode': 'डार्क मोड',
    'Cream + Navy': 'क्रीम + नेवी',
    'Cream + Dark Green': 'क्रीम + गहरा हरा',
    'Cream + Burgundy': 'क्रीम + बरगंडी',
    'Soft Yellow + Purple': 'हल्का पीला + बैंगनी',
    'Soft Reading': 'आरामदायक रीडिंग',
    'Extreme Accessibility': 'अत्यधिक सुलभता',
    'Modern Reading': 'आधुनिक रीडिंग',
    'High readability with reduced glare.':
        'कम चमक के साथ बेहतर पठनीयता।',
    'Reduces eye strain and improves focus.':
        'आँखों का तनाव कम करता है और ध्यान बढ़ाता है।',
    'Helps visual tracking and letter distinction.':
        'पंक्ति पर नज़र बनाए रखने और अक्षरों को अलग पहचानने में मदद करता है।',
    'Comfortable for long reading sessions.':
        'लंबे समय तक पढ़ने के लिए आरामदायक।',
    'Warm tone with strong contrast.':
        'गर्म रंग और स्पष्ट कंट्रास्ट।',
    'Maximum contrast.': 'अधिकतम कंट्रास्ट।',
    'Comfortable for low-light environments.':
        'कम रोशनी में पढ़ने के लिए आरामदायक।',
    'Classic cream with deep navy text.':
        'क्लासिक क्रीम पृष्ठभूमि पर गहरा नेवी पाठ।',
    'Earthy tones for reduced eye strain.':
        'आँखों का तनाव कम करने वाले प्राकृतिक रंग।',
    'Warm cream with rich burgundy text.':
        'गर्म क्रीम पृष्ठभूमि पर गहरा बरगंडी पाठ।',
    'Calming yellow with vivid purple contrast.':
        'शांत पीला रंग और स्पष्ट बैंगनी कंट्रास्ट।',
    'Strong contrast without harsh black text.':
        'काले पाठ की कठोरता के बिना स्पष्ट कंट्रास्ट।',
    'Calming contrast with softer tones.':
        'हल्के रंगों के साथ आरामदायक कंट्रास्ट।',
    'Maximum readability.': 'अधिकतम पठनीयता।',
    'Strong contrast for dark reading.':
        'डार्क मोड में पढ़ने के लिए स्पष्ट कंट्रास्ट।',
    'Cleaner than pure black.': 'पूरे काले रंग से अधिक सहज।',
    'Dark reading with crisp text.': 'डार्क मोड में स्पष्ट पाठ के साथ पढ़ें।',
    'Reduced glare dark theme.': 'कम चमक वाली डार्क थीम।',
    'Maximum foreground/background separation.':
        'पाठ और पृष्ठभूमि के बीच अधिकतम अंतर।',
    'Frequently preferred by some visually impaired readers.':
        'कुछ दृष्टिबाधित पाठकों द्वारा अक्सर पसंद किया जाता है।',
    'Bright high-visibility theme.': 'अधिक दृश्यता वाली चमकीली थीम।',
    'Strong visual distinction.': 'स्पष्ट दृश्य अंतर।',
    'Maximum letter differentiation.': 'अक्षरों के बीच अधिकतम अंतर।',
    'Book-like reading experience.': 'किताब जैसा पढ़ने का अनुभव।',
    'Comfortable long-session reading.': 'लंबे समय तक पढ़ने के लिए आरामदायक।',
    'Modern low-glare dark theme.': 'कम चमक वाली आधुनिक डार्क थीम।',
    'Balanced dark reading mode.': 'संतुलित डार्क रीडिंग मोड।',
    'Pure dark accessibility theme.': 'सुलभता के लिए पूरी तरह डार्क थीम।',
    'Applied': 'लागू',
    'Selected': 'चुना गया',
    'Override colours manually for a fully personalised look.':
        'अपने अनुसार रूप बनाने के लिए रंग खुद चुनें।',
    'Text Colour': 'पाठ का रंग',
    'Background Colour': 'पृष्ठभूमि का रंग',
    'Very low': 'बहुत कम',
    'Low contrast combination detected':
        'कम कंट्रास्ट वाला रंग संयोजन मिला',
    'This may reduce readability.':
        'इससे पढ़ना कठिन हो सकता है।',
    'Font:': 'फ़ॉन्ट:',
    'Size:': 'आकार:',
    'Theme:': 'थीम:',
    'saved readings': 'सहेजी गई रीडिंग',
    'saved reading': 'सहेजी गई रीडिंग',
    'This will permanently delete all': 'इससे स्थायी रूप से हट जाएँगी',
    'reading': 'रीडिंग',
    'readings': 'रीडिंग',
    'This cannot be undone.': 'इस बदलाव को वापस नहीं किया जा सकता।',
    'minute': 'मिनट',
    'minutes': 'मिनट',
    'hour': 'घंटा',
    'hours': 'घंटे',
    'day': 'दिन',
    'days': 'दिन',
    'ago': 'पहले',
    'words': 'शब्द',
    'Section': 'अनुभाग',
    'Voice commands': 'वॉइस कमांड',
    'Listening': 'सुन रहा है',
    'Mic off': 'माइक्रोफ़ोन बंद',
    'Voice-command language': 'वॉइस कमांड की भाषा',
    'Choose a supported language': 'समर्थित भाषा चुनें',
    'Voice commands use': 'वॉइस कमांड के लिए भाषा',
    'Tap the microphone to give a reading command.':
        'पढ़ने का निर्देश देने के लिए माइक्रोफ़ोन दबाएँ।',
    'Checking microphone and speech-recognition access…':
        'माइक्रोफ़ोन और वॉइस पहचान की अनुमति जाँची जा रही है…',
    'Speech recognition is unavailable. Check microphone and speech permissions in device settings.':
        'वॉइस पहचान उपलब्ध नहीं है। डिवाइस सेटिंग में माइक्रोफ़ोन और वॉइस अनुमतियाँ जाँचें।',
    'This device does not list English, Hindi, or Marathi speech recognition.':
        'इस डिवाइस में अंग्रेज़ी, हिंदी या मराठी वॉइस पहचान उपलब्ध नहीं है।',
    'Choose a command language supported by this device.':
        'इस डिवाइस पर उपलब्ध कमांड भाषा चुनें।',
    'No English speech-recognition locale is available. Select a listed language; AksharAlly will not switch languages automatically.':
        'अंग्रेज़ी वॉइस पहचान उपलब्ध नहीं है। सूची में दी गई भाषा चुनें; अक्षरअली भाषा अपने-आप नहीं बदलेगा।',
    'No Hindi speech-recognition locale is available. Select a listed language; AksharAlly will not switch languages automatically.':
        'हिंदी वॉइस पहचान उपलब्ध नहीं है। सूची में दी गई भाषा चुनें; अक्षरअली भाषा अपने-आप नहीं बदलेगा।',
    'No Marathi speech-recognition locale is available. Select a listed language; AksharAlly will not switch languages automatically.':
        'मराठी वॉइस पहचान उपलब्ध नहीं है। सूची में दी गई भाषा चुनें; अक्षरअली भाषा अपने-आप नहीं बदलेगा।',
    'No supported speech-recognition language is available on this device.':
        'इस डिवाइस पर कोई समर्थित वॉइस पहचान भाषा उपलब्ध नहीं है।',
    'Select a voice-command language before listening.':
        'सुनना शुरू करने से पहले वॉइस कमांड की भाषा चुनें।',
    'Listening…': 'सुन रहा है…',
    'Recognizing…': 'पहचान हो रही है…',
    'Command received.': 'कमांड मिल गया।',
    'No command was recognized.': 'कोई कमांड पहचाना नहीं गया।',
    'Could not start speech recognition:': 'वॉइस पहचान शुरू नहीं हो सकी:',
    'Could not listen:': 'सुनना शुरू नहीं हो सका:',
    'Could not process that command:': 'कमांड पर कार्रवाई नहीं हो सकी:',
    'Speech recognition error:': 'वॉइस पहचान में त्रुटि:',
    'Recognized speech': 'पहचानी गई आवाज़',
    'Recognized command will appear here.':
        'पहचाना गया कमांड यहाँ दिखाई देगा।',
    'Stop listening': 'सुनना बंद करें',
    'Preparing microphone…': 'माइक्रोफ़ोन तैयार हो रहा है…',
    'Processing…': 'प्रोसेस हो रहा है…',
    'Listen': 'सुनें',
    'Only English, Hindi, and Marathi commands are enabled.':
        'केवल अंग्रेज़ी, हिंदी और मराठी कमांड उपलब्ध हैं।',
    'Command completed.': 'कमांड पूरा हुआ।',
    'Reading started.': 'पढ़ना शुरू हुआ।',
    'Reading paused.': 'पढ़ना रोक दिया गया।',
    'Reading resumed.': 'पढ़ना फिर शुरू हुआ।',
    'Reading stopped.': 'पढ़ना बंद हुआ।',
    'There is no sentence to repeat.': 'दोहराने के लिए कोई वाक्य नहीं है।',
    'Repeating the current sentence.': 'मौजूदा वाक्य दोहराया जा रहा है।',
    'Repeating the passage.': 'यह अंश दोहराया जा रहा है।',
    'Reading speed updated.': 'पढ़ने की गति बदल दी गई।',
    'Text size updated.': 'पाठ का आकार बदल दिया गया।',
    'Reading colors updated.': 'पढ़ने के रंग बदल दिए गए।',
    'I did not recognize that command. Try one command at a time, such as “read this page,” “pause reading,” or “read slower.” Sentence navigation is not available yet.':
        'कमांड समझ नहीं आया। एक बार में एक कमांड बोलें, जैसे “यह पेज पढ़ें”, “पढ़ना रोकें” या “धीरे पढ़ें”। वाक्य पर आगे-पीछे जाना अभी उपलब्ध नहीं है।',
    'Customize Reading Experience': 'पढ़ने का अनुभव अनुकूलित करें',
    'English Reading Fonts': 'अंग्रेज़ी पढ़ने के फ़ॉन्ट',
    'Recommended for English': 'अंग्रेज़ी के लिए सुझाया गया',
    'Hindi & Marathi Fonts': 'हिंदी और मराठी के फ़ॉन्ट',
    'Recommended for Hindi & Marathi': 'हिंदी और मराठी के लिए सुझाया गया',
    'Paragraph Spacing': 'अनुच्छेदों के बीच दूरी',
    'Color Theme': 'रंग थीम',
    'Accessibility Features': 'सुलभता सुविधाएँ',
    'Word Highlighting during TTS': 'TTS के दौरान शब्द हाइलाइट करें',
    'Auto Read': 'अपने-आप पढ़ें',
    'Automatically read new content when it opens. Save as Default to keep this choice.':
        'नई सामग्री खुलने पर अपने-आप पढ़ें। इस विकल्प को रखने के लिए “डिफ़ॉल्ट के रूप में सहेजें” चुनें।',
    'Focus Window': 'फ़ोकस विंडो',
    'Dims surrounding text; drag the handle to reposition.':
        'आसपास का पाठ धुँधला करता है; इसे दूसरी जगह रखने के लिए हैंडल खींचें।',
    'Syllable Breakdown (Experimental)': 'शब्दांश विभाजन (प्रयोगात्मक)',
    'Inserts visible breaks into words (e.g. read-ing, im-por-tant).':
        'शब्दों में दिखने वाले विराम जोड़ता है (जैसे read-ing, im-por-tant)।',
    'Reduce Motion / Animations': 'गतिशीलता / एनिमेशन कम करें',
    'Reading Test Preview': 'पढ़ने के परीक्षण का पूर्वावलोकन',
    'System': 'सिस्टम',
    'Backend response was not JSON.':
        'बैकएंड से मिला जवाब मान्य JSON प्रारूप में नहीं है।',
    'Unknown backend error': 'बैकएंड में अज्ञात त्रुटि हुई।',
    'The OCR server took too long to process this image. Please try a smaller or clearer image.':
        'OCR सर्वर को इस छवि को प्रोसेस करने में बहुत समय लगा। छोटी या अधिक स्पष्ट छवि आज़माएँ।',
    'Could not reach the OCR server. Check that the phone and computer are on the same Wi-Fi and try again.':
        'OCR सर्वर से संपर्क नहीं हो सका। जाँचें कि फ़ोन और कंप्यूटर एक ही Wi-Fi पर हैं, फिर दोबारा कोशिश करें।',
    'The OCR server returned an invalid response. Please try again.':
        'OCR सर्वर से अमान्य जवाब मिला। कृपया फिर कोशिश करें।',
    'The OCR server returned a response in an unexpected format.':
        'OCR सर्वर से अप्रत्याशित प्रारूप में जवाब मिला।',
    'Unable to process the image:': 'छवि प्रोसेस नहीं हो सकी:',
    'Simplification failed': 'पाठ सरल नहीं हो सका।',
    'Text simplification took too long. Please try again.':
        'पाठ सरल करने में बहुत समय लगा। कृपया फिर कोशिश करें।',
    'Could not reach the backend server.':
        'बैकएंड सर्वर से संपर्क नहीं हो सका।',
    'Connection failed:': 'कनेक्शन विफल हुआ:',
    'Structured simplification failed':
        'संरचित पाठ सरल नहीं हो सका।',
    'Structured text processing took too long. Please try again.':
        'संरचित पाठ प्रोसेस करने में बहुत समय लगा। कृपया फिर कोशिश करें।',
    'error_audio_error': 'माइक्रोफ़ोन से ऑडियो नहीं मिला। उसकी अनुमति जाँचें।',
    'error_client': 'वॉइस पहचान शुरू नहीं हो सकी। कृपया फिर कोशिश करें।',
    'error_permission':
        'माइक्रोफ़ोन की अनुमति नहीं है। डिवाइस सेटिंग में अनुमति चालू करें।',
    'error_network': 'नेटवर्क त्रुटि। अपना कनेक्शन जाँचें और फिर कोशिश करें।',
    'error_network_timeout': 'नेटवर्क का समय समाप्त हुआ। कृपया फिर कोशिश करें।',
    'error_no_match': 'कोई आवाज़ पहचानी नहीं गई। फिर कोशिश करें।',
    'error_busy': 'वॉइस पहचान अभी व्यस्त है। थोड़ी देर बाद कोशिश करें।',
    'error_server': 'वॉइस पहचान सेवा उपलब्ध नहीं है। कृपया फिर कोशिश करें।',
    'error_speech_timeout': 'कोई आवाज़ नहीं मिली। फिर कोशिश करें।',
    'error_language_not_supported':
        'यह भाषा वॉइस पहचान के लिए समर्थित नहीं है।',
    'error_language_unavailable': 'यह भाषा वॉइस पहचान के लिए उपलब्ध नहीं है।',
    'error_server_disconnected':
        'वॉइस पहचान सेवा से संपर्क टूट गया। कृपया फिर कोशिश करें।',
    'error_too_many_requests':
        'बहुत ज़्यादा अनुरोध किए गए। थोड़ी देर बाद फिर कोशिश करें।',
    'error_speech_recognizer_disabled':
        'डिवाइस पर वॉइस पहचान बंद है। डिवाइस सेटिंग में इसे चालू करें।',
    'error_retry': 'वॉइस पहचान में समस्या हुई। कृपया फिर कोशिश करें।',
    'not supported': 'यह डिवाइस वॉइस पहचान का समर्थन नहीं करता।',
    'speech_not_supported': 'यह डिवाइस वॉइस पहचान का समर्थन नहीं करता।',
  };
}
