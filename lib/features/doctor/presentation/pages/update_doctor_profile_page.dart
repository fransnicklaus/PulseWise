import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_profile_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_profile_provider.dart';

class UpdateDoctorProfilePage extends ConsumerStatefulWidget {
  const UpdateDoctorProfilePage({super.key});

  @override
  ConsumerState<UpdateDoctorProfilePage> createState() =>
      _UpdateDoctorProfilePageState();
}

class _UpdateDoctorProfilePageState
    extends ConsumerState<UpdateDoctorProfilePage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final specializationController = TextEditingController();
  final licenseNoController = TextEditingController();
  final hospitalNameController = TextEditingController();

  bool isSaving = false;
  bool isInitialized = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    specializationController.dispose();
    licenseNoController.dispose();
    hospitalNameController.dispose();
    super.dispose();
  }

  void _initData(DoctorProfile profile) {
    if (isInitialized) return;
    isInitialized = true;

    firstNameController.text = profile.firstName;
    lastNameController.text = profile.lastName;
    specializationController.text = profile.specialization;
    licenseNoController.text = profile.licenseNo;
    hospitalNameController.text = profile.hospitalName;
  }

  Future<void> saveChanges() async {
    if (isSaving) return;

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final specialization = specializationController.text.trim();
    final licenseNo = licenseNoController.text.trim();
    final hospitalName = hospitalNameController.text.trim();

    if (firstName.isEmpty) {
      AppToast.warning(context, 'Nama depan wajib diisi');
      return;
    }

    if (lastName.isEmpty) {
      AppToast.warning(context, 'Nama belakang wajib diisi');
      return;
    }

    if (specialization.isEmpty) {
      AppToast.warning(context, 'Spesialisasi wajib diisi');
      return;
    }

    if (licenseNo.isEmpty) {
      AppToast.warning(context, 'Nomor izin wajib diisi');
      return;
    }

    if (hospitalName.isEmpty) {
      AppToast.warning(context, 'Nama rumah sakit wajib diisi');
      return;
    }

    setState(() => isSaving = true);
    try {
      await ref.read(doctorProfileApiProvider).updateDoctorProfile(
            firstName: firstName,
            lastName: lastName,
            specialization: specialization,
            licenseNo: licenseNo,
            hospitalName: hospitalName,
          );

      ref.invalidate(doctorProfileProvider);
      await ref.read(doctorProfileProvider.future);

      if (!mounted) return;
      context.pop();
      AppToast.success(context, 'Profil dokter berhasil diperbarui');
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(doctorProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Edit Profil Dokter',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (!isInitialized) {
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
              _buildSectionTitle('Informasi Dokter'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: firstNameController,
                label: 'Nama Depan',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: lastNameController,
                label: 'Nama Belakang',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: specializationController,
                label: 'Spesialisasi',
                icon: Icons.local_hospital_outlined,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: licenseNoController,
                label: 'Nomor Izin',
                icon: Icons.verified_user_outlined,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: hospitalNameController,
                label: 'Rumah Sakit / Klinik',
                icon: Icons.apartment_outlined,
              ),
              const SizedBox(height: 20),
              _buildReadOnlyField(
                label: 'Email',
                value: profile.email.isEmpty ? '-' : profile.email,
                icon: Icons.email_outlined,
              ),
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
                      : const Text(
                          'SIMPAN PERUBAHAN',
                          style: TextStyle(
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Gagal memuat profil dokter:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
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
        style: const TextStyle(fontSize: 18, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 18, color: Color(0xFF64748B)),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(icon, color: const Color(0xFF0F172A), size: 28),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
