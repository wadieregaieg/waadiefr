import 'package:freshk/extensions/localized_context.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../routes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(AppLocalizations.of(context)!.settings,
          style: TextStyles.sectionHeader),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.padding),
      children: [
        _buildSectionTitle(AppLocalizations.of(context)!.account),
        _buildMenuItem(
          context,
          Icons.person,
          context.loc.manageProfile,
          onTap: () => Navigator.pushNamed(context, AppRoutes.manageProfile),
        ),
        const SizedBox(height: AppDimensions.spacingLarge),
        _buildSectionTitle(AppLocalizations.of(context)!.preferences),
        _buildMenuItem(
          context,
          Icons.language,
          context.loc.language,
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.languageSelection),
        ),
        _buildDivider(),
        _buildMenuItem(
          context,
          Icons.brightness_6,
          context.loc.theme,
          onTap: () => Navigator.pushNamed(context, AppRoutes.themeSelection),
        ),
        _buildDivider(),
        _buildMenuItem(
          context,
          Icons.notifications,
          context.loc.notifications,
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.notificationSettings),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSmall),
      child: Text(title, style: TextStyles.sectionHeader),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String text,
      {VoidCallback? onTap, bool isDisabled = false}) {
    return ListTile(
      leading: Icon(icon, color: isDisabled ? Colors.grey : AppColors.primary),
      title: Text(text,
          style: TextStyle(
              color: isDisabled ? Colors.grey : AppColors.textPrimary)),
      trailing: Icon(Icons.chevron_right,
          color: isDisabled ? Colors.grey.withOpacity(0.3) : Colors.grey),
      onTap: isDisabled ? null : onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Colors.grey);
  }
}
