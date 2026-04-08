import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  int _healthStatusIndex = 0;
  final int _healthStatusCount = 2;

  // Health status tabs data
  final List<Map<String, dynamic>> _healthStatusTabs = [
    {
      'metrics': [
        {
          'value': '120/80',
          'unit': 'mmHg',
          'label': 'Tekanan Darah',
          'status': 'Normal',
          'statusColor': Color(0xFF2D9744),
          'backgroundColor': Color(0xFFF6FFF8),
          'borderColor': Color(0xFFCDF3D5),
          'icon': FluentIcons.info_24_regular,
          'iconColor': Color(0xFF2D9744),
        },
        {
          'value': '72',
          'unit': 'BPM',
          'label': 'Detak Jantung',
          'status': 'Baik',
          'statusColor': Color(0xFF285DBE),
          'backgroundColor': Color(0xFFF5F8FF),
          'borderColor': Color(0xFFCBDCFE),
          'icon': FluentIcons.info_24_regular,
          'iconColor': Color(0xFF285DBE),
        },
      ],
    },
    {
      'metrics': [
        {
          'value': '118/78',
          'unit': 'mmHg',
          'label': 'Tekanan Darah',
          'status': 'Normal',
          'statusColor': Color(0xFF2D9744),
          'backgroundColor': Color(0xFFF6FFF8),
          'borderColor': Color(0xFFCDF3D5),
          'icon': FluentIcons.info_24_regular,
          'iconColor': Color(0xFF2D9744),
        },
        {
          'value': '68',
          'unit': 'BPM',
          'label': 'Detak Jantung',
          'status': 'Optimal',
          'statusColor': Color(0xFF2D9744),
          'backgroundColor': Color(0xFFF6FFF8),
          'borderColor': Color(0xFFCDF3D5),
          'icon': FluentIcons.info_24_regular,
          'iconColor': Color(0xFF2D9744),
        },
      ],
    },
  ];

  void _previousTab() {
    setState(() {
      _healthStatusIndex =
          (_healthStatusIndex - 1 + _healthStatusCount) % _healthStatusCount;
    });
  }

  void _nextTab() {
    setState(() {
      _healthStatusIndex = (_healthStatusIndex + 1) % _healthStatusCount;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // Swipe right (previous tab)
    if (details.primaryVelocity! > 0 && _healthStatusIndex > 0) {
      _previousTab();
    }
    // Swipe left (next tab)
    else if (details.primaryVelocity! < 0 &&
        _healthStatusIndex < _healthStatusCount - 1) {
      _nextTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120), // Space for bottom nav
        child: Stack(
          children: [
            // Red gradient background header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 264,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
                child: Container(
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
              ),
            ),

            // Scrollable content
            Column(
              children: [
                // App Bar / Header content
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, Jhoni',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Senin, 13 Oktober 2025',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(240, 70, 102, 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          FluentIcons.alert_24_regular,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Emergency Contact Card
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    context.push('/home/contacts');
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE64060),
                          Color(0xFFFF7E93),
                          Color(0xFFE64060)
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          offset: Offset(0, 10),
                          blurRadius: 23,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 59,
                          height: 59,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 244, 184, 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.call,
                            color: Color(0xFFFFF4B8),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kontak Darurat',
                                style: TextStyle(
                                  color: Color(0xFFFFF4B8),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Tekan untuk menghubungi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          FluentIcons.info_24_regular,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),

                // Health Status Carousel Placeholders
                const SizedBox(height: 24),
                GestureDetector(
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.03),
                          offset: Offset(0, 7),
                          blurRadius: 33.3,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Carousel Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                          240, 70, 102, 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.favorite,
                                      color: Color(0xFFE64060),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Status Kesehatan',
                                          style: TextStyle(
                                            color: Color(0xFF525252),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        // Text(
                                        //   _healthStatusTabs[_healthStatusIndex]
                                        //       ['title'],
                                        //   style: const TextStyle(
                                        //     color: Color(0xFF62748E),
                                        //     fontSize: 14,
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _healthStatusIndex == 0
                                      ? null
                                      : _previousTab,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _healthStatusIndex == 0
                                          ? const Color(0xFFE8EAED)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.arrow_back,
                                        color: _healthStatusIndex == 0
                                            ? const Color(0xFFBFBFBF)
                                            : const Color(0xFF525252),
                                        size: 20),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _healthStatusIndex ==
                                          _healthStatusCount - 1
                                      ? null
                                      : _nextTab,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _healthStatusIndex ==
                                              _healthStatusCount - 1
                                          ? const Color(0xFFE8EAED)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.arrow_forward,
                                        color: _healthStatusIndex ==
                                                _healthStatusCount - 1
                                            ? const Color(0xFFBFBFBF)
                                            : const Color(0xFF525252),
                                        size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Animated Health Metrics
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.3, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            key: ValueKey(_healthStatusIndex),
                            children: [
                              for (final metric
                                  in _healthStatusTabs[_healthStatusIndex]
                                      ['metrics'] as List)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: metric['backgroundColor'] as Color,
                                      border: Border.all(
                                          color:
                                              metric['borderColor'] as Color),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(metric['icon'] as IconData,
                                            color:
                                                metric['iconColor'] as Color),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${metric['value']} ${metric['unit']}',
                                                style: const TextStyle(
                                                    color: Color(0xFF525252),
                                                    fontSize: 18),
                                              ),
                                              Text(metric['label'] as String,
                                                  style: const TextStyle(
                                                      color: Color(0xFF62748E),
                                                      fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color:
                                                (metric['statusColor'] as Color)
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                              metric['status'] as String,
                                              style: TextStyle(
                                                  color: metric['statusColor']
                                                      as Color)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Dots indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_healthStatusCount, (index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: index == _healthStatusIndex ? 31 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == _healthStatusIndex
                                      ? const Color(0xFFE74665)
                                      : const Color(0xFFCAD5E2),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                // Menu Utama header
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Menu Utama',
                      style: TextStyle(
                        color: Color(0xFF525252),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Diari Kesehatan Full Width Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7E7),
                    border: Border.all(color: const Color(0xFFE64060)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 59,
                        height: 59,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE64060),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DIARI KESEHATAN',
                              style: TextStyle(
                                color: Color(0xFF525252),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '⭐ Catat semua kondisi harian Anda',
                              style: TextStyle(
                                color: Color(0xFFCD3754),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Half Width Buttons Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      // Edukasi Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 59,
                                height: 59,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F3FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  FluentIcons.book_open_24_regular,
                                  color: Color(0xFF6C2BD9),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 48),
                              const Text(
                                'Edukasi',
                                style: TextStyle(
                                  color: Color(0xFF525252),
                                  fontSize: 18,
                                ),
                              ),
                              const Text(
                                'Artikel Kesehatan',
                                style: TextStyle(
                                  color: Color(0xFF62748E),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Pengingat Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 59,
                                height: 59,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  FluentIcons.alert_24_regular,
                                  color: Color(0xFFE08B3D),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 48),
                              const Text(
                                'Pengingat',
                                style: TextStyle(
                                  color: Color(0xFF525252),
                                  fontSize: 18,
                                ),
                              ),
                              const Text(
                                'Obat & Jadwal',
                                style: TextStyle(
                                  color: Color(0xFF62748E),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
