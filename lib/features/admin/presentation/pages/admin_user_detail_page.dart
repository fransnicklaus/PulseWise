import 'package:flutter/material.dart';

class AdminUserDetailPage extends StatelessWidget {
  const AdminUserDetailPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Admin user detail: $userId'),
      ),
    );
  }
}
