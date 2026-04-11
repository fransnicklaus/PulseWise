import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../providers/emergency_contacts_provider.dart';

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
    await ref.read(emergencyContactsProvider.notifier).fetchInitial();
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

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(emergencyContactsProvider);

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
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: contactsState.items.length + 4,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildEmergencyCallCard();
            }

            if (index == 1) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text(
                  'Daftar Kontak Darurat',
                  style: TextStyle(
                    color: Color(0xFF525252),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                child: Container(
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

            final firstItemIndex = 2;
            final lastItemIndexExclusive =
                firstItemIndex + contactsState.items.length;

            if (index >= firstItemIndex && index < lastItemIndexExclusive) {
              final contact = contactsState.items[index - firstItemIndex];
              return _EmergencyContactCard(
                contact: contact,
                onCallPressed: () => _openDialer(contact.contactNumber),
              );
            }

            if (index == lastItemIndexExclusive) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF62748E),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => context.push('/home/contacts/add'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 8),
                      Text('Tambah Kontak'),
                    ],
                  ),
                ),
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
                            style: TextStyle(color: Color(0xFF64748B)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ambulans Darurat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Layanan 24 Jam',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
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
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCallPressed;

  const _EmergencyContactCard({
    required this.contact,
    required this.onCallPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPriority = contact.isPrioritas;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7E7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFFE64060),
                    size: 24,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        contact.contactNumber,
                        style: const TextStyle(
                          color: Color(0xFF62748E),
                          fontSize: 12,
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
                      'Prioritas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D9744),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onCallPressed,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'HUBUNGI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _selectedType = '';
  bool _isPrimaryContact = false;

  final List<Map<String, dynamic>> _contactTypes = [
    {'label': 'Keluarga', 'icon': Icons.favorite},
    {'label': 'Dokter', 'icon': Icons.medical_services_outlined},
    {'label': 'Rumah Sakit', 'icon': Icons.local_hospital_outlined},
    {'label': 'Lainnya', 'icon': Icons.person_outline},
  ];

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Field
            const Text(
              'Nama Lengkap',
              style: TextStyle(
                color: Color(0xFF525252),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama',
                hintStyle: const TextStyle(color: Color(0xFFBCBCBC)),
                prefixIcon:
                    const Icon(Icons.person_outline, color: Color(0xFF62748E)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFE64060), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Phone Field
            const Text(
              'Nomor Telepon',
              style: TextStyle(
                color: Color(0xFF525252),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: '+62 812-3456-7890',
                hintStyle: const TextStyle(color: Color(0xFFBCBCBC)),
                prefixIcon:
                    const Icon(Icons.phone_outlined, color: Color(0xFF62748E)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFE64060), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Contact Type Selection
            const Text(
              'Jenis Kontak',
              style: TextStyle(
                color: Color(0xFF525252),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: List.generate(4, (index) {
                final type = _contactTypes[index];
                final isSelected = _selectedType == type['label'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type['label']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE64060)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type['icon'],
                          color: isSelected
                              ? const Color(0xFFE64060)
                              : const Color(0xFF62748E),
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type['label'],
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFE64060)
                                : const Color(0xFF62748E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Primary Contact Checkbox
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _isPrimaryContact,
                    onChanged: (value) =>
                        setState(() => _isPrimaryContact = value ?? false),
                    activeColor: const Color(0xFFE64060),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadikan Kontak Utama',
                          style: TextStyle(
                            color: Color(0xFF525252),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Kontak utama akan ditampilkan di bagian paling atas dan mudah diakses',
                          style: TextStyle(
                            color: Color(0xFF62748E),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tips Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF285DBE),
                    size: 20,
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
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pastikan nomor telepon yang Anda masukkan benar dan dapat dihubungi sewaktu-waktu untuk keadaan darurat.',
                          style: TextStyle(
                            color: Color(0xFF285DBE),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE64060),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Simpan Kontak',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF525252),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
