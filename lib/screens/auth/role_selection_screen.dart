import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_role.dart';
import '../../widgets/responsive_container.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Logo / Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.local_hospital, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Mediq',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'How are you joining us today?',
                style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: const [
                    _RoleCard(
                      role: UserRole.patient,
                      icon: Icons.person_outline,
                      color: Color(0xFF0F766E),
                      bgColor: Color(0xFFCCFBF1),
                    ),
                    _RoleCard(
                      role: UserRole.clinicAdmin,
                      icon: Icons.local_hospital_outlined,
                      color: Color(0xFF1D4ED8),
                      bgColor: Color(0xFFDBEAFE),
                    ),
                    _RoleCard(
                      role: UserRole.doctor,
                      icon: Icons.medical_services_outlined,
                      color: Color(0xFF7C3AED),
                      bgColor: Color(0xFFEDE9FE),
                    ),
                    _RoleCard(
                      role: UserRole.pharmacyAdmin,
                      icon: Icons.local_pharmacy_outlined,
                      color: Color(0xFFB45309),
                      bgColor: Color(0xFFFEF3C7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.15),
      child: InkWell(
        onTap: () => context.push('/login/${role.toDatabaseString}'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                role.displayName,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
