class GoogleWebRedirectSignInResult {
  const GoogleWebRedirectSignInResult({
    this.idToken,
    this.error,
  });

  final String? idToken;
  final String? error;
}

bool get supportsGoogleWebRedirectSignIn => false;

Future<void> beginGoogleWebRedirectSignIn({
  required String clientId,
}) async {}

Future<GoogleWebRedirectSignInResult?>
    consumeGoogleWebRedirectSignInResult() async {
  return null;
}
