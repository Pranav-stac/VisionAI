# Language Localization in Vision AI

This document provides guidelines on how to implement language localization in the Vision AI app.

## Overview

The app supports multiple languages:
- English (en)
- Hindi (hi)
- Marathi (mr)

## How to Use Localization

### 1. Using BaseScreen

The simplest way to add localization support to any screen is to use the `BaseScreen` widget:

```dart
@override
Widget build(BuildContext context) {
  return BaseScreen(
    builder: (context, localizedStrings) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizedStrings['screenTitle'] ?? 'Default Title'),
        ),
        body: Center(
          child: Text(localizedStrings['greeting'] ?? 'Hello'),
        ),
      );
    },
  );
}
```

### 2. Using Localized Widgets

For simpler components, use the pre-built localized widgets:

```dart
// Text
LocalizedText(
  textKey: 'helloWorld',
  defaultText: 'Hello World',
  style: TextStyle(fontSize: 16),
)

// AppBar
LocalizedAppBar(
  titleKey: 'settings',
  defaultTitle: 'Settings',
  actions: [
    IconButton(
      icon: Icon(Icons.info),
      onPressed: () {},
    ),
  ],
)

// Buttons
LocalizedElevatedButton(
  textKey: 'save',
  defaultText: 'Save',
  onPressed: () {},
)

LocalizedTextButton(
  textKey: 'cancel',
  defaultText: 'Cancel',
  onPressed: () {},
)
```

### 3. Direct Access to Localized Strings

You can also get localized strings directly:

```dart
// Get all localized strings
final localizedStrings = AppLocalizations.getLocalizedStrings(context);
Text(localizedStrings['welcome'] ?? 'Welcome');

// Get a specific localized string
final greeting = AppLocalizations.getText(context, 'welcome', 'Welcome');
Text(greeting);
```

## Adding New Translations

To add new translations:

1. Open `lib/utils/app_localizations.dart`
2. Add your new string keys and translations to each language in the `_localizedValues` map

Example:
```dart
'en': {
  // ... existing translations
  'myNewString': 'My new string in English',
},
'hi': {
  // ... existing translations
  'myNewString': 'हिंदी में मेरी नई स्ट्रिंग',
},
'mr': {
  // ... existing translations
  'myNewString': 'मराठीत माझी नवीन स्ट्रिंग',
},
```

## Best Practices

1. Always provide a default text value for cases when translation is missing
2. Group related translations together in the translation files
3. Use meaningful key names that describe the text's purpose
4. When adding features, add translations for all supported languages simultaneously 