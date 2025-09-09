import 'package:freshk/extensions/localized_context.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';

enum AppTheme { light }

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({Key? key}) : super(key: key);

  @override
  _ThemeSelectionScreenState createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  AppTheme _selectedTheme = AppTheme.light;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(context.loc.theme, style: TextStyles.sectionHeader),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.padding),
        children: [
          RadioListTile<AppTheme>(
            title: const Text(
              'Light Theme',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            value: AppTheme.light,
            groupValue: _selectedTheme,
            activeColor: AppColors.primary,
            onChanged: (AppTheme? value) {
              if (value != null) {
                setState(() {
                  _selectedTheme = value;
                  // TODO: Implement theme change logic for light theme.
                });
              }
            },
          ),
          // Future expansion: Add additional themes if needed.
        ],
      ),
    );
  }
}
