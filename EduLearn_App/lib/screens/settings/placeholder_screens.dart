import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class EditProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(AppLocalizations.of(context)!.get('edit_profile'))));
}

class ManageEmailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(AppLocalizations.of(context)!.get('email_address'))));
}

class ChangePasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(AppLocalizations.of(context)!.get('change_password'))));
}

class NotificationPreferencesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(AppLocalizations.of(context)!.get('notifications'))));
}

class LanguageSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(AppLocalizations.of(context)!.get('language'))));
}
