import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:freshk/utils/freshk_utils.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Local style values from your login screen
  final _borderColor = const Color(0xFF9F9F9F);
  final _textColor = const Color(0xFF8E8E8E);

  OutlineInputBorder _customBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _borderColor),
    );
  }

  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement your password change logic.
      FreshkUtils.showSuccessSnackbar(
        context,
        AppLocalizations.of(context)!.passwordChangedSuccessfully,
      );
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _textColor),
      border: _customBorder(),
      enabledBorder: _customBorder(),
      focusedBorder: _customBorder(),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: _textColor),
        title: Text(AppLocalizations.of(context)!.changePassword,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: _textColor)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(
            16.0), // using fixed padding for style consistency
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: _inputDecoration(
                    label: AppLocalizations.of(context)!.oldPassword),
                validator: (value) => (value == null || value.isEmpty)
                    ? AppLocalizations.of(context)!.pleaseEnterOldPassword
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: _inputDecoration(
                    label: AppLocalizations.of(context)!.newPassword),
                validator: (value) => (value == null || value.isEmpty)
                    ? AppLocalizations.of(context)!.pleaseEnterNewPassword
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: _inputDecoration(
                    label:
                        AppLocalizations.of(context)!.confirmYourNewPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.confirmYourNewPassword;
                  }
                  if (value != _newPasswordController.text) {
                    return AppLocalizations.of(context)!.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1AB560),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppLocalizations.of(context)!.changePassword,
                    style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
