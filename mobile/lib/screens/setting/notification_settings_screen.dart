import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../constants.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _receiveNotifications = true;
  bool _notificationSound = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          AppLocalizations.of(context)!.notificationSettings,
          style: TextStyles.sectionHeader,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.padding),
        children: [
          SwitchListTile(
            title: Text(
              AppLocalizations.of(context)!.receiveNotifications,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            value: _receiveNotifications,
            activeColor: AppColors.primary,
            onChanged: (bool value) {
              setState(() {
                _receiveNotifications = value;
                // TODO: Update notification preference.
              });
            },
          ),
          SwitchListTile(
            title: Text(
              AppLocalizations.of(context)!.notificationSound,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            value: _notificationSound,
            activeColor: AppColors.primary,
            onChanged: (bool value) {
              setState(() {
                _notificationSound = value;
                // TODO: Update notification sound setting.
              });
            },
          ),
        ],
      ),
    );
  }
}
