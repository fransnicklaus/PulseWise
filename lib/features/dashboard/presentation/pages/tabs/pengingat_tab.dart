import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PengingatTab extends StatelessWidget {
  const PengingatTab({super.key});

  @override
  Widget build(BuildContext context) {
    const medications = [
      _MedicationItem(
        name: 'Panadol',
        detail: '300 ml • 3 times per day',
        icon: Icons.local_drink_rounded,
        iconColor: Color(0xFF7C3AED),
        iconBg: Color(0xFFEDE9FE),
      ),
      _MedicationItem(
        name: 'Amlodipine',
        detail: '2 capsules • 1 time per day',
        icon: Icons.medication_rounded,
        iconColor: Color(0xFFEAB308),
        iconBg: Color(0xFFFEF9C3),
      ),
      _MedicationItem(
        name: 'Allopurinol',
        detail: '1 pill • 3 times per day',
        icon: Icons.circle,
        iconColor: Color(0xFFEC4899),
        iconBg: Color(0xFFFCE7F3),
      ),
      _MedicationItem(
        name: 'Metformin',
        detail: '5 drops • 3 times per day',
        icon: Icons.water_drop,
        iconColor: Color(0xFFF97316),
        iconBg: Color(0xFFFFEDD5),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 14),
          ...List.generate(
            medications.length,
            (index) => _MedicationCard(
              item: medications[index],
              onTap: () => context.push('/home/reminder/detail/$index'),
            ),
          ),
          // _AddMedicationCard(
          //   onTap: () => context.push('/home/reminder/add'),
          // ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE64060), Color(0xFFFF6C86)],
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengingat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Medication list',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIcon(
            icon: Icons.add,
            onTap: () => context.push('/home/reminder/add'),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderIcon({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final _MedicationItem item;
  final VoidCallback onTap;

  const _MedicationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Color(0xFF0B1742),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.detail,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6B7280),
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class _AddMedicationCard extends StatelessWidget {
//   final VoidCallback onTap;

//   const _AddMedicationCard({required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(24),
//         child: Container(
//           padding: const EdgeInsets.all(18),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(color: const Color(0xFFE5E7EB)),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 56,
//                 height: 56,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border:
//                       Border.all(color: const Color(0xFF2F64D3), width: 2.5),
//                 ),
//                 child: const Icon(
//                   Icons.add,
//                   color: Color(0xFF2F64D3),
//                   size: 36,
//                 ),
//               ),
//               const SizedBox(width: 14),
//               const Text(
//                 'Add Medication halo',
//                 style: TextStyle(
//                   color: Color(0xFF2F64D3),
//                   fontSize: 24,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class _MedicationItem {
  final String name;
  final String detail;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _MedicationItem({
    required this.name,
    required this.detail,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}
