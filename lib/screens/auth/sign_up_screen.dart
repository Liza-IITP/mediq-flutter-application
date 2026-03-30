import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clinics_provider.dart';

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
            const SnackBar(content: Text('Sign up successful! Please log in.')),
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

    return Scaffold(
      appBar: AppBar(title: Text('Sign Up as ${widget.role.displayName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || val.isEmpty || !val.contains('@') ? 'Please enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 16),
              if (widget.role == UserRole.clinicAdmin || widget.role == UserRole.pharmacyAdmin) ...[
                Text(widget.role == UserRole.clinicAdmin ? 'Clinic Details' : 'Pharmacy Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _clinicNameController,
                  decoration: InputDecoration(labelText: widget.role == UserRole.clinicAdmin ? 'Clinic Name' : 'Pharmacy Name', border: const OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clinicAddressController,
                  decoration: InputDecoration(labelText: widget.role == UserRole.clinicAdmin ? 'Clinic Address' : 'Pharmacy Address', border: const OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter address' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clinicPhoneController,
                  decoration: InputDecoration(labelText: widget.role == UserRole.clinicAdmin ? 'Clinic Phone' : 'Pharmacy Phone', border: const OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.isEmpty ? 'Please enter phone number' : null,
                ),
                const SizedBox(height: 16),
              ],
              if (widget.role == UserRole.doctor) ...[
                ref.watch(clinicsProvider).when(
                  data: (clinics) {
                    if (clinics.isEmpty) {
                      return const Text('No clinics available.');
                    }
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Select Clinic', border: OutlineInputBorder()),
                      initialValue: _selectedClinicId,
                      items: clinics.map((clinic) => DropdownMenuItem(
                        value: clinic.id,
                        child: Text(clinic.name),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedClinicId = val;
                        });
                      },
                      validator: (val) => val == null ? 'Please select a clinic' : null,
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, _) => Text('Error loading clinics: $err'),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sign Up', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
