import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _email = '';
  String _displayName = '';
  String _photoUrl = '';

  String get email => _email;
  String get displayName => _displayName;
  String get photoUrl => _photoUrl;

  void updateEmail(String newEmail, String newDisplayName, String newPhotoUrl) {
    _email = newEmail;
    _displayName = newDisplayName;
    _photoUrl = newPhotoUrl;
    notifyListeners();
  }
}
