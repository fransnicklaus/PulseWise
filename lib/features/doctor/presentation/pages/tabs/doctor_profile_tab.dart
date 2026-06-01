import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_profile_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_profile_provider.dart';
import 'package:pulsewise/features/doctor_shell/presentation/providers/doctor_dashboard_provider.dart';

class DoctorProfileTab extends ConsumerStatefulWidget {
  const DoctorProfileTab({super.key});

  @override
  ConsumerState<DoctorProfileTab> createState() => _DoctorProfileTabState();
}

class _DoctorProfileTabState extends ConsumerState<DoctorProfileTab> {
  bool _isUploadingAvatar = false;

  Future<void> _refreshProfile() async {
    await ref.read(doctorProfileNotifierProvider.notifier).refreshProfile();
  }

  Future<void> _retryProfile() async {
    await ref.read(doctorProfileNotifierProvider.notifier).reloadProfile();
  }

  bool _isNetworkError(Object? error) {
    return error != null && isNetworkRequestError(error);
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

  Future<void> _onLogout() async {
    await ref.read(authProvider.notifier).logout();
    ref.invalidate(doctorProfileProvider);
    ref.invalidate(doctorProfileNotifierProvider);
    ref.read(doctorDashboardNavIndexProvider.notifier).state = 0;
    if (!mounted) return;
    AppToast.success(context, 'Berhasil keluar dari akun dokter');
    context.go('/login');
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
                  'Apakah Anda yakin ingin keluar dari akun dokter ini?',
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
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        bool obscureCurrent = true;
        bool obscureNew = true;
        bool obscureConfirm = true;
        bool submitting = false;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan kata sandi saat ini dan kata sandi baru Anda.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: currentCtrl,
                            obscureText: obscureCurrent,
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi Saat Ini',
                              suffixIcon: IconButton(
                                onPressed: () => setSheetState(
                                  () => obscureCurrent = !obscureCurrent,
                                ),
                                icon: Icon(
                                  obscureCurrent
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kata sandi saat ini wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: newCtrl,
                            obscureText: obscureNew,
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi Baru',
                              suffixIcon: IconButton(
                                onPressed: () => setSheetState(
                                  () => obscureNew = !obscureNew,
                                ),
                                icon: Icon(
                                  obscureNew
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kata sandi baru wajib diisi';
                              }
                              if (value.length < 6) {
                                return 'Kata sandi minimal 6 karakter';
                              }
                              if (value == currentCtrl.text) {
                                return 'Kata sandi baru harus berbeda dari kata sandi saat ini';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: confirmCtrl,
                            obscureText: obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Konfirmasi Kata Sandi Baru',
                              suffixIcon: IconButton(
                                onPressed: () => setSheetState(
                                  () => obscureConfirm = !obscureConfirm,
                                ),
                                icon: Icon(
                                  obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi kata sandi wajib diisi';
                              }
                              if (value != newCtrl.text) {
                                return 'Konfirmasi tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: submitting
                                  ? null
                                  : () async {
                                      if (!(formKey.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }

                                      setSheetState(() => submitting = true);
                                      try {
                                        final data = await ref
                                            .read(authProvider.notifier)
                                            .changePassword(
                                              currentPassword:
                                                  currentCtrl.text.trim(),
                                              newPassword: newCtrl.text.trim(),
                                              confirmNewPassword:
                                                  confirmCtrl.text.trim(),
                                            );

                                        if (!mounted) return;
                                        context.pop();

                                        final nextStep =
                                            (data['nextStep'] ?? '').toString();
                                        if (nextStep == 'LOGIN_AGAIN') {
                                          await _onLogout();
                                        } else {
                                          AppToast.success(
                                            context,
                                            'Kata sandi berhasil diperbarui',
                                          );
                                        }
                                      } catch (error) {
                                        if (!mounted) return;
                                        final message = error
                                            .toString()
                                            .replaceFirst('Exception: ', '');
                                        AppToast.error(
                                          context,
                                          'Gagal memperbarui kata sandi: $message',
                                        );
                                      } finally {
                                        if (mounted) {
                                          setSheetState(
                                              () => submitting = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE64060),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: submitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan Perubahan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() async {
      await Future.delayed(const Duration(milliseconds: 250));
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;

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

    String? sourcePath = selected.path;
    if ((sourcePath == null || sourcePath.isEmpty) && selected.bytes != null) {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}${Platform.pathSeparator}doctor_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
    if (!mounted) return;

    final file = await MultipartFile.fromFile(
      croppedFile.path,
      filename: filename,
    );
    if (!mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      await ref.read(doctorProfileApiProvider).uploadAvatar(file: file);
      ref.invalidate(doctorProfileProvider);
      await ref.read(doctorProfileNotifierProvider.notifier).reloadProfile();

      if (!mounted) return;
      AppToast.success(context, 'Avatar dokter berhasil diperbarui.');
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Widget _buildAvatarSection(DoctorProfile profile) {
    final fullName =
        profile.fullName.isEmpty ? 'Nama Belum Diatur' : profile.fullName;
    final hasAvatar = profile.avatarPhoto.trim().isNotEmpty;

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
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: hasAvatar
                        ? Image.network(
                            profile.avatarPhoto,
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
            fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (profile.email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                profile.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          if (profile.email.isEmpty) const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Akun Dokter',
              style: TextStyle(
                color: Color(0xFFE64060),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ketuk ikon kamera untuk ubah avatar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(doctorProfileNotifierProvider);
    final profile = profileState.profile;
    final showInitialLoading = profileState.isLoading && profile == null;
    final showOfflinePage = _isNetworkError(profileState.errorCause) &&
        profile == null &&
        !profileState.isLoading;
    final showOfflineBanner =
        _isNetworkError(profileState.errorCause) && profile != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          color: const Color(0xFFE64060),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
            children: [
              if (showInitialLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 140),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE64060),
                    ),
                  ),
                )
              else if (showOfflinePage)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 96, 16, 24),
                  child: NoConnectionState.page(
                    title: 'Profil dokter belum bisa dimuat',
                    message:
                        'Kami belum bisa mengambil profil dokter Anda. Cek koneksi internet lalu coba lagi.',
                    onRetry: _retryProfile,
                  ),
                )
              else if (profile == null && profileState.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFE64060),
                        size: 56,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        profileState.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _retryProfile,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE64060),
                            side: const BorderSide(color: Color(0xFFE64060)),
                            minimumSize: const Size.fromHeight(52),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            'Muat Ulang Profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (profile != null) ...[
                if (profileState.isRefreshing)
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: Color(0xFFE64060),
                    backgroundColor: Color(0xFFFBCFD7),
                  ),
                if (showOfflineBanner)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: NoConnectionState.compact(
                      title: 'Profil dokter belum tersinkron',
                      message:
                          'Data terakhir tetap ditampilkan. Sambungkan internet lalu tarik untuk memuat ulang.',
                      onRetry: _refreshProfile,
                    ),
                  ),
                _buildAvatarSection(profile),
                _SectionCard(
                  title: 'Informasi Dokter',
                  children: [
                    _InfoRow(
                      label: 'Spesialisasi',
                      value: profile.specialization.isEmpty
                          ? '-'
                          : profile.specialization,
                    ),
                    _InfoRow(
                      label: 'Nomor Izin',
                      value:
                          profile.licenseNo.isEmpty ? '-' : profile.licenseNo,
                    ),
                    _InfoRow(
                      label: 'Rumah Sakit',
                      value: profile.hospitalName.isEmpty
                          ? '-'
                          : profile.hospitalName,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Informasi Akun',
                  children: [
                    _InfoRow(
                      label: 'Email',
                      value: profile.email.isEmpty ? '-' : profile.email,
                    ),
                    _InfoRow(
                      label: 'ID Dokter',
                      value: profile.doctorId.isEmpty ? '-' : profile.doctorId,
                    ),
                    _InfoRow(
                      label: 'Bergabung',
                      value: _formatDate(profile.createdAt),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Pengaturan Akun',
                  children: [
                    _ActionRow(
                      label: 'Ubah Kata Sandi',
                      onTap: _showChangePasswordSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/doctor/home/update-profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE64060),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 22),
                      label: const Text(
                        'Edit Profil',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
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
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

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
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
  const _ActionRow({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
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
    );
  }
}
