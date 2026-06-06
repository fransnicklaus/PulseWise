const accountDeletionConfirmationText = 'HAPUS AKUN';

const accountDeletionPasswordMethod = 'password';
const accountDeletionOtpMethod = 'otp';
const accountDeletionGoogleMethod = 'google';

class AccountDeletionException implements Exception {
  const AccountDeletionException(
    this.message, {
    this.availableReauthMethods = const [],
    this.fieldErrors = const {},
  });

  final String message;
  final List<String> availableReauthMethods;
  final Map<String, List<String>> fieldErrors;

  String? firstFieldError(String key) {
    final values = fieldErrors[key];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.first;
  }

  @override
  String toString() => message;
}

class AccountDeletionRequestResult {
  const AccountDeletionRequestResult({
    required this.nextStep,
    required this.requiresReauth,
    required this.reauthMethod,
    required this.availableReauthMethods,
    required this.deletionToken,
    required this.isPermanent,
    required this.isRecoverable,
    required this.confirmationText,
    this.delivery,
    this.expiresInMinutes,
  });

  final String nextStep;
  final bool requiresReauth;
  final String reauthMethod;
  final List<String> availableReauthMethods;
  final String deletionToken;
  final bool isPermanent;
  final bool isRecoverable;
  final String confirmationText;
  final String? delivery;
  final int? expiresInMinutes;

  factory AccountDeletionRequestResult.fromJson(Map<String, dynamic> json) {
    final warning = (json['warning'] as Map<String, dynamic>?) ?? const {};
    return AccountDeletionRequestResult(
      nextStep: (json['nextStep'] ?? '').toString(),
      requiresReauth: json['requiresReauth'] == true,
      reauthMethod: normalizeAccountDeletionMethod(json['reauthMethod']),
      availableReauthMethods:
          parseAccountDeletionMethods(json['availableReauthMethods']),
      deletionToken: (json['deletionToken'] ?? '').toString(),
      isPermanent: warning['permanent'] == true,
      isRecoverable: warning['recoverable'] == true,
      confirmationText:
          (warning['confirmationText'] ?? accountDeletionConfirmationText)
              .toString(),
      delivery: _normalizeOptionalString(json['delivery']),
      expiresInMinutes: (json['expiresInMinutes'] as num?)?.toInt(),
    );
  }
}

class AccountDeletionConfirmResult {
  const AccountDeletionConfirmResult({
    required this.nextStep,
    required this.deleted,
    required this.reauthMethod,
    required this.sessionRevoked,
    this.deletedAt,
  });

  final String nextStep;
  final bool deleted;
  final String reauthMethod;
  final bool sessionRevoked;
  final DateTime? deletedAt;

  factory AccountDeletionConfirmResult.fromJson(Map<String, dynamic> json) {
    return AccountDeletionConfirmResult(
      nextStep: (json['nextStep'] ?? '').toString(),
      deleted: json['deleted'] == true,
      reauthMethod: normalizeAccountDeletionMethod(json['reauthMethod']),
      sessionRevoked: json['sessionRevoked'] == true,
      deletedAt: DateTime.tryParse((json['deletedAt'] ?? '').toString()),
    );
  }
}

List<String> parseAccountDeletionMethods(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map(normalizeAccountDeletionMethod)
      .where((method) => method.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

String normalizeAccountDeletionMethod(dynamic value) {
  final normalized = (value ?? '').toString().trim().toLowerCase();
  switch (normalized) {
    case accountDeletionPasswordMethod:
    case accountDeletionOtpMethod:
    case accountDeletionGoogleMethod:
      return normalized;
    default:
      return normalized;
  }
}

Map<String, List<String>> parseAccountDeletionFieldErrors(dynamic details) {
  if (details is! Map<String, dynamic>) {
    return const {};
  }

  final rawFieldErrors = details['fieldErrors'];
  if (rawFieldErrors is! Map) {
    return const {};
  }

  final mapped = <String, List<String>>{};
  for (final entry in rawFieldErrors.entries) {
    final key = entry.key.toString();
    final value = entry.value;
    if (value is List) {
      mapped[key] =
          value.map((item) => item.toString()).toList(growable: false);
    } else if (value != null) {
      mapped[key] = [value.toString()];
    }
  }
  return mapped;
}

String? _normalizeOptionalString(dynamic value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}
