import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visionai/providers/language_provider.dart';
import 'package:visionai/screens/settings/language_screen.dart';
import 'package:visionai/utils/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final Map<String, String> localizedStrings = AppLocalizations.getLocalizedStrings(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizedStrings['settings'] ?? 'Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(localizedStrings['language'] ?? 'Language'),
            subtitle: Text(languageProvider.currentLanguageName),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguageScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          // Add more settings options here as needed
        ],
      ),
    );
  }
} 