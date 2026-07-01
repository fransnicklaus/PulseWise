import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/platform/health_connect_visibility.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';
import 'package:pulsewise/features/diary/presentation/providers/current_diary_provider.dart';
import 'package:pulsewise/features/emergency_contacts/presentation/providers/emergency_contacts_provider.dart';
import 'package:pulsewise/features/home_dashboard/presentation/providers/dashboard_overview_provider.dart';
import 'package:pulsewise/features/profile/data/models/profile_models.dart';
import 'package:pulsewise/features/profile/presentation/providers/profile_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilTab extends ConsumerStatefulWidget {
  const ProfilTab({super.key});

  @override
  ConsumerState<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends ConsumerState<ProfilTab> {
  static const CropperSize _webAvatarCropperSize = CropperSize(
    width: 360,
    height: 360,
  );
  static const Size _webAvatarCropperDialogSize = Size(360, 360);
  static const WebTranslations _webAvatarCropperTranslations = WebTranslations(
    title: 'Sesuaikan Avatar',
    rotateLeftTooltip: 'Putar 90 derajat ke kiri',
    rotateRightTooltip: 'Putar 90 derajat ke kanan',
    cancelButton: 'Batal',
    cropButton: 'Simpan',
  );
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://pulsewise-cms.algoritme.tech/privacy-policy',
  );

  bool _isUploadingAvatar = false;
  bool _didAutoRetryAuthFetch = false;

  void _goSafely(String location, {Object? extra}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(location, extra: extra);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(emergencyContactsProvider.notifier).fetchInitial();
    });
  }

  Future<void> _refreshSilently(Future<void> Function() refresh) async {
    try {
      await refresh();
    } catch (_) {
      // Let the existing screen state render stale data or fallback UI.
    }
  }

  Future<void> _refreshProfile() async {
    if (!mounted) return;
    await Future.wait([
      _refreshSilently(() async {
        final profileFuture = ref.refresh(patientProfileProvider.future);
        await profileFuture;
      }),
      _refreshSilently(() async {
        final authFuture = ref.refresh(authMeProvider.future);
        await authFuture;
      }),
      _refreshSilently(() async {
        await ref.read(emergencyContactsProvider.notifier).fetchInitial();
      }),
    ]);

    if (mounted) {
      _didAutoRetryAuthFetch = false;
    }
  }

  void _retryProfileData() {
    _didAutoRetryAuthFetch = false;
    ref.invalidate(patientProfileProvider);
    ref.invalidate(authMeProvider);
  }

  void _retryEmergencyContactsData() {
    ref.invalidate(emergencyContactsProvider);
    ref.read(emergencyContactsProvider.notifier).fetchInitial();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final month = monthNames[date.month - 1];
    return '${date.day.toString().padLeft(2, '0')} $month ${date.year}';
  }

  String _formatSex(String sex) {
    switch (sex.toLowerCase()) {
      case 'male':
        return 'Laki-laki';
      case 'female':
        return 'Perempuan';
      default:
        return sex.isEmpty ? '-' : sex;
    }
  }

  Future<void> _onLogout() async {
    await ref.read(authProvider.notifier).logout();
    ref.invalidate(authMeProvider);
    ref.invalidate(patientProfileProvider);
    ref.invalidate(quickDashboardProvider);
    ref.invalidate(dashboardVitalsProvider);
    ref.invalidate(currentDiaryProvider);
    ref.invalidate(emergencyContactsProvider);
    ref.read(previousNavIndexProvider.notifier).state = 0;
    ref.read(dashboardNavIndexProvider.notifier).state = 0;
    ref.read(healthConnectLoginPromptArmedProvider.notifier).state = false;
    if (!mounted) return;
    AppToast.success(context, 'Berhasil keluar dari akun');
    _goSafely('/login');
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Konfirmasi Keluar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Apakah Anda yakin ingin keluar dari akun ini?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE64060),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Ya, Keluar',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldLogout == true) {
      await _onLogout();
    }
  }

  void _showChangePasswordSheet() {
    final _currentCtrl = TextEditingController();
    final _newCtrl = TextEditingController();
    final _confirmCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        bool _obscureCurrent = true;
        bool _obscureNew = true;
        bool _obscureConfirm = true;
        bool _submitting = false;

        return StatefulBuilder(builder: (c, setState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(c).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ubah Kata Sandi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masukkan kata sandi saat ini dan kata sandi baru Anda.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _currentCtrl,
                          obscureText: _obscureCurrent,
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi Saat Ini',
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent),
                              icon: Icon(_obscureCurrent
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Kata sandi saat ini wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newCtrl,
                          obscureText: _obscureNew,
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi Baru',
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                              icon: Icon(_obscureNew
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Kata sandi baru wajib diisi';
                            if (v.length < 6)
                              return 'Kata sandi minimal 6 karakter';
                            if (v == _currentCtrl.text)
                              return 'Kata sandi baru harus berbeda dari kata sandi saat ini';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Kata Sandi Baru',
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(_obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Konfirmasi kata sandi wajib diisi';
                            if (v != _newCtrl.text)
                              return 'Konfirmasi tidak cocok';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting
                                ? null
                                : () async {
                                    if (!(_formKey.currentState?.validate() ??
                                        false)) return;
                                    setState(() => _submitting = true);
                                    try {
                                      final data = await ref
                                          .read(authProvider.notifier)
                                          .changePassword(
                                            currentPassword:
                                                _currentCtrl.text.trim(),
                                            newPassword: _newCtrl.text.trim(),
                                            confirmNewPassword:
                                                _confirmCtrl.text.trim(),
                                          );
                                      if (!mounted) return;
                                      context.pop();

                                      final nextStep =
                                          (data['nextStep'] ?? '').toString();
                                      if (nextStep == 'LOGIN_AGAIN') {
                                        await _onLogout();
                                      }
                                    } catch (e) {
                                      final message = e
                                          .toString()
                                          .replaceFirst('Exception: ', '');
                                      if (!mounted) return;
                                      AppToast.success(context,
                                          'Gagal memperbarui kata sandi: $message');
                                    } finally {
                                      if (mounted) {
                                        setState(() => _submitting = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE64060),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Simpan Perubahan',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    ).whenComplete(() async {
      await Future.delayed(const Duration(milliseconds: 250));
      _currentCtrl.dispose();
      _newCtrl.dispose();
      _confirmCtrl.dispose();
    });
  }

  Future<void> _copyAndPrintAuthToken() async {
    final session = await AppSessionStore.readSession(allowEnvFallback: false);
    final token = session.token ?? '';
    final userId = session.userId ?? '';

    if (!mounted) return;

    if (token.isEmpty) {
      debugPrint('[AUTH_TOKEN] <empty>');
      AppToast.warning(context, 'Token tidak ditemukan. Silakan login ulang.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: token));
    debugPrint('[AUTH_TOKEN] $token');
    debugPrint('[USER_ID] $userId');

    if (!mounted) return;
    AppToast.success(context, 'Token disalin dan dicetak ke debugger.');
  }

  Future<void> _goToMlQuestionnaire() async {
    final session = await AppSessionStore.readSession(allowEnvFallback: false);
    final token = session.token ?? '';
    final userId = session.userId ?? '';

    if (!mounted) return;

    if (token.isEmpty || userId.isEmpty) {
      AppToast.warning(
        context,
        'Sesi login tidak ditemukan. Silakan login ulang.',
      );
      return;
    }

    context.push(
      '/home/ml-questionnaire',
      extra: {
        AppSessionStore.tokenPrefsKey: token,
        AppSessionStore.userIdPrefsKey: userId,
      },
    );
  }

  Future<void> _openPrivacyPolicy() async {
    if (await canLaunchUrl(_privacyPolicyUri)) {
      await launchUrl(_privacyPolicyUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    AppToast.warning(
      context,
      'Tautan kebijakan privasi belum bisa dibuka saat ini.',
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) return;

      final selected = picked.files.first;
      const maxAvatarBytes = 5 * 1024 * 1024;
      if (selected.size > maxAvatarBytes) {
        if (!mounted) return;
        AppToast.warning(context, 'Ukuran avatar maksimal 5 MB.');
        return;
      }

      final filename = selected.name.isEmpty ? 'avatar.jpg' : selected.name;
      MultipartFile file;

      if (kIsWeb) {
        final bytes = selected.bytes;
        if (bytes == null || bytes.isEmpty) {
          if (!mounted) return;
          AppToast.warning(
            context,
            'File gambar tidak bisa dibaca di browser ini. Coba pilih ulang.',
          );
          return;
        }

        final extension = filename.contains('.')
            ? filename.split('.').last.toLowerCase()
            : 'jpg';
        final mimeType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };
        final cropSessionId = DateTime.now().microsecondsSinceEpoch;
        final sourcePath =
            'data:$mimeType;pw_session=$cropSessionId;base64,${base64Encode(bytes)}';
        if (!mounted) return;
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: sourcePath,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressFormat: ImageCompressFormat.jpg,
          uiSettings: [
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.dialog,
              size: _webAvatarCropperSize,
              viewwMode: WebViewMode.mode_1,
              dragMode: WebDragMode.move,
              background: false,
              guides: false,
              center: false,
              highlight: false,
              cropBoxMovable: false,
              cropBoxResizable: false,
              toggleDragModeOnDblclick: false,
              minContainerWidth: _webAvatarCropperDialogSize.width,
              minContainerHeight: _webAvatarCropperDialogSize.height,
              translations: _webAvatarCropperTranslations,
              customDialogBuilder: (
                cropper,
                initCropper,
                crop,
                rotate,
                _,
              ) {
                return _WebAvatarCropDialog(
                  cropper: cropper,
                  initCropper: initCropper,
                  crop: crop,
                  rotate: rotate,
                  cropperSize: _webAvatarCropperDialogSize,
                  translations: _webAvatarCropperTranslations,
                );
              },
            ),
          ],
        );

        if (croppedFile == null) return;

        file = MultipartFile.fromBytes(
          await croppedFile.readAsBytes(),
          filename: filename,
        );
      } else {
        String? sourcePath = selected.path;
        if ((sourcePath == null || sourcePath.isEmpty) &&
            selected.bytes != null) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(
            '${tempDir.path}${Platform.pathSeparator}avatar_pick_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await tempFile.writeAsBytes(selected.bytes!, flush: true);
          sourcePath = tempFile.path;
        }

        if (sourcePath == null || sourcePath.isEmpty) {
          if (!mounted) return;
          AppToast.warning(context, 'File gambar tidak valid.');
          return;
        }

        final croppedFile = await ImageCropper().cropImage(
          sourcePath: sourcePath,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 85,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Sesuaikan Avatar',
              toolbarColor: const Color(0xFFE64060),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              cropStyle: CropStyle.circle,
            ),
            IOSUiSettings(
              title: 'Sesuaikan Avatar',
              cropStyle: CropStyle.circle,
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile == null) return;

        file = await MultipartFile.fromFile(
          croppedFile.path,
          filename: filename,
        );
      }

      if (!mounted) return;
      setState(() => _isUploadingAvatar = true);

      if (!mounted) return;
      await ref.read(patientProfileApiProvider).uploadAvatar(file: file);
      if (!mounted) return;

      ref.invalidate(patientProfileProvider);
      ref.invalidate(authMeProvider);

      if (!mounted) return;
      AppToast.success(context, 'Avatar berhasil diperbarui.');
    } catch (e) {
      if (!mounted) return;
      AppToast.warning(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted && _isUploadingAvatar) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Widget _buildProfileSetupRequiredCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        border: Border.all(color: const Color(0xFFFDA4AF)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil Anda belum disiapkan',
            style: TextStyle(
              color: Color(0xFF881337),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lengkapi data profil terlebih dahulu agar akun dapat digunakan dengan normal.',
            style: TextStyle(
              color: Color(0xFF9F1239),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/home/update-profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text(
                'Edit Profil',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileErrorFooterActions({required bool includeDelete}) {
    return Column(
      children: [
        if (includeDelete) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/home/delete-account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBE123C),
                  side: const BorderSide(color: Color(0xFFFDA4AF)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_forever_outlined, size: 22),
                label: const Text(
                  'Hapus Akun Permanen',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE64060),
                side: const BorderSide(color: Color(0xFFE64060)),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout, size: 22),
              label: const Text(
                'Keluar',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(patientProfileProvider);
    final authMeAsync = ref.watch(authMeProvider);
    final emergencyState = ref.watch(emergencyContactsProvider);
    final authMe = authMeAsync.valueOrNull;
    final profile = profileAsync.valueOrNull;
    final profileError = profileAsync.asError?.error;
    final isAdminViewer = isAdminRole(authMe?.role);
    final isSkeleton = profile == null;
    final isRefreshing = profileAsync.isLoading && profileAsync.hasValue;
    final isProfileNetworkError =
        profileError != null && isNetworkRequestError(profileError);

    if (profileAsync.hasError && !profileAsync.hasValue) {
      final message = profileAsync.error.toString();
      final isMissingToken =
          message.toLowerCase().contains('bearer token tidak ditemukan');
      final isMissingProfile =
          isPatientProfileNotSetupError(profileAsync.error);

      if (isMissingToken && !_didAutoRetryAuthFetch) {
        _didAutoRetryAuthFetch = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.invalidate(patientProfileProvider);
          ref.invalidate(authMeProvider);
        });

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshProfile,
              color: const Color(0xFFE64060),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: SizedBox(
                  height: 200,
                  child: Container(
                    color: const Color(0xFFFFFFFF),
                    child: const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFE64060)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshProfile,
            color: const Color(0xFFE64060),
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isMissingProfile
                        ? _buildProfileSetupRequiredCard()
                        : isProfileNetworkError
                            ? NoConnectionState.page(
                                title: 'Profil belum bisa dimuat',
                                message:
                                    'Kami belum bisa mengambil data profil karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                                onRetry: _retryProfileData,
                              )
                            : Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  border: Border.all(
                                      color: const Color(0xFFFECACA)),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Gagal memuat profil',
                                      style: TextStyle(
                                        color: Color(0xFF991B1B),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      message,
                                      style: const TextStyle(
                                        color: Color(0xFF7F1D1D),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _retryProfileData,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFDC2626),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Coba Lagi'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                  if (isAdminViewer) ...[
                    const SizedBox(height: 12),
                    _buildAdminPanelButton(),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _copyAndPrintAuthToken,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7C3AED),
                            side: const BorderSide(color: Color(0xFFC4B5FD)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.key_outlined, size: 22),
                          label: const Text(
                            'Copy Auth Token',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildProfileErrorFooterActions(
                    includeDelete: isMissingProfile,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          color: const Color(0xFFE64060),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Skeletonizer(
              enabled: isSkeleton,
              effect: const ShimmerEffect(
                baseColor: Color(0xFFE9EDF2),
                highlightColor: Color(0xFFF6F8FB),
                duration: Duration(milliseconds: 1300),
              ),
              child: Stack(
                children: [
                  if (isRefreshing)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: Color(0xFFE64060),
                        backgroundColor: Color(0xFFF1F5F9),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 35),
                      _buildAvatarSection(
                        (profile?.fullName.isNotEmpty ?? false)
                            ? profile!.fullName
                            : 'Nama Pengguna',
                        (profile?.email.isNotEmpty ?? false)
                            ? profile!.email
                            : 'pengguna@pulsewise.app',
                        authMeAsync.asData?.value.avatarPhoto,
                      ),
                      const SizedBox(height: 8),
                      _SectionCard(
                        title: 'Informasi Pribadi',
                        children: [
                          _InfoRow(
                            label: 'Jenis Kelamin',
                            value:
                                profile == null ? '-' : _formatSex(profile.sex),
                          ),
                          _InfoRow(
                            label: 'Tanggal Lahir',
                            value: profile == null
                                ? '-'
                                : _formatDate(profile.dateOfBirth),
                          ),
                          _InfoRow(
                            label: 'Alamat',
                            value: profile == null
                                ? '-'
                                : (profile.address.isEmpty
                                    ? '-'
                                    : profile.address),
                          ),
                          // _InfoRow(
                          //   label: 'Merokok',
                          //   value: profile == null
                          //       ? '-'
                          //       : (profile.isSmoking ? 'Ya' : 'Tidak'),
                          // ),
                          // _InfoRow(
                          //   label: 'Merokok Elektrik',
                          //   value: profile == null
                          //       ? '-'
                          //       : (profile.isElectricSmoking ? 'Ya' : 'Tidak'),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Data Kesehatan',
                        children: [
                          _InfoRow(
                            label: 'Golongan Darah',
                            value: profile == null
                                ? 'A+'
                                : (profile.bloodType.isEmpty
                                    ? '-'
                                    : profile.bloodType),
                          ),
                          _InfoRow(
                            label: 'Tinggi',
                            value: profile == null
                                ? '170 cm'
                                : (profile.bodyHeightCm.isEmpty
                                    ? '-'
                                    : '${profile.bodyHeightCm} cm'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Kontak Darurat Utama',
                        children: isSkeleton
                            ? const [
                                _InfoRow(
                                    label: 'Nama', value: 'Kontak Darurat'),
                                _InfoRow(
                                    label: 'Nomor Telepon',
                                    value: '0812-3456-7890'),
                                _InfoRow(label: 'Status', value: 'Prioritas'),
                              ]
                            : _buildEmergencyContactChildren(emergencyState),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Pengaturan Akun',
                        children: [
                          _ActionRow(
                            label: 'Ubah Kata Sandi',
                            onTap: _showChangePasswordSheet,
                          ),
                          _ActionRow(
                            label: 'Kebijakan Privasi',
                            onTap: _openPrivacyPolicy,
                          ),
                          _ActionRow(
                            label: 'Edit Profil',
                            actionKey: const Key('patient_profile_edit_action'),
                            onTap: () => context.push('/home/update-profile'),
                          ),
                          _ActionRow(
                            label: 'Isi Kuisioner ML',
                            onTap: _goToMlQuestionnaire,
                          ),
                          _ActionRow(
                            label: 'Hapus Akun Permanen',
                            onTap: () => context.push('/home/delete-account'),
                          ),
                          _ActionRow(
                            label: 'Keluar',
                            actionKey: isSkeleton
                                ? null
                                : const Key('patient_profile_logout_action'),
                            onTap: _confirmLogout,
                          ),
                        ],
                      ),
                      if (isAdminViewer) ...[
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showNoConnectionDemoSheet(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFB45309),
                                side:
                                    const BorderSide(color: Color(0xFFFCD34D)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon:
                                  const Icon(Icons.wifi_off_rounded, size: 22),
                              label: const Text(
                                'Demo No Connection Widget',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildAdminPanelButton(),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showToastDebugSheet(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side:
                                    const BorderSide(color: Color(0xFF93C5FD)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.bug_report_outlined,
                                  size: 22),
                              label: const Text(
                                'Debug Toast Tester',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _copyAndPrintAuthToken,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF7C3AED),
                                side:
                                    const BorderSide(color: Color(0xFFC4B5FD)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.key_outlined, size: 22),
                              label: const Text(
                                'Copy Auth Token',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.push('/home/picker-demo'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFB45309),
                                side:
                                    const BorderSide(color: Color(0xFFFCD34D)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.watch_later_outlined,
                                  size: 22),
                              label: const Text(
                                'Demo Date & Time Picker',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/home/fcm-token'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F766E),
                                side:
                                    const BorderSide(color: Color(0xFF99F6E4)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                  Icons.notifications_active_outlined,
                                  size: 22),
                              label: const Text(
                                'FCM Device Token',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (isAdminViewer && shouldExposeHealthConnectUi) ...[
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.push('/home/health-connect'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF16A34A),
                                side:
                                    const BorderSide(color: Color(0xFF86EFAC)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.monitor_heart_outlined,
                                  size: 22),
                              label: const Text(
                                'Panduan Health Connect',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmergencyContactChildren(EmergencyContactsState state) {
    final hasNetworkError =
        state.errorCause != null && isNetworkRequestError(state.errorCause!);

    if (state.isLoadingInitial && state.items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.error != null && state.items.isEmpty) {
      return hasNetworkError
          ? [
              NoConnectionState.card(
                title: 'Kontak darurat belum bisa dimuat',
                message:
                    'Kami belum bisa mengambil kontak darurat karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                onRetry: _retryEmergencyContactsData,
              ),
            ]
          : [
              Text(
                state.error!,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _retryEmergencyContactsData,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE64060),
                    side: const BorderSide(color: Color(0xFFE64060)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    'Muat Ulang Kontak',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ];
    }

    if (state.error != null && state.items.isNotEmpty && hasNetworkError) {
      return [
        NoConnectionState.compact(
          title: 'Koneksi terputus',
          message:
              'Menampilkan kontak darurat terakhir yang berhasil dimuat. Sambungkan internet untuk memperbarui daftar terbaru.',
          onRetry: _retryEmergencyContactsData,
        ),
        const SizedBox(height: 14),
        ..._buildEmergencyContactRows(state),
      ];
    }

    if (state.items.isEmpty) {
      return const [
        _InfoRow(label: 'Nama', value: '-'),
        _InfoRow(label: 'Nomor Telepon', value: '-'),
      ];
    }

    return _buildEmergencyContactRows(state);
  }

  List<Widget> _buildEmergencyContactRows(EmergencyContactsState state) {
    final prioritized = state.items.where((item) => item.isPrioritas == true);
    final mainContact =
        prioritized.isNotEmpty ? prioritized.first : state.items.first;

    return [
      _InfoRow(
        label: 'Nama',
        value:
            mainContact.contactLabel.isEmpty ? '-' : mainContact.contactLabel,
      ),
      _InfoRow(
        label: 'Nomor Telepon',
        value:
            mainContact.contactNumber.isEmpty ? '-' : mainContact.contactNumber,
      ),
      _InfoRow(
        label: 'Status',
        value: mainContact.isPrioritas == true ? 'Prioritas' : 'Kontak Darurat',
      ),
    ];
  }

  Widget _buildTopBar() {
    return const SizedBox();
    // return Container(
    //   width: double.infinity,
    //   padding: const EdgeInsets.fromLTRB(20, 48, 20, 28),
    //   decoration: const BoxDecoration(
    //     gradient: LinearGradient(
    //       colors: [Color(0xFFE64060), Color(0xFFFF7A93)],
    //       begin: Alignment.topLeft,
    //       end: Alignment.bottomRight,
    //     ),
    //     borderRadius: BorderRadius.only(
    //       bottomLeft: Radius.circular(28),
    //       bottomRight: Radius.circular(28),
    //     ),
    //   ),
    //   child: const Text(
    //     'Profil Saya',
    //     textAlign: TextAlign.center,
    //     style: TextStyle(
    //       color: Colors.white,
    //       fontSize: 24,
    //       fontWeight: FontWeight.w800,
    //       letterSpacing: 0.5,
    //     ),
    //   ),
    // );
  }

  Widget _buildAvatarSection(
      [String? fullName, String? email, String? avatarUrl]) {
    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE64060), Color(0xFFFF7A93)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE64060).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4), // gradient border width
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: hasAvatar
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Color(0xFFE64060),
                              size: 56,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Color(0xFFE64060),
                            size: 56,
                          ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE64060),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isUploadingAvatar
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            (fullName != null && fullName.isNotEmpty)
                ? fullName
                : 'Nama Belum Diatur',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (email != null && email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          if (email == null || email.isEmpty) const SizedBox(height: 6),
          const Text(
            'Ketuk ikon kamera untuk ubah avatar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPanelButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => context.push('/admin/home'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF7C3AED),
            side: const BorderSide(color: Color(0xFFC4B5FD)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.admin_panel_settings_outlined, size: 22),
          label: const Text(
            'Buka Admin Panel',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  void _showToastDebugSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Try Toaster Variants',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _DebugToastButton(
                  label: 'Show Success Toast',
                  color: const Color(0xFF16A34A),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    AppToast.success(context, 'Ini contoh toast sukses.');
                  },
                ),
                _DebugToastButton(
                  label: 'Show Warning Toast',
                  color: const Color(0xFFD97706),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    AppToast.warning(context, 'Ini contoh toast warning.');
                  },
                ),
                _DebugToastButton(
                  label: 'Show Info Toast',
                  color: const Color(0xFF2563EB),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    AppToast.info(context, 'Ini contoh toast info.');
                  },
                ),
                _DebugToastButton(
                  label: 'Show Error Toast',
                  color: const Color(0xFFDC2626),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    AppToast.error(context, 'Ini contoh toast error.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNoConnectionDemoSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Demo No Connection',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pratinjau ini menampilkan versi kecil, versi card, dan versi halaman kecil supaya nanti bisa kita pakai konsisten di berbagai API state.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _PreviewLabel(
                    title: 'Compact',
                    subtitle: 'Untuk widget kecil atau section yang sempit.',
                  ),
                  const SizedBox(height: 10),
                  NoConnectionState.compact(
                    onRetry: () {
                      AppToast.info(
                        context,
                        'Demo retry ditekan pada versi compact.',
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const _PreviewLabel(
                    title: 'Card',
                    subtitle: 'Untuk section utama atau empty state inline.',
                  ),
                  const SizedBox(height: 10),
                  NoConnectionState.card(
                    title: 'Data belum bisa dimuat',
                    message:
                        'Bagian ini belum bisa mengambil data karena koneksi sedang bermasalah.',
                    onRetry: () {
                      AppToast.info(
                        context,
                        'Demo retry ditekan pada versi card.',
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const _PreviewLabel(
                    title: 'Page',
                    subtitle:
                        'Untuk halaman kecil atau error state penuh pada satu screen.',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SizedBox(
                      height: 420,
                      child: NoConnectionState.page(
                        title: 'Riwayat kesehatan belum bisa dibuka',
                        message:
                            'Screen ini cocok dipakai saat satu halaman penuh gagal memuat karena perangkat sedang offline.',
                        onRetry: () {
                          AppToast.info(
                            context,
                            'Demo retry ditekan pada versi page.',
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WebAvatarCropDialog extends StatefulWidget {
  const _WebAvatarCropDialog({
    required this.cropper,
    required this.initCropper,
    required this.crop,
    required this.rotate,
    required this.cropperSize,
    required this.translations,
  });

  final Widget cropper;
  final VoidCallback initCropper;
  final Future<String?> Function() crop;
  final void Function(RotationAngle) rotate;
  final Size cropperSize;
  final WebTranslations translations;

  @override
  State<_WebAvatarCropDialog> createState() => _WebAvatarCropDialogState();
}

class _WebAvatarCropDialogState extends State<_WebAvatarCropDialog> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    widget.initCropper();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.translations.title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      backgroundColor: const Color(0xFFF8FAFC),
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Cubit untuk memperbesar, lalu geser foto sampai pas di dalam lingkaran.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Container(
                  width: widget.cropperSize.width,
                  height: widget.cropperSize.height,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.cropper,
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Wrap(
                  spacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    _AvatarCropControlButton(
                      tooltip: widget.translations.rotateLeftTooltip,
                      icon: Icons.rotate_90_degrees_ccw_rounded,
                      onPressed: _isProcessing
                          ? null
                          : () => widget.rotate(
                                RotationAngle.counterClockwise90,
                              ),
                    ),
                    _AvatarCropControlButton(
                      tooltip: widget.translations.rotateRightTooltip,
                      icon: Icons.rotate_90_degrees_cw_outlined,
                      onPressed: _isProcessing
                          ? null
                          : () => widget.rotate(
                                RotationAngle.clockwise90,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tampilan crop di PWA dibuat menyerupai avatar bulat seperti di mobile.',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.translations.cancelButton,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handleCrop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE64060),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.translations.cropButton,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCrop() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final result = await widget.crop();
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      debugPrint(error.toString());
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

class _AvatarCropControlButton extends StatelessWidget {
  const _AvatarCropControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              icon,
              color: onPressed == null
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFFE64060),
            ),
          ),
        ),
      ),
    );
  }
}

class _DebugToastButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _DebugToastButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _PreviewLabel extends StatelessWidget {
  const _PreviewLabel({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;

  final VoidCallback? onTap;
  final Key? actionKey;

  const _ActionRow({
    required this.label,
    this.onTap,
    this.actionKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: actionKey,
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF94A3B8),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
