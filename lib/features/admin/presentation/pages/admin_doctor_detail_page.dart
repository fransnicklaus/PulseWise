import 'package:flutter/material.dart';

class AdminDoctorDetailPage extends StatelessWidget {
  const AdminDoctorDetailPage({
    super.key,
    required this.doctorId,
  });

  final String doctorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Admin doctor detail: $doctorId'),
      ),
    );
  }
}
