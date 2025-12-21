// Package imports:
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

const String _serverClientId =
    '333142083765-m2bntjbnrtt0m2699l019mcbpmdsb1ku.apps.googleusercontent.com';

final List<String> _defaultScopes = <String>[
  'email',
  'openid',
  'profile',
];

bool _googleInitialized = false;

Future<void> _ensureGoogleInitialized() async {
  if (!_googleInitialized) {
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _googleInitialized = true;
  }
}

class GoogleOAuth {
  static bool get isEnabled => true;

  static Future<bool> signIn(Function(String, String) callback,
      {bool isSilent = false}) async {
    await _ensureGoogleInitialized();

    GoogleSignInAccount? account;

    if (isSilent) {
      final Future<GoogleSignInAccount?>? future =
          GoogleSignIn.instance.attemptLightweightAuthentication();
      if (future != null) {
        account = await future;
      }
    }

    account ??= await GoogleSignIn.instance.authenticate(
      scopeHint: _defaultScopes,
    );

    if (account != null) {
      final idToken = account.authentication.idToken ?? '';
      String accessToken = '';
      try {
        final GoogleSignInClientAuthorization? auth = await account
            .authorizationClient
            .authorizationForScopes(_defaultScopes);
        accessToken = auth?.accessToken ?? '';
      } catch (_) {
        // ignore and continue with empty access token
      }

      callback(idToken, accessToken);
      return true;
    } else {
      debugPrint('## ERROR: sign in failed');
      return false;
    }
  }

  static Future<bool> signUp(Function(String, String) callback) async {
    await _ensureGoogleInitialized();
    final GoogleSignInAccount account =
        await GoogleSignIn.instance.authenticate(scopeHint: _defaultScopes);
    debugPrint('dataAccount:${account.toString()}');
    if (account != null) {
      final idToken = account.authentication.idToken ?? '';
      String accessToken = '';
      try {
        final GoogleSignInClientAuthorization? auth = await account
            .authorizationClient
            .authorizationForScopes(_defaultScopes);
        accessToken = auth?.accessToken ?? '';
      } catch (_) {}

      callback(idToken, accessToken);
      return true;
    } else {
      debugPrint('## ERROR: sign up failed');
      return false;
    }
  }

  static Future<bool> requestGmailScope() async {
    await _ensureGoogleInitialized();
    try {
      final GoogleSignInClientAuthorization? auth = await GoogleSignIn
          .instance.authorizationClient
          .authorizeScopes(['https://www.googleapis.com/auth/gmail.send']);
      return auth != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> signOut() async {
    await _ensureGoogleInitialized();
    await GoogleSignIn.instance.signOut();
  }

  static Future<void> disconnect() async {
    await _ensureGoogleInitialized();
    await GoogleSignIn.instance.disconnect();
  }
}
