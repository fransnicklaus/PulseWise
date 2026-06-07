import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/core/notifications/fcm_service.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  final String token;
  final String patientId;

  const ProfileSetupPage({
    super.key,
    required this.token,
    required this.patientId,
  });

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  static const _fieldRadius = 15.0;
  static const _fieldMinHeight = 68.0;
  static const _fieldFillColor = Color(0xFFF9FBFD);

  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _heightController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedBirthDate;
  String? _selectedBloodType;
  bool? _isSmoking;
  bool? _isElectricSmoking;
  bool _isSubmitting = false;
  bool _showBirthDateValidation = false;

  void _goSafely(String location, {Object? extra}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(location, extra: extra);
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Dio _buildDio() {
    return createApiDio(resolveApiBaseUrl());
  }

  String _extractApiError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      constraints: const BoxConstraints(minHeight: _fieldMinHeight),
      hintText: hint,
      hintStyle: _fieldHintTextStyle,
      prefixIcon: _buildFieldIcon(icon),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 56,
        minHeight: _fieldMinHeight,
      ),
      filled: true,
      fillColor: _fieldFillColor,
      focusColor: _fieldFillColor,
      hoverColor: _fieldFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      errorStyle: const TextStyle(fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: Color(0xFFE64060), width: 1.3),
      ),
    );
  }

  Widget _buildFieldIcon(IconData icon) {
    return SizedBox(
      width: 56,
      height: _fieldMinHeight,
      child: Center(
        child: Icon(icon, color: const Color(0xFF536278), size: 26),
      ),
    );
  }

  InputDecoration _selectionDecoration({
    required IconData icon,
  }) {
    return _inputDecoration(
      hint: '',
      icon: icon,
    ).copyWith(
      hintText: null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      suffixIconConstraints: const BoxConstraints(
        minWidth: 52,
        minHeight: _fieldMinHeight,
      ),
    );
  }

  TextStyle get _fieldHintTextStyle => const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.1,
      );

  TextStyle get _fieldValueTextStyle => const TextStyle(
        fontSize: 18,
        color: Color(0xFF1F2937),
        fontWeight: FontWeight.w500,
        height: 1.1,
      );

  TextStyle get _dropdownTextStyle => _fieldValueTextStyle;

  DropdownMenuItem<String> _dropdownItem(String value) {
    return DropdownMenuItem<String>(
      value: value,
      alignment: Alignment.centerLeft,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(value, style: _dropdownTextStyle),
      ),
    );
  }

  DropdownMenuItem<bool> _dropdownItemBool(bool value, String label) {
    return DropdownMenuItem<bool>(
      value: value,
      alignment: Alignment.centerLeft,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: _dropdownTextStyle),
      ),
    );
  }

  Widget _buildBirthDateField() {
    return InkWell(
      borderRadius: BorderRadius.circular(_fieldRadius),
      onTap: _pickBirthDate,
      child: InputDecorator(
        isEmpty: _selectedBirthDate == null,
        decoration: _selectionDecoration(
          icon: FluentIcons.calendar_24_regular,
        ).copyWith(
          suffixIcon: const Icon(
            FluentIcons.chevron_down_24_regular,
            color: Color(0xFF64748B),
            size: 24,
          ),
        ),
        child: Text(
          _birthDateLabel(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _selectedBirthDate == null
              ? _fieldHintTextStyle
              : _fieldValueTextStyle,
        ),
      ),
    );
  }

  String _birthDateLabel() {
    final date = _selectedBirthDate;
    if (date == null) return 'Pilih tanggal lahir';

    const months = [
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _showBirthDateValidation = false;
      });
    }
  }

  Future<void> _persistSession({
    required String token,
    required String userId,
  }) async {
    await AppSessionStore.saveSession(
      token: token,
      userId: userId,
      role: AppRoles.patient,
    );
  }

  Future<void> _submitProfile() async {
    final canProceed = _formKey.currentState?.validate() ?? false;
    if (!canProceed || _isSubmitting) return;

    if (_selectedBirthDate == null) {
      setState(() => _showBirthDateValidation = true);
      AppToast.warning(context, 'Tanggal lahir wajib dipilih');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final date = _selectedBirthDate!;
      final dateOfBirth =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final dio = _buildDio();
      final response = await dio.put<Map<String, dynamic>>(
        '/patients/${widget.patientId}/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${widget.token}',
          },
        ),
        data: {
          'dateOfBirth': dateOfBirth,
          'sex': (_selectedGender ?? '').toLowerCase(),
          'heightCm': double.parse(_heightController.text.trim()),
          // 'isSmoking': _isSmoking ?? false,
          // 'isElectricSmoking': _isElectricSmoking ?? false,
          'bloodType': _selectedBloodType ?? 'O+',
          'address': _addressController.text.trim(),
        },
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw Exception((body['message'] ?? 'Update profil gagal').toString());
      }

      await _persistSession(token: widget.token, userId: widget.patientId);
      await AppFcmService.instance.registerTokenForCurrentSession(
        trigger: 'profile_setup',
      );
      if (!mounted) return;

      AppToast.success(context, 'Profil berhasil dilengkapi');
      final wantsMlQuestionnaire = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kuesioner Insight Harian',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Apakah Anda ingin mengisi kuesioner untuk membantu menyusun insight dan ringkasan pribadi Anda?',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF475569),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE64060),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ya, Isi Kuesioner',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
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
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tidak, Lanjut ke Beranda',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!mounted) return;

      if (wantsMlQuestionnaire == true) {
        _goSafely(
          '/home/ml-questionnaire',
          extra: {
            AppSessionStore.tokenPrefsKey: widget.token,
            AppSessionStore.userIdPrefsKey: widget.patientId,
          },
        );
      } else {
        ref.read(previousNavIndexProvider.notifier).state = 0;
        ref.read(dashboardNavIndexProvider.notifier).state = 0;
        ref.read(healthConnectLoginPromptArmedProvider.notifier).state = true;
        _goSafely('/home');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, _extractApiError(e));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFADB5),
                    Color(0xFFE64060),
                  ],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: size.height * 0.08),
                  ),
                  SliverToBoxAdapter(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Color.fromRGBO(195, 78, 80, 0.16),
                              offset: Offset(0, 3.98),
                              blurRadius: 17.6,
                            ),
                          ],
                        ),
                        children: [
                          TextSpan(
                            text: 'Pulse ',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'Wise',
                            style: TextStyle(color: Color(0xFFE64060)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: size.height * 0.05),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 56),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(47),
                              topRight: Radius.circular(47),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 72, 24, 36),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Center(
                                  child: Text(
                                    'Lengkapi Profil',
                                    style: TextStyle(
                                      color: Color(0xFF536278),
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Product Sans',
                                    ),
                                  ),
                                ),
                                // const SizedBox(height: 12),
                                // const Center(
                                //   child: Text(
                                //     'Langkah akhir setelah verifikasi OTP',
                                //     style: TextStyle(
                                //       color: Color(0xFF64748B),
                                //       fontSize: 16,
                                //     ),
                                //     textAlign: TextAlign.center,
                                //   ),
                                // ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          DropdownButtonFormField<String>(
                                            dropdownColor: Colors.white,
                                            value: _selectedGender,
                                            isExpanded: true,
                                            itemHeight: _fieldMinHeight,
                                            alignment: Alignment.centerLeft,
                                            hint: Text(
                                              'Jenis Kelamin',
                                              style: _fieldHintTextStyle,
                                            ),
                                            icon: const Icon(
                                              FluentIcons
                                                  .chevron_down_24_regular,
                                              size: 24,
                                              color: Color(0xFF64748B),
                                            ),
                                            style: _dropdownTextStyle,
                                            items: [
                                              _dropdownItem('Male'),
                                              _dropdownItem('Female')
                                            ],
                                            decoration: _selectionDecoration(
                                              icon: FluentIcons
                                                  .person_feedback_24_regular,
                                            ),
                                            onChanged: (value) => setState(
                                                () => _selectedGender = value),
                                            validator: (value) => (value ==
                                                        null ||
                                                    value.isEmpty)
                                                ? 'Jenis kelamin wajib dipilih'
                                                : null,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildBirthDateField(),
                                          if (_selectedBirthDate == null &&
                                              _showBirthDateValidation)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                  top: 6, left: 4),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Tanggal lahir wajib dipilih',
                                                  style: TextStyle(
                                                    color: Color(0xFFB91C1C),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: _addressController,
                                            maxLines: 1,
                                            textAlignVertical:
                                                TextAlignVertical.center,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF1F2937),
                                            ),
                                            decoration: _inputDecoration(
                                              hint: 'Alamat',
                                              icon: FluentIcons
                                                  .location_24_regular,
                                            ),
                                            validator: (value) =>
                                                (value ?? '').trim().isEmpty
                                                    ? 'Alamat wajib diisi'
                                                    : null,
                                          ),
                                          const SizedBox(height: 12),
                                          DropdownButtonFormField<String>(
                                            dropdownColor: Colors.white,
                                            value: _selectedBloodType,
                                            isExpanded: true,
                                            itemHeight: _fieldMinHeight,
                                            alignment: Alignment.centerLeft,
                                            hint: Text(
                                              'Golongan Darah',
                                              style: _fieldHintTextStyle,
                                            ),
                                            icon: const Icon(
                                              FluentIcons
                                                  .chevron_down_24_regular,
                                              size: 24,
                                              color: Color(0xFF64748B),
                                            ),
                                            style: _dropdownTextStyle,
                                            items: [
                                              _dropdownItem('A+'),
                                              _dropdownItem('A-'),
                                              _dropdownItem('B+'),
                                              _dropdownItem('B-'),
                                              _dropdownItem('AB+'),
                                              _dropdownItem('AB-'),
                                              _dropdownItem('O+'),
                                              _dropdownItem('O-'),
                                            ],
                                            decoration: _selectionDecoration(
                                              icon: FluentIcons
                                                  .heart_pulse_24_regular,
                                            ),
                                            onChanged: (value) => setState(() =>
                                                _selectedBloodType = value),
                                            validator: (value) => (value ==
                                                        null ||
                                                    value.isEmpty)
                                                ? 'Golongan darah wajib dipilih'
                                                : null,
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: _heightController,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF1F2937),
                                            ),
                                            decoration: _inputDecoration(
                                              hint: 'Tinggi Badan',
                                              icon:
                                                  FluentIcons.ruler_24_regular,
                                            ).copyWith(
                                              suffixText: 'cm',
                                              suffixStyle: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            validator: (value) {
                                              final text = (value ?? '').trim();
                                              if (text.isEmpty) {
                                                return 'Tinggi badan wajib diisi';
                                              }
                                              if (double.tryParse(text) ==
                                                  null) {
                                                return 'Tinggi badan harus angka';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          // DropdownButtonFormField<bool>(
                                          //   dropdownColor: Colors.white,
                                          //   value: _isSmoking,
                                          //   isExpanded: true,
                                          //   itemHeight: _fieldMinHeight,
                                          //   alignment: Alignment.centerLeft,
                                          //   icon: const Icon(
                                          //     FluentIcons.chevron_down_24_regular,
                                          //     size: 24,
                                          //     color: Color(0xFF64748B),
                                          //   ),
                                          //   style: _dropdownTextStyle,
                                          //   items: [
                                          //     _dropdownItemBool(true, 'Ya'),
                                          //     _dropdownItemBool(false, 'Tidak'),
                                          //   ],
                                          //   decoration: _inputDecoration(
                                          //     hint: 'Apakah Anda Merokok?',
                                          //     icon:
                                          //         FluentIcons.question_24_regular,
                                          //   ).copyWith(
                                          //     contentPadding:
                                          //         const EdgeInsets.symmetric(
                                          //             horizontal: 18),
                                          //   ),
                                          //   onChanged: (value) => setState(
                                          //       () => _isSmoking = value),
                                          //   validator: (value) => value == null
                                          //       ? 'Wajib dipilih'
                                          //       : null,
                                          // ),
                                          // const SizedBox(height: 12),
                                          // DropdownButtonFormField<bool>(
                                          //   dropdownColor: Colors.white,
                                          //   value: _isElectricSmoking,
                                          //   isExpanded: true,
                                          //   itemHeight: _fieldMinHeight,
                                          //   alignment: Alignment.centerLeft,
                                          //   icon: const Icon(
                                          //     FluentIcons.chevron_down_24_regular,
                                          //     size: 24,
                                          //     color: Color(0xFF64748B),
                                          //   ),
                                          //   style: _dropdownTextStyle,
                                          //   items: [
                                          //     _dropdownItemBool(true, 'Ya'),
                                          //     _dropdownItemBool(false, 'Tidak'),
                                          //   ],
                                          //   decoration: _inputDecoration(
                                          //     hint: 'Merokok Elektrik (Vape)?',
                                          //     icon:
                                          //         FluentIcons.question_24_regular,
                                          //   ).copyWith(
                                          //     contentPadding:
                                          //         const EdgeInsets.symmetric(
                                          //             horizontal: 18),
                                          //   ),
                                          //   onChanged: (value) => setState(
                                          //       () => _isElectricSmoking = value),
                                          //   validator: (value) => value == null
                                          //       ? 'Wajib dipilih'
                                          //       : null,
                                          // ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isSubmitting ? null : _submitProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE64060),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'SELESAIKAN PROFIL',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/svgs/pulsewise_logo.svg',
                              width: 122,
                              height: 122,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
