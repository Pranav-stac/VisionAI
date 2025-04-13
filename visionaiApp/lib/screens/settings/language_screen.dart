import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visionai/providers/language_provider.dart';
import 'package:visionai/utils/app_localizations.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final Map<String, String> localizedStrings = AppLocalizations.getLocalizedStrings(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizedStrings['language'] ?? 'Language'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildLanguageListTile(
            context: context,
            languageCode: 'en',
            languageName: 'English',
            localizedName: localizedStrings['english'] ?? 'English',
            languageProvider: languageProvider,
          ),
          const Divider(height: 1),
          _buildLanguageListTile(
            context: context,
            languageCode: 'hi',
            languageName: 'हिंदी',
            localizedName: localizedStrings['hindi'] ?? 'Hindi',
            languageProvider: languageProvider,
          ),
          const Divider(height: 1),
          _buildLanguageListTile(
            context: context,
            languageCode: 'mr',
            languageName: 'मराठी',
            localizedName: localizedStrings['marathi'] ?? 'Marathi',
            languageProvider: languageProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageListTile({
    required BuildContext context,
    required String languageCode,
    required String languageName,
    required String localizedName,
    required LanguageProvider languageProvider,
  }) {
    final isSelected = languageProvider.languageCode == languageCode;

    return ListTile(
      title: Text(
        languageName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(localizedName),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        languageProvider.setLanguage(languageCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to $languageName'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
} 