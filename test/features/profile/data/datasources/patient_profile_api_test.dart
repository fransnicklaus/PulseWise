import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/profile/data/datasources/patient_profile_api.dart';
import 'package:pulsewise/features/profile/data/models/profile_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'profile-token',
      AppSessionStore.userIdPrefsKey: 'patient-1',
    });
  });

  group('PatientProfileApi', () {
    test('fetchAvatarUploadSignature sends authorized folder query', () async {
      late RequestOptions observedOptions;
      final api = PatientProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse({
            'uploadUrl': 'https://upload.example.com',
            'apiKey': 'api-key',
            'timestamp': 1234,
            'folder': 'pulsewise/avatars',
            'signature': 'signature',
          });
        },
      )));

      final signature = await api.fetchAvatarUploadSignature(
        folder: 'pulsewise/avatars',
      );

      expect(observedOptions.method, 'GET');
      expect(
        observedOptions.path,
        '/users/patient-1/avatar/upload-signature',
      );
      expect(observedOptions.queryParameters, {
        'folder': 'pulsewise/avatars',
      });
      expect(observedOptions.headers['Authorization'], 'Bearer profile-token');
      expect(signature.apiKey, 'api-key');
      expect(signature.signature, 'signature');
    });

    test('saveAvatarMetadata sends authorized avatar metadata payload',
        () async {
      late RequestOptions observedOptions;
      final api = PatientProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse({});
        },
      )));

      await api.saveAvatarMetadata(
        secureUrl: 'https://cdn.example.com/avatar.png',
        publicId: 'avatars/patient-1',
        bytes: 2048,
        width: 512,
        height: 512,
        format: 'png',
        resourceType: 'image',
      );

      expect(observedOptions.method, 'PUT');
      expect(observedOptions.path, '/users/patient-1/avatar');
      expect(observedOptions.headers['Authorization'], 'Bearer profile-token');
      expect(observedOptions.data, {
        'secureUrl': 'https://cdn.example.com/avatar.png',
        'publicId': 'avatars/patient-1',
        'bytes': 2048,
        'width': 512,
        'height': 512,
        'format': 'png',
        'resourceType': 'image',
      });
    });

    test('uploadAvatar chains signature, Cloudinary upload, and metadata save',
        () async {
      final observed = <RequestOptions>[];
      final api = PatientProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observed.add(options);
          if (options.path.endsWith('/avatar/upload-signature')) {
            return _successResponse({
              'uploadUrl': 'https://upload.example.com/avatar',
              'apiKey': 'api-key',
              'timestamp': 1234,
              'folder': 'pulsewise/avatars',
              'signature': 'signature',
              'transformation': 'c_limit,w_512',
              'allowedFormats': 'png',
            });
          }
          if (options.uri.toString() == 'https://upload.example.com/avatar') {
            return const _FakeDioResponse({
              'secure_url': 'https://cdn.example.com/avatar.png',
              'public_id': 'avatars/patient-1',
              'bytes': 1024,
              'width': 256,
              'height': 256,
              'format': 'png',
              'resource_type': 'image',
            });
          }
          return _successResponse({});
        },
      )));

      await api.uploadAvatar(
        file: MultipartFile.fromBytes(
          Uint8List.fromList([1, 2, 3]),
          filename: 'avatar.png',
        ),
      );

      expect(observed.map((options) => options.method), ['GET', 'POST', 'PUT']);
      expect(
        observed[0].path,
        '/users/patient-1/avatar/upload-signature',
      );
      expect(observed[1].uri.toString(), 'https://upload.example.com/avatar');
      expect(observed[1].headers['Accept'], 'application/json');
      expect(observed[1].data, isA<FormData>());
      expect(observed[2].path, '/users/patient-1/avatar');
      expect(observed[2].data, {
        'secureUrl': 'https://cdn.example.com/avatar.png',
        'publicId': 'avatars/patient-1',
        'bytes': 1024,
        'width': 256,
        'height': 256,
        'format': 'png',
        'resourceType': 'image',
      });
    });

    test('fetchProfile parses patient profile data', () async {
      late RequestOptions observedOptions;
      final api = PatientProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'patient_id': 'patient-1',
              'first_name': 'Ayu',
              'last_name': 'Putri',
              'email': 'ayu@example.com',
              'date_of_birth': '1990-01-02',
            },
          });
        },
      )));

      final profile = await api.fetchProfile();

      expect(observedOptions.method, 'GET');
      expect(observedOptions.path, '/patients/patient-1/profile');
      expect(observedOptions.headers['Authorization'], 'Bearer profile-token');
      expect(profile.patientId, 'patient-1');
      expect(profile.fullName, 'Ayu Putri');
    });

    test('fetchProfile maps profile missing 404 to setup exception', () async {
      final api = PatientProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': patientProfileMissingMessage,
          },
          statusCode: 404,
        ),
      )));

      await expectLater(
        api.fetchProfile(),
        throwsA(isA<PatientProfileNotSetupException>()),
      );
    });

    test('updatePatientProfile sends patient profile payload', () async {
      late RequestOptions observedOptions;
      final api = PatientProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse({});
        },
      )));

      await api.updatePatientProfile(
        dateOfBirth: '1990-01-02',
        sex: 'female',
        heightCm: 165,
        isSmoking: false,
        isElectricSmoking: true,
        bloodType: 'O',
        address: 'Jakarta',
      );

      expect(observedOptions.method, 'PUT');
      expect(observedOptions.path, '/patients/patient-1/profile');
      expect(observedOptions.data, {
        'dateOfBirth': '1990-01-02',
        'sex': 'female',
        'heightCm': 165.0,
        'isSmoking': false,
        'isElectricSmoking': true,
        'bloodType': 'O',
        'address': 'Jakarta',
      });
    });

    test('fetchAuthMe sends authorized request and parses user', () async {
      late RequestOptions observedOptions;
      final api = PatientProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'userId': 'user-1',
              'username': 'ayu',
              'email': 'ayu@example.com',
              'firstName': 'Ayu',
              'lastName': 'Putri',
              'role': 'patient',
              'accountStatus': 'active',
            },
          });
        },
      )));

      final user = await api.fetchAuthMe();

      expect(observedOptions.method, 'GET');
      expect(observedOptions.path, '/auth/me');
      expect(observedOptions.headers['Authorization'], 'Bearer profile-token');
      expect(user.userId, 'user-1');
      expect(user.email, 'ayu@example.com');
    });

    test('fetchAuthMe maps Dio backend error message', () async {
      final api = PatientProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Auth me ditolak',
          },
          statusCode: 401,
        ),
      )));

      await expectLater(
        api.fetchAuthMe(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Auth me ditolak'),
          ),
        ),
      );
    });
  });
}

_FakeDioResponse _successResponse(Object data) {
  return _FakeDioResponse({
    'success': true,
    'message': 'OK',
    'data': data,
  });
}

Dio _dioWithAdapter(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.pulsewise.test'));
  dio.httpClientAdapter = adapter;
  return dio;
}

class _FakeDioResponse {
  const _FakeDioResponse(
    this.body, {
    this.statusCode = 200,
  });

  final Map<String, dynamic> body;
  final int statusCode;
}

class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter({required this.handler});

  final FutureOr<_FakeDioResponse> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = await handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
