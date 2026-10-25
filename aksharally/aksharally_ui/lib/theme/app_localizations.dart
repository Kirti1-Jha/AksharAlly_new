import 'app_settings.dart';

/// Small shared English/Hindi string catalog for the app's interface.
///
/// Reading content and the user's OCR/reading-language preference are kept
/// separate from these interface labels.
class AppLocalizations {
  AppLocalizations._();

  static bool get isHindi => AppSettings.interfaceLanguage == 'hi';

  static String text(String english) =>
      isHindi ? (_hindi[english] ?? english) : english;

  static String choose(String english, String hindi) =>
      isHindi ? hindi : english;

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
    'Hindi': 'हिंदी',
    'Marathi': 'मराठी',
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
    'Larger Touch Targets': 'टच क्षेत्र बड़ा करें',
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
    'English': 'अंग्रेज़ी',
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
    'Playback speed': 'पढ़ने की गति',
    'Previous section': 'पिछला अनुभाग',
    'Next section': 'अगला अनुभाग',
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
    'Dark Mode': 'डार्क मोड',
    'Cream + Navy': 'क्रीम + नेवी',
    'Cream + Dark Green': 'क्रीम + गहरा हरा',
    'Cream + Burgundy': 'क्रीम + बरगंडी',
    'Soft Yellow + Purple': 'हल्का पीला + बैंगनी',
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
  };
}
