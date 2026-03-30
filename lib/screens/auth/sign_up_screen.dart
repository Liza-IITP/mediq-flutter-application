import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clinics_provider.dart';
import '../../widgets/responsive_container.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  final UserRole role;

  const SignUpScreen({super.key, required this.role});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  String? _selectedClinicId;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (widget.role == UserRole.doctor && _selectedClinicId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a clinic.')),
        );
        return;
      }

      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: widget.role,
        clinicId: _selectedClinicId,
        entityName: _clinicNameController.text.trim(),
        entityAddress: _clinicAddressController.text.trim(),
        entityPhone: _clinicPhoneController.text.trim(),
      );

      if (!mounted) return;

      final authState = ref.read(authProvider);
      authState.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! Please log in.')),
          );
          context.pop();
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final isEntityRole = widget.role == UserRole.clinicAdmin ||
        widget.role == UserRole.pharmacyAdmin;
    final entityLabel =
        widget.role == UserRole.clinicAdmin ? 'Clinic' : 'Pharmacy';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Create Account',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Signing up as ${widget.role.displayName}',
                    style: const TextStyle(
                        fontSize: 15, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 32),

                  // ── Personal Details ─────────────────────────────────
                  _SectionHeader(label: 'Personal Details'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline)),
                    textCapitalization: TextCapitalization.words,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) =>
                        val == null || val.isEmpty || !val.contains('@')
                            ? 'Enter a valid email'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (val) => val == null || val.length < 6
                        ? 'Min 6 characters'
                        : null,
                  ),

                  // ── Entity Details (Clinic / Pharmacy Admin) ─────────
                  if (isEntityRole) ...[
                    const SizedBox(height: 28),
                    _SectionHeader(label: '$entityLabel Details'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clinicNameController,
                      decoration: InputDecoration(
                          labelText: '$entityLabel Name',
                          prefixIcon:
                              const Icon(Icons.business_outlined)),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _clinicAddressController,
                      decoration: InputDecoration(
                          labelText: '$entityLabel Address',
                          prefixIcon:
                              const Icon(Icons.location_on_outlined)),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _clinicPhoneController,
                      decoration: InputDecoration(
                          labelText: '$entityLabel Phone',
                          prefixIcon: const Icon(Icons.phone_outlined)),
                      keyboardType: TextInputType.phone,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ],

                  // ── Clinic Selection (Doctor) ─────────────────────────
                  if (widget.role == UserRole.doctor) ...[
                    const SizedBox(height: 28),
                    _SectionHeader(label: 'Select Your Clinic'),
                    const SizedBox(height: 12),
                    ref.watch(clinicsProvider).when(
                          data: (clinics) {
                            if (clinics.isEmpty) {
                              return const Text('No clinics available.',
                                  style:
                                      TextStyle(color: Color(0xFF64748B)));
                            }
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                  labelText: 'Clinic',
                                  prefixIcon: Icon(
                                      Icons.local_hospital_outlined)),
                              initialValue: _selectedClinicId,
                              items: clinics
                                  .map((c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name),
                                      ))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedClinicId = val),
                              validator: (val) =>
                                  val == null ? 'Select a clinic' : null,
                            );
                          },
                          loading: () => const Center(
                              child: CircularProgressIndicator()),
                          error: (err, _) =>
                              Text('Error: $err',
                                  style: const TextStyle(color: Colors.red)),
                        ),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Create Account',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Already have an account? Log in →'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F766E),
          letterSpacing: 0.5,
        ),
      );
}
