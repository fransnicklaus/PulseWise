import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/emergency_contacts_provider.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilTab extends ConsumerStatefulWidget {
  const ProfilTab({super.key});

  @override
  ConsumerState<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends ConsumerState<ProfilTab> {
  bool _isUploadingAvatar = false;
  bool _didAutoRetryAuthFetch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emergencyContactsProvider.notifier).fetchInitial();
    });
  }

  Future<void> _refreshProfile() async {
    ref.invalidate(patientProfileProvider);
    ref.invalidate(authMeProvider);
    await ref.read(patientProfileProvider.future);
    await ref.read(authMeProvider.future);
    await ref.read(emergencyContactsProvider.notifier).fetchInitial();
    _didAutoRetryAuthFetch = false;
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
    ref.invalidate(patientProfileProvider);
    ref.read(previousNavIndexProvider.notifier).state = 0;
    ref.read(dashboardNavIndexProvider.notifier).state = 0;
    if (!mounted) return;
    AppToast.success(context, 'Berhasil keluar dari akun');
    context.go('/login');
  }

  Future<void> _copyAndPrintAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (!mounted) return;

    if (token.isEmpty) {
      debugPrint('[AUTH_TOKEN] <empty>');
      AppToast.warning(context, 'Token tidak ditemukan. Silakan login ulang.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: token));
    debugPrint('[AUTH_TOKEN] $token');

    if (!mounted) return;
    AppToast.success(context, 'Token disalin dan dicetak ke debugger.');
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
    if (!mounted) return;

    final file =
        await MultipartFile.fromFile(croppedFile.path, filename: filename);
    if (!mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      if (!mounted) return;
      await ref.read(profileApiProvider).uploadAvatar(file: file);
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
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(patientProfileProvider);
    final authMeAsync = ref.watch(authMeProvider);
    final emergencyState = ref.watch(emergencyContactsProvider);

    return RefreshIndicator(
      onRefresh: _refreshProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        child: profileAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE64060)),
                ),
              ),
            ],
          ),
          error: (error, _) {
            final message = error.toString();
            final isMissingToken =
                message.toLowerCase().contains('bearer token tidak ditemukan');

            if (isMissingToken && !_didAutoRetryAuthFetch) {
              _didAutoRetryAuthFetch = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.invalidate(patientProfileProvider);
                ref.invalidate(authMeProvider);
              });

              return const SizedBox(
                height: 320,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE64060)),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      border: Border.all(color: const Color(0xFFFECACA)),
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
                            onPressed: () {
                              _didAutoRetryAuthFetch = false;
                              ref.invalidate(patientProfileProvider);
                              ref.invalidate(authMeProvider);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ),
                      ],
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
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _onLogout,
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
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          data: (profile) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              _buildAvatarSection(
                profile.fullName,
                profile.email,
                authMeAsync.asData?.value.avatarPhoto,
              ),
              const SizedBox(height: 8),
              _SectionCard(
                title: 'Informasi Pribadi',
                children: [
                  _InfoRow(
                    label: 'Jenis Kelamin',
                    value: _formatSex(profile.sex),
                  ),
                  _InfoRow(
                    label: 'Tanggal Lahir',
                    value: _formatDate(profile.dateOfBirth),
                  ),
                  _InfoRow(
                    label: 'Alamat',
                    value: profile.address.isEmpty ? '-' : profile.address,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Data Kesehatan',
                children: [
                  _InfoRow(
                    label: 'Golongan Darah',
                    value: profile.bloodType.isEmpty ? '-' : profile.bloodType,
                  ),
                  _InfoRow(
                    label: 'Tinggi',
                    value: profile.bodyHeightCm.isEmpty
                        ? '-'
                        : '${profile.bodyHeightCm} cm',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Kontak Darurat Utama',
                children: _buildEmergencyContactChildren(emergencyState),
              ),
              const SizedBox(height: 14),
              const _SectionCard(
                title: 'Pengaturan Akun',
                children: [
                  _ActionRow(label: 'Ubah Kata Sandi'),
                  _ActionRow(label: 'Privasi & Izin Data'),
                  _ActionRow(label: 'Bahasa Aplikasi'),
                  _ActionRow(label: 'Notifikasi'),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showToastDebugSheet(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.bug_report_outlined, size: 22),
                    label: const Text(
                      'Debug Toast Tester',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                      side: const BorderSide(color: Color(0xFFC4B5FD)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.key_outlined, size: 22),
                    label: const Text(
                      'Copy Auth Token',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                    onPressed: () => context.push('/home/health-connect'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFF86EFAC)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.monitor_heart_outlined, size: 22),
                    label: const Text(
                      'Test Health Connect',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/home/update-profile'),
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
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
                    onPressed: _onLogout,
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
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmergencyContactChildren(EmergencyContactsState state) {
    if (state.isLoadingInitial && state.items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.error != null && state.items.isEmpty) {
      return [
        Text(
          state.error!.replaceFirst('Exception: ', ''),
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
            onPressed: () =>
                ref.read(emergencyContactsProvider.notifier).fetchInitial(),
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

    if (state.items.isEmpty) {
      return const [
        _InfoRow(label: 'Nama', value: '-'),
        _InfoRow(label: 'Nomor Telepon', value: '-'),
      ];
    }

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE64060), Color(0xFFFF7A93)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: const Text(
        'Profil Saya',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
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
              fontSize: 24,
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
                  fontSize: 15,
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
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
              fontSize: 19,
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
                fontSize: 16,
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
                fontSize: 17,
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

  const _ActionRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {},
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
                    fontSize: 16,
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
