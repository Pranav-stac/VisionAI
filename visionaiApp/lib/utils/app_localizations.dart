import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visionai/providers/language_provider.dart';

class AppLocalizations {
  static Map<String, String> getLocalizedStrings(BuildContext context, [String? languageCode]) {
    // If languageCode is not provided, get it from the provider
    if (languageCode == null) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      languageCode = languageProvider.languageCode;
    }
    
    // Return localized values
    return _localizedValues[languageCode] ?? _localizedValues['en']!;
  }

  // Helper method to get a specific localized string
  static String getText(BuildContext context, String key, [String defaultValue = '']) {
    final localizedStrings = getLocalizedStrings(context);
    return localizedStrings[key] ?? defaultValue;
  }

  // All translations for the app
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Vision AI',
      'home': 'Home',
      'settings': 'Settings',
      'language': 'Language',
      'english': 'English',
      'hindi': 'Hindi',
      'marathi': 'Marathi',
      'selectLanguage': 'Select Language',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'mentalHealth': 'Mental Health',
      'objectDetection': 'Object Detection',
      'textRecognition': 'Text Recognition',
      'faceDetection': 'Face Detection',
      'speechToText': 'Speech to Text',
      'textToSpeech': 'Text to Speech',
      'profile': 'Profile',
      'logout': 'Logout',
      'login': 'Login',
      'signUp': 'Sign Up',
      'welcome': 'Welcome',
      'continueText': 'Continue',
      'quickActions': 'Quick Actions',
      'features': 'Features',
      'volunteers': 'Volunteers',
      'communities': 'Communities',
      'helloUser': 'Hello, User',
      'howCanWeAssist': 'How can we assist you today?',
      'sceneDescription': 'Scene Description',
      'voiceToText': 'Voice to Text',
      'realtimeCaptioning': 'Realtime Captioning',
      'textToVoice': 'Text to Voice',
      'getHelp': 'Get Help',
      'voiceGeneration': 'Voice Generation',
      'volunteerNetwork': 'Volunteer Network',
      'learningResources': 'Learning Resources',
      
      // General app translations
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'next': 'Next',
      'previous': 'Previous',
      'search': 'Search',
      
      // Profile screen translations
      'personal': 'Personal',
      'activity': 'Activity',
      'accountInformation': 'Account Information',
      'personalInformation': 'Personal Information',
      'security': 'Security',
      'linkedAccounts': 'Linked Accounts',
      'appPreferences': 'App Preferences',
      'notifications': 'Notifications',
      'pushNotifications': 'Push Notifications',
      'soundEffects': 'Sound Effects',
      'accessibility': 'Accessibility',
      'visualPreferences': 'Visual Preferences',
      'audioPreferences': 'Audio Preferences',
      'touchInteraction': 'Touch & Interaction',
      'darkMode': 'Dark Mode',
      'recentActivity': 'Recent Activity',
      'noRecentActivity': 'Your activity will appear here once you start using the app features.',
      'exploreFeatures': 'Explore Features',
      'support': 'Support',
      'helpCenter': 'Help Center',
      'faqsAndTroubleshooting': 'FAQs and troubleshooting',
      'feedback': 'Feedback',
      'helpUsImproveTheApp': 'Help us improve the app',
      'about': 'About',
    },
    'hi': {
      'appTitle': 'विज़न एआई',
      'home': 'होम',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'english': 'अंग्रे़ी',
      'hindi': 'हिंदी',
      'marathi': 'मराठी',
      'selectLanguage': 'भाषा चुनें',
      'camera': 'कैमरा',
      'gallery': 'गैलरी',
      'mentalHealth': 'मानसिक स्वास्थ्य',
      'objectDetection': 'वस्तु पहचान',
      'textRecognition': 'टेक्स्ट पहचान',
      'faceDetection': 'चेहरा पहचान',
      'speechToText': 'स्पीच से टेक्स्ट',
      'textToSpeech': 'टेक्स्ट से स्पीच',
      'profile': 'प्रोफाइल',
      'logout': 'लॉगआउट',
      'login': 'लॉगिन',
      'signUp': 'साइन अप',
      'welcome': 'स्वागत है',
      'continueText': 'जारी रखें',
      'quickActions': 'त्वरित कार्य',
      'features': 'विशेषताएं',
      'volunteers': 'स्वयंसेवक',
      'communities': 'समुदाय',
      'helloUser': 'नमस्ते, उपयोगकर्ता',
      'howCanWeAssist': 'आज हम आपकी कैसे सहायता कर सकते हैं?',
      'sceneDescription': 'दृश्य विवरण',
      'voiceToText': 'आवाज से टेक्स्ट',
      'realtimeCaptioning': 'रीयलटाइम कैप्शनिंग',
      'textToVoice': 'टेक्स्ट से आवाज',
      'getHelp': 'मदद लें',
      'voiceGeneration': 'आवाज निर्माण',
      'volunteerNetwork': 'स्वयंसेवक नेटवर्क',
      'learningResources': 'शिक्षण संसाधन',
      
      // General app translations
      'loading': 'लोड हो रहा है...',
      'error': 'त्रुटि',
      'success': 'सफलता',
      'cancel': 'रद्द करें',
      'confirm': 'पुष्टि करें',
      'save': 'सहेजें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'next': 'अगला',
      'previous': 'पिछला',
      'search': 'खोजें',
      
      // Profile screen translations
      'personal': 'व्यक्तिगत',
      'activity': 'गतिविधि',
      'accountInformation': 'खाता जानकारी',
      'personalInformation': 'व्यक्तिगत जानकारी',
      'security': 'सुरक्षा',
      'linkedAccounts': 'जुड़े खाते',
      'appPreferences': 'ऐप प्राथमिकताएं',
      'notifications': 'सूचनाएं',
      'pushNotifications': 'पुश सूचनाएं',
      'soundEffects': 'ध्वनि प्रभाव',
      'accessibility': 'पहुंच',
      'visualPreferences': 'दृश्य प्राथमिकताएं',
      'audioPreferences': 'ऑडियो प्राथमिकताएं',
      'touchInteraction': 'स्पर्श और इंटरैक्शन',
      'darkMode': 'डार्क मोड',
      'recentActivity': 'हाल की गतिविधि',
      'noRecentActivity': 'ऐप सुविधाओं का उपयोग शुरू करने के बाद आपकी गतिविधि यहां दिखाई देगी।',
      'exploreFeatures': 'सुविधाएं देखें',
      'support': 'सहायता',
      'helpCenter': 'सहायता केंद्र',
      'faqsAndTroubleshooting': 'अक्सर पूछे जाने वाले प्रश्न और समस्या निवारण',
      'feedback': 'प्रतिक्रिया',
      'helpUsImproveTheApp': 'ऐप को बेहतर बनाने में हमारी मदद करें',
      'about': 'के बारे में',
    },
    'mr': {
      'appTitle': 'व्हिजन एआय',
      'home': 'होम',
      'settings': 'सेटिंग्ज',
      'language': 'भाषा',
      'english': 'इंग्रजी',
      'hindi': 'हिंदी',
      'marathi': 'मराठी',
      'selectLanguage': 'भाषा निवडा',
      'camera': 'कॅमेरा',
      'gallery': 'गॅलरी',
      'mentalHealth': 'मानसिक आरोग्य',
      'objectDetection': 'वस्तू ओळख',
      'textRecognition': 'मजकूर ओळख',
      'faceDetection': 'चेहरा ओळख',
      'speechToText': 'भाषण ते मजकूर',
      'textToSpeech': 'मजकूर ते भाषण',
      'profile': 'प्रोफाइल',
      'logout': 'लॉगआउट',
      'login': 'लॉगिन',
      'signUp': 'साइन अप',
      'welcome': 'स्वागत आहे',
      'continueText': 'पुढे जा',
      'quickActions': 'जलद क्रिया',
      'features': 'वैशिष्ट्ये',
      'volunteers': 'स्वयंसेवक',
      'communities': 'समुदाय',
      'helloUser': 'नमस्कार, वापरकर्ता',
      'howCanWeAssist': 'आज आम्ही तुम्हाला कशी मदत करू शकतो?',
      'sceneDescription': 'दृश्य वर्णन',
      'voiceToText': 'आवाज ते मजकूर',
      'realtimeCaptioning': 'रिअलटाइम कॅप्शनिंग',
      'textToVoice': 'मजकूर ते आवाज',
      'getHelp': 'मदत मिळवा',
      'voiceGeneration': 'आवाज निर्मिती',
      'volunteerNetwork': 'स्वयंसेवक नेटवर्क',
      'learningResources': 'शिक्षण संसाधने',
      
      // General app translations
      'loading': 'लोड होत आहे...',
      'error': 'त्रुटी',
      'success': 'यश',
      'cancel': 'रद्द करा',
      'confirm': 'पुष्टी करा',
      'save': 'जतन करा',
      'delete': 'हटवा',
      'edit': 'संपादित करा',
      'next': 'पुढील',
      'previous': 'मागील',
      'search': 'शोधा',
      
      // Profile screen translations
      'personal': 'वैयक्तिक',
      'activity': 'क्रियाकलाप',
      'accountInformation': 'खाते माहिती',
      'personalInformation': 'वैयक्तिक माहिती',
      'security': 'सुरक्षा',
      'linkedAccounts': 'जोडलेली खाती',
      'appPreferences': 'अॅप प्राधान्ये',
      'notifications': 'सूचना',
      'pushNotifications': 'पुश सूचना',
      'soundEffects': 'ध्वनी प्रभाव',
      'accessibility': 'प्रवेशक्षमता',
      'visualPreferences': 'दृश्य प्राधान्ये',
      'audioPreferences': 'ऑडिओ प्राधान्ये',
      'touchInteraction': 'स्पर्श आणि इंटरॅक्शन',
      'darkMode': 'डार्क मोड',
      'recentActivity': 'अलीकडील क्रियाकलाप',
      'noRecentActivity': 'आपण अॅप वैशिष्ट्यांचा वापर करण्यास सुरुवात केल्यानंतर आपला क्रियाकलाप येथे दिसेल.',
      'exploreFeatures': 'वैशिष्ट्ये एक्सप्लोर करा',
      'support': 'सहाय्य',
      'helpCenter': 'मदत केंद्र',
      'faqsAndTroubleshooting': 'सामान्य प्रश्न आणि समस्या निवारण',
      'feedback': 'अभिप्राय',
      'helpUsImproveTheApp': 'अॅप सुधारण्यासाठी आम्हाला मदत करा',
      'about': 'बद्दल',
    },
  };
}

/// A widget that displays localized text.
/// This makes it easy to use localized strings in any widget.
class LocalizedText extends StatelessWidget {
  final String textKey;
  final String defaultText;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LocalizedText({
    Key? key,
    required this.textKey,
    this.defaultText = '',
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.getText(context, textKey, defaultText);
    
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// A localized version of ElevatedButton with text.
class LocalizedElevatedButton extends StatelessWidget {
  final String textKey;
  final String defaultText;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool isLoading;
  
  const LocalizedElevatedButton({
    Key? key,
    required this.textKey,
    this.defaultText = '',
    required this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.getText(context, textKey, defaultText);
    
    Widget buttonChild = Text(text);
    
    if (isLoading) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: buttonChild,
    );
  }
}

/// A localized version of TextButton.
class LocalizedTextButton extends StatelessWidget {
  final String textKey;
  final String defaultText;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  
  const LocalizedTextButton({
    Key? key,
    required this.textKey,
    this.defaultText = '',
    required this.onPressed,
    this.style,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.getText(context, textKey, defaultText);
    
    if (icon != null) {
      return TextButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: Text(text),
      );
    }
    
    return TextButton(
      onPressed: onPressed,
      style: style,
      child: Text(text),
    );
  }
}

/// A localized version of AppBar title.
class LocalizedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleKey;
  final String defaultTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double elevation;
  final Color? backgroundColor;
  
  const LocalizedAppBar({
    Key? key,
    required this.titleKey,
    this.defaultTitle = '',
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation = 0,
    this.backgroundColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final title = AppLocalizations.getText(context, titleKey, defaultTitle);
    
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation,
      backgroundColor: backgroundColor,
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 