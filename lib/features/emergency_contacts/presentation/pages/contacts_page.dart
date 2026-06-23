import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/emergency_contacts/data/models/emergency_contact_models.dart';
import 'package:pulsewise/features/emergency_contacts/presentation/providers/emergency_contacts_provider.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emergencyContactsProvider.notifier).fetchInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 220;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(emergencyContactsProvider.notifier).fetchNextPage();
    }
  }

  Future<void> _refresh() async {
    try {
      await ref.read(emergencyContactsProvider.notifier).fetchInitial();
    } catch (_) {
      // Let the page keep stale data or render its fallback state.
    }
  }

  Future<void> _openDialer(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _openWhatsApp(String number) async {
    final phone = _normalizeForWhatsApp(number);
    if (phone.isEmpty) {
      AppToast.warning(context, 'Nomor WhatsApp tidak valid.');
      return;
    }

    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    AppToast.warning(context, 'WhatsApp tidak tersedia di perangkat ini.');
  }

  String _normalizeForWhatsApp(String raw) {
    var value = raw.replaceAll(RegExp(r'[^0-9+]'), '');

    if (value.startsWith('+62')) {
      value = '62${value.substring(3)}';
    } else if (value.startsWith('0')) {
      value = '62${value.substring(1)}';
    } else if (!value.startsWith('62')) {
      value = value.replaceFirst(RegExp(r'^\+'), '');
    }

    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(emergencyContactsProvider);
    final hasNetworkError = contactsState.errorCause != null &&
        isNetworkRequestError(contactsState.errorCause!);
    final showInitialNoConnection = contactsState.error != null &&
        contactsState.items.isEmpty &&
        hasNetworkError;
    final showRefreshNoConnection = contactsState.error != null &&
        contactsState.items.isNotEmpty &&
        hasNetworkError;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Kontak Darurat',
        subtitle: 'Hubungi segera jika diperlukan',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFFE64060),
        backgroundColor: Colors.white,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: contactsState.items.length +
              3 +
              (showRefreshNoConnection ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildEmergencyCallCard();
            }

            if (index == 1) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Daftar Kontak Darurat',
                        style: TextStyle(
                          color: Color(0xFF525252),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await context.push('/home/contacts/add');
                        if (!context.mounted) return;
                        if (result == true) {
                          await ref
                              .read(emergencyContactsProvider.notifier)
                              .fetchInitial();
                          if (!context.mounted) return;
                          AppToast.success(
                            context,
                            'Kontak darurat berhasil ditambahkan',
                          );
                        }
                      },
                      icon: const Icon(Icons.add, size: 22),
                      label: const Text(
                        'Tambah Kontak',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE64060),
                        minimumSize: const Size(0, 50),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (index == 2 &&
                contactsState.isLoadingInitial &&
                contactsState.items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (index == 2 &&
                contactsState.error != null &&
                contactsState.items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: showInitialNoConnection
                    ? NoConnectionState.card(
                        title: 'Kontak darurat belum bisa dimuat',
                        message:
                            'Kami belum bisa mengambil daftar kontak darurat karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                        onRetry: () {
                          ref
                              .read(emergencyContactsProvider.notifier)
                              .fetchInitial();
                        },
                      )
                    : Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          border: Border.all(color: const Color(0xFFFECACA)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gagal memuat kontak',
                              style: TextStyle(
                                color: Color(0xFF991B1B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              contactsState.error!,
                              style: const TextStyle(
                                color: Color(0xFF7F1D1D),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => ref
                                  .read(emergencyContactsProvider.notifier)
                                  .fetchInitial(),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
              );
            }

            const firstItemIndex = 2;
            final adjustedFirstItemIndex =
                firstItemIndex + (showRefreshNoConnection ? 1 : 0);
            final lastItemIndexExclusive =
                adjustedFirstItemIndex + contactsState.items.length;

            if (showRefreshNoConnection && index == firstItemIndex) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: NoConnectionState.compact(
                  title: 'Koneksi terputus',
                  message:
                      'Menampilkan kontak darurat terakhir yang berhasil dimuat. Sambungkan internet untuk memperbarui daftar terbaru.',
                  onRetry: () {
                    ref.read(emergencyContactsProvider.notifier).fetchInitial();
                  },
                ),
              );
            }

            if (index >= adjustedFirstItemIndex &&
                index < lastItemIndexExclusive) {
              final contact =
                  contactsState.items[index - adjustedFirstItemIndex];
              return _EmergencyContactCard(
                contact: contact,
                onCallPressed: () => _openDialer(contact.contactNumber),
                onWhatsappPressed: () => _openWhatsApp(contact.contactNumber),
                onEditPressed: () => _openEditContactDialog(contact),
                onDeletePressed: () => _deleteContact(contact),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Center(
                child: contactsState.isLoadingMore
                    ? const CircularProgressIndicator()
                    : contactsState.items.isEmpty
                        ? const Text(
                            'Belum ada kontak darurat',
                            style: TextStyle(
                                color: Color(0xFF64748B), fontSize: 18),
                          )
                        : const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmergencyCallCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C42), Color(0xFFE64060)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ambulans Darurat',
                      style: TextStyle(
                        color: Color(0xFFFFF4B8),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Layanan 24 Jam',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _openDialer('112'),
              child: const Text(
                'HUBUNGI 112',
                style: TextStyle(
                  color: Color(0xFFE64060),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditContactDialog(EmergencyContact contact) async {
    const brand = Color(0xFFE64060);
    const textPrimary = Color(0xFF334155);
    const textMuted = Color(0xFF64748B);
    const borderSoft = Color(0xFFE2E8F0);
    const surfaceSoft = Color(0xFFFFF5F7);

    final nameController = TextEditingController(text: contact.contactLabel);
    final phoneController = TextEditingController(text: contact.contactNumber);
    bool isPriority = contact.isPrioritas == true;
    bool isSubmitting = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBC7D1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        // decoration: BoxDecoration(
                        //   color: surfaceSoft,
                        //   borderRadius: BorderRadius.circular(12),
                        // ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit, color: brand, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Edit Kontak Darurat',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nama Kontak',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        enabled: !isSubmitting,
                        cursorColor: brand,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          // fillColor: Colors.white,
                          hintText: 'Masukkan nama',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 18,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderSoft),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderSoft),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: brand, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nomor Telepon',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: phoneController,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.phone,
                        cursorColor: brand,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          // fillColor: Colors.white,
                          hintText: '08xx-xxxx-xxxx',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 18,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderSoft),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderSoft),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: brand, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isPriority,
                        activeColor: brand,
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                setLocalState(() {
                                  isPriority = value ?? false;
                                });
                              },
                        title: const Text(
                          'Jadikan Kontak Utama',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: brand,
                                side: const BorderSide(color: brand),
                                minimumSize: const Size.fromHeight(54),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final label = nameController.text.trim();
                                      final number =
                                          phoneController.text.trim();
                                      final digitsOnly = number.replaceAll(
                                          RegExp(r'[^0-9]'), '');

                                      if (label.isEmpty) {
                                        AppToast.warning(context,
                                            'Nama kontak wajib diisi.');
                                        return;
                                      }
                                      if (digitsOnly.length < 8) {
                                        AppToast.warning(context,
                                            'Nomor telepon tidak valid.');
                                        return;
                                      }

                                      setLocalState(() => isSubmitting = true);
                                      try {
                                        await ref
                                            .read(emergencyContactsProvider
                                                .notifier)
                                            .updateEmergencyContact(
                                              emergencyContactId:
                                                  contact.emergencyContactId,
                                              contactLabel: label,
                                              contactNumber: number,
                                              isPriority: isPriority,
                                            );
                                        if (!sheetContext.mounted) return;
                                        Navigator.of(sheetContext).pop(true);
                                      } catch (e) {
                                        AppToast.warning(
                                          context,
                                          e
                                              .toString()
                                              .replaceFirst('Exception: ', ''),
                                        );
                                        setLocalState(
                                            () => isSubmitting = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brand,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Simpan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();

    if (result == true) {
      AppToast.success(context, 'Kontak darurat berhasil diperbarui');
      if (!mounted) return;
      await ref.read(emergencyContactsProvider.notifier).fetchInitial();
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setLocalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 40,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Hapus Kontak?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yakin ingin menghapus ${contact.contactLabel}?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isDeleting
                              ? null
                              : () => Navigator.of(sheetContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFFE64060),
                            side: const BorderSide(color: Color(0xFFE64060)),
                            minimumSize: const Size.fromHeight(54),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isDeleting
                              ? null
                              : () async {
                                  setLocalState(() => isDeleting = true);
                                  try {
                                    await ref
                                        .read(
                                            emergencyContactsProvider.notifier)
                                        .deleteEmergencyContact(
                                          contact.emergencyContactId,
                                        );
                                    if (!sheetContext.mounted) return;
                                    Navigator.of(sheetContext).pop(true);
                                  } catch (e) {
                                    AppToast.warning(
                                      context,
                                      e
                                          .toString()
                                          .replaceFirst('Exception: ', ''),
                                    );
                                    setLocalState(() => isDeleting = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE64060),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: isDeleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Hapus'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    try {
      AppToast.success(context, 'Kontak darurat berhasil dihapus');
      if (!mounted) return;
      await ref.read(emergencyContactsProvider.notifier).fetchInitial();
    } catch (e) {
      if (!mounted) return;
      AppToast.warning(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCallPressed;
  final VoidCallback onWhatsappPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const _EmergencyContactCard({
    required this.contact,
    required this.onCallPressed,
    required this.onWhatsappPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPriority = contact.isPrioritas;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7E7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFFE64060),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.contactLabel,
                        style: const TextStyle(
                          color: Color(0xFF525252),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        contact.contactNumber,
                        style: const TextStyle(
                          color: Color(0xFF62748E),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPriority == true)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE64060),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Kontak Utama',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditPressed,
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text(
                      'Edit',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1D4ED8),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDeletePressed,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text(
                      'Hapus',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onWhatsappPressed,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'WHATSAPP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D9744),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onCallPressed,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'HUBUNGI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddContactPage extends ConsumerStatefulWidget {
  const AddContactPage({super.key});

  @override
  ConsumerState<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends ConsumerState<AddContactPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isPrimaryContact = false;
  bool _isSubmitting = false;

  bool get _canImportDeviceContacts => !kIsWeb;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Tambah Kontak',
        subtitle: 'Tambahkan kontak darurat baru',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nama Lengkap',
              style: TextStyle(
                color: Color(0xFF525252),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              enabled: !_isSubmitting,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(
                hintText: 'Masukkan nama',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nomor Telepon',
              style: TextStyle(
                color: Color(0xFF525252),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              enabled: !_isSubmitting,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: _fieldDecoration(
                hintText: '08xx-xxxx-xxxx',
                icon: Icons.phone_outlined,
              ),
            ),
            if (_canImportDeviceContacts) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickFromPhoneContacts,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE64060),
                    side: const BorderSide(color: Color(0xFFE64060)),
                    minimumSize: const Size.fromHeight(58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.contact_phone_outlined, size: 22),
                  label: const Text(
                    'Pilih dari Kontak HP',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.all(14),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFFFFBFB),
              //     borderRadius: BorderRadius.circular(14),
              //     border: Border.all(color: const Color(0xFFFBC8D2)),
              //   ),
              //   child: const Text(
              //     'Impor kontak dari perangkat belum tersedia di web app. Tambahkan kontak dukungan secara manual.',
              //     style: TextStyle(
              //       color: Color(0xFF9F1239),
              //       fontSize: 15,
              //       fontWeight: FontWeight.w600,
              //       height: 1.45,
              //     ),
              //   ),
              // ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Checkbox(
                      value: _isPrimaryContact,
                      onChanged: _isSubmitting
                          ? null
                          : (value) => setState(
                              () => _isPrimaryContact = value ?? false),
                      activeColor: const Color(0xFFE64060),
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadikan Kontak Utama',
                          style: TextStyle(
                            color: Color(0xFF525252),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kontak utama akan ditampilkan di bagian paling atas dan mudah diakses',
                          style: TextStyle(
                            color: Color(0xFF62748E),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF285DBE),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tips!',
                          style: TextStyle(
                            color: Color(0xFF285DBE),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pastikan nomor telepon yang Anda masukkan benar dan dapat dihubungi sewaktu-waktu untuk keadaan darurat.',
                          style: TextStyle(
                            color: Color(0xFF285DBE),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE64060),
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add, color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Simpan Kontak',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF525252),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 18),
      prefixIcon: Icon(icon, color: const Color(0xFF62748E), size: 24),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE64060), width: 2),
      ),
    );
  }

  Future<void> _submit() async {
    final contactLabel = _nameController.text.trim();
    final contactNumber = _phoneController.text.trim();

    if (contactLabel.isEmpty) {
      _showMessage('Nama kontak wajib diisi.');
      return;
    }

    final digitsOnly = contactNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 8) {
      _showMessage('Nomor telepon tidak valid.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(emergencyContactsProvider.notifier).addEmergencyContact(
            contactLabel: contactLabel,
            contactNumber: contactNumber,
            isPriority: _isPrimaryContact,
          );

      if (!mounted) return;
      // context.pop(true);
      context.pop();
      AppToast.success(context, 'Kontak darurat berhasil ditambahkan');
      await ref.read(emergencyContactsProvider.notifier).fetchInitial();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickFromPhoneContacts() async {
    if (!_canImportDeviceContacts) {
      _showMessage(
        'Impor kontak dari perangkat belum tersedia di web app. Silakan isi manual.',
      );
      return;
    }

    try {
      final hasPermission = await FlutterContacts.requestPermission(
        readonly: true,
      );
      if (!hasPermission) {
        _showMessage('Izin kontak ditolak. Silakan isi manual.');
        return;
      }

      try {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          _applyPickedContact(contact);
          // if (!mounted) return;
          // AppToast.success(context, 'Kontak berhasil dipilih');
          return;
        }
      } catch (_) {
        // Some devices/ROMs do not support external contact picker reliably.
      }

      // final contact = await _showInAppContactPicker();
      // if (contact == null) {
      //   _showMessage('Tidak ada kontak yang dipilih.');
      //   return;
      // }

      // _applyPickedContact(contact);
      // if (!mounted) return;
      // AppToast.success(context, 'Kontak berhasil dipilih');
    } on MissingPluginException {
      if (!mounted) return;
      AppToast.warning(
        context,
        'Fitur kontak belum aktif di sesi ini. Tutup app lalu jalankan ulang dari build terbaru.',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _applyPickedContact(Contact contact) {
    String phone = '';
    if (contact.phones.isNotEmpty) {
      phone = _normalizePhone(contact.phones.first.number);
    }

    setState(() {
      _nameController.text = contact.displayName.trim();
      if (phone.isNotEmpty) {
        _phoneController.text = phone;
      }
    });
  }

  Future<Contact?> _showInAppContactPicker() async {
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    final selectable = contacts
        .where((c) => c.displayName.trim().isNotEmpty && c.phones.isNotEmpty)
        .toList();

    if (selectable.isEmpty) {
      throw Exception('Kontak tidak tersedia di perangkat.');
    }

    if (!mounted) return null;

    return showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.65,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pilih Kontak',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: selectable.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    itemBuilder: (context, index) {
                      final contact = selectable[index];
                      final phone =
                          _normalizePhone(contact.phones.first.number);

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFE7EE),
                          child: Icon(
                            Icons.person,
                            color: Color(0xFFE64060),
                          ),
                        ),
                        title: Text(
                          contact.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(phone),
                        onTap: () => Navigator.of(sheetContext).pop(contact),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _normalizePhone(String raw) {
    var value =
        raw.replaceAll(RegExp(r'[^0-9+]'), '').replaceAll(RegExp(r'^00'), '+');

    if (value.startsWith('+62')) {
      value = '0${value.substring(3)}';
    } else if (value.startsWith('62')) {
      value = '0${value.substring(2)}';
    }

    return value;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
