import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/auth/data/datasources/account_deletion_api.dart';
import 'package:pulsewise/features/auth/presentation/providers/account_deletion_provider.dart';

void main() {
  group('account deletion providers', () {
    test('accountDeletionApiProvider creates API from shared Dio', () {
      final container = ProviderContainer(
        overrides: [
          apiDioProvider.overrideWithValue(Dio()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(accountDeletionApiProvider),
        isA<AccountDeletionApi>(),
      );
    });
  });
}
