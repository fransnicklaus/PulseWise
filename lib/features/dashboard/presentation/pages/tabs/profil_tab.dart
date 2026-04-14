import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
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

    if (token.isEmpty) {
      debugPrint('[AUTH_TOKEN] <empty>');
      if (!mounted) return;
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
      AppToast.warning(context, 'Ukuran avatar maksimal 5 MB.');
      return;
    }

    final filename = selected.name.isEmpty ? 'avatar.jpg' : selected.name;
    MultipartFile file;
    if (selected.path != null && selected.path!.isNotEmpty) {
      file = await MultipartFile.fromFile(selected.path!, filename: filename);
    } else if (selected.bytes != null) {
      file = MultipartFile.fromBytes(selected.bytes!, filename: filename);
    } else {
      AppToast.warning(context, 'File gambar tidak valid.');
      return;
    }

    setState(() => _isUploadingAvatar = true);
    try {
      await ref.read(profileApiProvider).uploadAvatar(file: file);
      ref.invalidate(patientProfileProvider);
      ref.invalidate(authMeProvider);
      await ref.read(patientProfileProvider.future);
      await ref.read(authMeProvider.future);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 140),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
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
                        error.toString(),
                        style: const TextStyle(
                          color: Color(0xFF7F1D1D),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              ref.invalidate(patientProfileProvider),
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
            ],
          ),
          data: (profile) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                profile.fullName,
                authMeAsync.asData?.value.avatarPhoto.isNotEmpty == true
                    ? authMeAsync.asData?.value.avatarPhoto
                    : profile.avatarUrl,
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Informasi Pribadi',
                children: [
                  _InfoRow(
                    label: 'Nama Lengkap',
                    value: profile.fullName.isEmpty ? '-' : profile.fullName,
                  ),
                  _InfoRow(
                    label: 'Email',
                    value: profile.email.isEmpty ? '-' : profile.email,
                  ),
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
              _SectionCard(
                title: 'Pengaturan Akun',
                children: const [
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
                    onPressed: () {},
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
            onPressed: () => ref.read(emergencyContactsProvider.notifier).fetchInitial(),
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
        value: mainContact.contactLabel.isEmpty ? '-' : mainContact.contactLabel,
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

  Widget _buildHeader([String? fullName, String? avatarUrl]) {
    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
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
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: hasAvatar
                      ? Image.network(
                          avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 42,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 42,
                        ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE64060)),
                      ),
                      child: _isUploadingAvatar
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFE64060),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Color(0xFFE64060),
                              size: 16,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profil Saya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (fullName != null && fullName.isNotEmpty)
                      ? fullName
                      : 'Kelola data pribadi dan kesehatan Anda',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ketuk ikon kamera untuk ubah avatar',
                  style: TextStyle(
                    color: Color(0xFFFFE4EA),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
