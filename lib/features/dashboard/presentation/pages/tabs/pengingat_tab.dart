import 'package:flutter/material.dart';

class PengingatTab extends StatelessWidget {
  const PengingatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Pengingat Tab',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 20),
          // Add Pengingat content here
        ],
      ),
    );
  }
}
