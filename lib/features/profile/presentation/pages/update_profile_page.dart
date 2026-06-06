import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/profile/data/models/profile_models.dart';
import 'package:pulsewise/features/profile/presentation/providers/profile_provider.dart';

class UpdateProfilePage extends ConsumerStatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  ConsumerState<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends ConsumerState<UpdateProfilePage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  DateTime? selectedBirthDate;
  String? selectedSex;
  String? selectedBloodType;

  bool isSaving = false;
  bool _isInit = false;

  PatientProfile _buildEmptyProfile() {
    return const PatientProfile(
      patientId: '',
      firstName: '',
      lastName: '',
      email: '',
      address: '',
      dateOfBirth: null,
      sex: '',
      bodyHeightCm: '',
      bloodType: '',
      healthConnectPreference: null,
      healthConnectStatus: null,
      isSmoking: false,
      isElectricSmoking: false,
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    heightController.dispose();
    super.dispose();
  }

  void _initData(PatientProfile profile) {
    if (_isInit) return;
    _isInit = true;

    addressController.text = profile.address;
    heightController.text = profile.bodyHeightCm.trim();

    selectedBirthDate = profile.dateOfBirth;
    selectedSex = profile.sex.toLowerCase().trim();
    if (selectedSex != 'male' && selectedSex != 'female') {
      selectedSex = 'male';
    }

    const bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    selectedBloodType = profile.bloodType.trim().isEmpty
        ? 'O+'
        : profile.bloodType.trim().toUpperCase();
    if (!bloodTypes.contains(selectedBloodType)) {
      selectedBloodType = 'O+';
    }
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

  String _formatDateForApi(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          selectedBirthDate ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE64060),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => selectedBirthDate = picked);
  }

  Future<void> saveChanges() async {
    if (isSaving) return;

    final address = addressController.text.trim();
    if (address.isEmpty) {
      AppToast.warning(context, 'Alamat wajib diisi');
      return;
    }

    final height = double.tryParse(heightController.text.trim());
    if (height == null || height <= 0) {
      AppToast.warning(context, 'Tinggi badan tidak valid');
      return;
    }

    if (selectedBirthDate == null) {
      AppToast.warning(context, 'Tanggal lahir wajib dipilih');
      return;
    }

    setState(() => isSaving = true);
    try {
      await ref.read(patientProfileApiProvider).updatePatientProfile(
            dateOfBirth: _formatDateForApi(selectedBirthDate!),
            sex: selectedSex ?? 'male',
            heightCm: height,
            isSmoking: false,
            isElectricSmoking: false,
            bloodType: selectedBloodType ?? 'O+',
            address: address,
          );

      ref.invalidate(patientProfileProvider);
      await ref.read(patientProfileProvider.future);

      if (!mounted) return;
      context.pop();
      AppToast.success(context, 'Profil berhasil diperbarui');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Widget _buildProfileForm(PatientProfile profile,
      {bool isInitialSetup = false}) {
    if (!_isInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _initData(profile);
          });
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        if (isInitialSetup) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDA4AF)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil Anda belum disiapkan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF881337),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Lengkapi data profil berikut agar akun Anda dapat digunakan dengan normal.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF9F1239),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        _buildSectionTitle('Informasi Pribadi'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: addressController,
          label: 'Alamat Tempat Tinggal',
          icon: Icons.home_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: heightController,
          label: 'Tinggi Badan (cm)',
          icon: Icons.height,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 20),
        _buildDropdown<String>(
          label: 'Jenis Kelamin',
          icon: Icons.person_outline,
          value: selectedSex,
          items: const [
            DropdownMenuItem(
              value: 'male',
              child: Text('Laki-laki', style: TextStyle(fontSize: 18)),
            ),
            DropdownMenuItem(
              value: 'female',
              child: Text('Perempuan', style: TextStyle(fontSize: 18)),
            ),
          ],
          onChanged: (val) => setState(() => selectedSex = val),
        ),
        const SizedBox(height: 20),
        _buildDropdown<String>(
          label: 'Golongan Darah',
          icon: Icons.bloodtype_outlined,
          value: selectedBloodType,
          items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type, style: const TextStyle(fontSize: 18)),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => selectedBloodType = val),
        ),
        const SizedBox(height: 20),
        _buildDateSelector(),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE64060),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isInitialSetup
                        ? 'SIMPAN & LENGKAPI PROFIL'
                        : 'SIMPAN PERUBAHAN',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(patientProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Edit Profil',
        // subtitle: 'Kelola pengingat obat Anda',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: profileAsync.when(
        data: (profile) => _buildProfileForm(profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          if (isPatientProfileNotSetupError(err)) {
            return _buildProfileForm(
              _buildEmptyProfile(),
              isInitialSetup: true,
            );
          }

          if (isNetworkRequestError(err)) {
            return NoConnectionState.page(
              title: 'Profil edit belum bisa dimuat',
              message:
                  'Kami belum bisa mengambil data profil untuk diedit karena koneksi internet tidak tersedia atau sedang tidak stabil.',
              onRetry: () {
                ref.invalidate(patientProfileProvider);
              },
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Gagal memuat profil:\n$err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 18, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 18, color: Color(0xFF64748B)),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(icon, color: const Color(0xFF0F172A), size: 28),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE64060), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down,
            size: 32, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 18, color: Color(0xFF64748B)),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(icon, color: const Color(0xFF0F172A), size: 28),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE64060), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: pickBirthDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.calendar_today_outlined,
                  color: Color(0xFF0F172A), size: 28),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal Lahir',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedBirthDate == null
                        ? 'Pilih Tanggal Lahir'
                        : _formatDate(selectedBirthDate),
                    style: TextStyle(
                      fontSize: 18,
                      color: selectedBirthDate == null
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child:
                  Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
