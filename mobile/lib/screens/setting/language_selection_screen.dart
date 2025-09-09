import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/providers/language_provider.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';

enum Language { english, french }

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  _LanguageSelectionScreenState createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  Language _selectedLanguage = Language.english;

  @override
  void initState() {
    super.initState();
    // Set the initial selected language based on current locale
    final currentLocale = context.read<LanguageProvider>().locale;
    _selectedLanguage =
        currentLocale.languageCode == 'fr' ? Language.french : Language.english;
  }

  void _changeLanguage(Language language) {
    final languageProvider = context.read<LanguageProvider>();

    setState(() {
      _selectedLanguage = language;
    });

    switch (language) {
      case Language.english:
        languageProvider.setEnglish();
        break;
      case Language.french:
        languageProvider.setFrench();
        break;
    }
    FreshkUtils.showSuccessSnackbar(
      context,
      language == Language.english
          ? 'Language changed to English'
          : 'Langue changée en Français',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(context.loc.selectLanguageTitle,
            style: TextStyles.sectionHeader),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.padding),
        children: [
          RadioListTile<Language>(
            title: const Text(
              'English',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            value: Language.english,
            groupValue: _selectedLanguage,
            activeColor: AppColors.primary,
            onChanged: (Language? value) {
              if (value != null) {
                _changeLanguage(value);
              }
            },
          ),
          RadioListTile<Language>(
            title: const Text(
              'Français',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            value: Language.french,
            groupValue: _selectedLanguage,
            activeColor: AppColors.primary,
            onChanged: (Language? value) {
              if (value != null) {
                _changeLanguage(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
