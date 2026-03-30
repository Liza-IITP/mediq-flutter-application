import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_role.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Role')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Welcome to Mediq! How are you joining us?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: const [
                  _RoleCard(role: UserRole.patient, icon: Icons.person),
                  _RoleCard(role: UserRole.clinicAdmin, icon: Icons.local_hospital),
                  _RoleCard(role: UserRole.doctor, icon: Icons.medical_services),
                  _RoleCard(role: UserRole.pharmacyAdmin, icon: Icons.local_pharmacy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;

  const _RoleCard({required this.role, required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/login/${role.toDatabaseString}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(role.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
