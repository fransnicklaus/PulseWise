import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_profile_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'doctor-token',
      AppSessionStore.userIdPrefsKey: 'doctor-1',
    });
  });

  group('DoctorProfileApi', () {
    test('fetchProfile sends authorized request and parses profile', () async {
      late RequestOptions observedOptions;
      final api = DoctorProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'doctorId': 'doctor-1',
              'specialization': 'Cardiology',
              'licenseNo': 'LIC-1',
              'hospitalName': 'Pulse Hospital',
              'firstName': 'Budi',
              'lastName': 'Santoso',
              'email': 'budi@example.com',
            },
          });
        },
      )));

      final profile = await api.fetchProfile();

      expect(observedOptions.method, 'GET');
      expect(observedOptions.path, '/doctors/doctor-1/profile');
      expect(observedOptions.headers['Authorization'], 'Bearer doctor-token');
      expect(profile.doctorId, 'doctor-1');
      expect(profile.fullName, 'Budi Santoso');
      expect(profile.specialization, 'Cardiology');
    });

    test('fetchProfile returns empty doctor profile on not found', () async {
      final api = DoctorProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {'success': false, 'message': 'Belum ada profil'},
          statusCode: 404,
        ),
      )));

      final profile = await api.fetchProfile();

      expect(profile.doctorId, 'doctor-1');
      expect(profile.specialization, isEmpty);
      expect(profile.email, isEmpty);
    });

    test('updateDoctorProfile sends authorized profile payload', () async {
      late RequestOptions observedOptions;
      final api = DoctorProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse({});
        },
      )));

      await api.updateDoctorProfile(
        specialization: 'Cardiology',
        licenseNo: 'LIC-1',
        hospitalName: 'Pulse Hospital',
      );

      expect(observedOptions.method, 'PUT');
      expect(observedOptions.path, '/doctors/doctor-1/profile');
      expect(observedOptions.headers['Authorization'], 'Bearer doctor-token');
      expect(observedOptions.data, {
        'specialization': 'Cardiology',
        'licenseNo': 'LIC-1',
        'hospitalName': 'Pulse Hospital',
      });
    });

    test('uploadAvatar chains signature, Cloudinary upload, and metadata save',
        () async {
      final observed = <RequestOptions>[];
      final api = DoctorProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observed.add(options);
          if (options.path.endsWith('/avatar/upload-signature')) {
            return _successResponse({
              'uploadUrl': 'https://upload.example.com/doctor-avatar',
              'apiKey': 'api-key',
              'timestamp': 1234,
              'folder': 'pulsewise/avatars',
              'signature': 'signature',
              'transformation': 'c_limit,w_512',
              'allowedFormats': 'png',
            });
          }
          if (options.uri.toString() ==
              'https://upload.example.com/doctor-avatar') {
            return const _FakeDioResponse({
              'secure_url': 'https://cdn.example.com/doctor.png',
              'public_id': 'avatars/doctor-1',
              'bytes': 2048,
              'width': 512,
              'height': 512,
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
          filename: 'doctor.png',
        ),
      );

      expect(observed.map((options) => options.method), ['GET', 'POST', 'PUT']);
      expect(observed[0].path, '/users/doctor-1/avatar/upload-signature');
      expect(
        observed[1].uri.toString(),
        'https://upload.example.com/doctor-avatar',
      );
      expect(observed[1].data, isA<FormData>());
      expect(observed[2].path, '/users/doctor-1/avatar');
      expect(observed[2].data, {
        'secureUrl': 'https://cdn.example.com/doctor.png',
        'publicId': 'avatars/doctor-1',
        'bytes': 2048,
        'width': 512,
        'height': 512,
        'format': 'png',
        'resourceType': 'image',
      });
    });

    test('fetchProfile maps Dio backend error message', () async {
      final api = DoctorProfileApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Profil dokter ditolak',
          },
          statusCode: 403,
        ),
      )));

      await expectLater(
        api.fetchProfile(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Profil dokter ditolak'),
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
