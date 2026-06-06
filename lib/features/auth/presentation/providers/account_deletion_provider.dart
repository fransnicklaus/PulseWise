import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/auth/data/datasources/account_deletion_api.dart';

final accountDeletionApiProvider = Provider<AccountDeletionApi>((ref) {
  return AccountDeletionApi(ref.watch(apiDioProvider));
});
