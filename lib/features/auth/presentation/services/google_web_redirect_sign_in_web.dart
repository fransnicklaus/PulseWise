// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';

class GoogleWebRedirectSignInResult {
  const GoogleWebRedirectSignInResult({
    this.idToken,
    this.error,
  });

  final String? idToken;
  final String? error;
}

const _resultStorageKey = 'pulsewise_google_redirect_result';
const _resultHashIdTokenKey = 'pw_google_id_token';
const _resultHashErrorKey = 'pw_google_error';
const _scopes = 'openid email profile';
const _googleAuthorizationEndpoint =
    'https://accounts.google.com/o/oauth2/v2/auth';
const _googleRedirectCallbackUri =
    'https://pulsewise.algoritme.tech/google-signin-callback.html';
const _randomAlphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

bool get supportsGoogleWebRedirectSignIn => true;

Future<void> beginGoogleWebRedirectSignIn({
  required String clientId,
}) async {
  final trimmedClientId = clientId.trim();
  if (trimmedClientId.isEmpty) {
    throw Exception('Google Web Client ID belum dikonfigurasi.');
  }

  final nonce = _generateRandomValue();
  final callbackUri = Uri.parse(_googleRedirectCallbackUri);
  final returnUrl = '${html.window.location.origin}/login';
  final state = _encodeGoogleRedirectState(
    nonce: nonce,
    returnUrl: returnUrl,
  );

  final authorizationUri = Uri.parse(
    _googleAuthorizationEndpoint,
  ).replace(
    queryParameters: {
      'client_id': trimmedClientId,
      'redirect_uri': callbackUri.toString(),
      'response_type': 'id_token',
      'scope': _scopes,
      'prompt': 'select_account',
      'state': state,
      'nonce': nonce,
    },
  );

  html.window.location.assign(authorizationUri.toString());
}

Future<GoogleWebRedirectSignInResult?>
    consumeGoogleWebRedirectSignInResult() async {
  final hashResult = _consumeGoogleWebRedirectResultFromHash();
  if (hashResult != null) {
    return hashResult;
  }

  final rawResult = html.window.localStorage[_resultStorageKey];
  if (rawResult == null || rawResult.trim().isEmpty) {
    return null;
  }

  html.window.localStorage.remove(_resultStorageKey);

  try {
    final payload = jsonDecode(rawResult);
    if (payload is! Map<String, dynamic>) {
      return const GoogleWebRedirectSignInResult(
        error: 'Respons login Google web tidak valid.',
      );
    }

    final idToken = (payload['idToken'] ?? '').toString().trim();
    final error = (payload['error'] ?? '').toString().trim();

    return GoogleWebRedirectSignInResult(
      idToken: idToken.isEmpty ? null : idToken,
      error: error.isEmpty ? null : error,
    );
  } catch (_) {
    return const GoogleWebRedirectSignInResult(
      error: 'Gagal membaca hasil login Google web.',
    );
  }
}

GoogleWebRedirectSignInResult? _consumeGoogleWebRedirectResultFromHash() {
  final rawHash = html.window.location.hash;
  if (rawHash.trim().isEmpty || rawHash.trim() == '#') {
    return null;
  }

  final normalizedHash =
      rawHash.startsWith('#') ? rawHash.substring(1) : rawHash;

  Map<String, String> params;
  try {
    params = Uri.splitQueryString(normalizedHash);
  } catch (_) {
    return null;
  }

  final idToken = (params[_resultHashIdTokenKey] ?? '').trim();
  final error = (params[_resultHashErrorKey] ?? '').trim();
  if (idToken.isEmpty && error.isEmpty) {
    return null;
  }

  final cleanedUrl =
      '${html.window.location.pathname}${html.window.location.search}';
  html.window.history.replaceState(null, html.document.title, cleanedUrl);

  return GoogleWebRedirectSignInResult(
    idToken: idToken.isEmpty ? null : idToken,
    error: error.isEmpty ? null : error,
  );
}

String _encodeGoogleRedirectState({
  required String nonce,
  required String returnUrl,
}) {
  final payload = jsonEncode({
    'nonce': nonce,
    'returnUrl': returnUrl,
    'requestId': _generateRandomValue(24),
    'issuedAt': DateTime.now().millisecondsSinceEpoch,
  });

  return base64Url.encode(utf8.encode(payload));
}

String _generateRandomValue([int length = 40]) {
  final random = Random.secure();
  final buffer = StringBuffer();

  for (var index = 0; index < length; index++) {
    buffer.write(_randomAlphabet[random.nextInt(_randomAlphabet.length)]);
  }

  return buffer.toString();
}
