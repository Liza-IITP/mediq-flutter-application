import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_role.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // initial state
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? clinicId,
    String? entityName,
    String? entityAddress,
    String? entityPhone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final supabase = Supabase.instance.client;
      
      // 1. Create the user in auth.users
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('User creation failed: No user returned.');
      }

      // 2. Insert profile data into public.users table
      await supabase.from('users').insert({
        'id': user.id,
        'role': role.toDatabaseString,
        'name': name,
        'email': email,
      });

      // 3. Insert into doctors table if role is doctor
      if (role == UserRole.doctor) {
        if (clinicId == null || clinicId.isEmpty) {
          throw Exception('Clinic must be selected for Doctor role.');
        }
        await supabase.from('doctors').insert({
          'id': user.id,
          'clinic_id': clinicId,
          'status': 'pending',
        });
      }

      // 4. Insert into clinics table if role is clinicAdmin
      if (role == UserRole.clinicAdmin) {
        if (entityName == null || entityName.isEmpty ||
            entityAddress == null || entityAddress.isEmpty ||
            entityPhone == null || entityPhone.isEmpty) {
          throw Exception('Clinic details are required for Clinic Admin role.');
        }
        await supabase.from('clinics').insert({
          'admin_id': user.id,
          'name': entityName,
          'address': entityAddress,
          'phone': entityPhone,
        });
      }

      // 5. Insert into pharmacies table if role is pharmacyAdmin
      if (role == UserRole.pharmacyAdmin) {
        if (entityName == null || entityName.isEmpty ||
            entityAddress == null || entityAddress.isEmpty ||
            entityPhone == null || entityPhone.isEmpty) {
          throw Exception('Pharmacy details are required for Pharmacy Admin role.');
        }
        await supabase.from('pharmacies').insert({
          'admin_id': user.id,
          'name': entityName,
          'address': entityAddress,
          'phone': entityPhone,
        });
      }

      // Automatically sign out immediately after creating to force user through the true Login flow
      await supabase.auth.signOut();
    });
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.signInWithPassword(email: email, password: password);
      final user = response.user;
      
      if (user == null) {
        throw Exception('Login failed: user missing');
      }

      // Check users table to determine the user's REAL role (bypassing whatever they clicked first)
      final userData = await supabase.from('users').select('role').eq('id', user.id).single();
      final String roleStr = userData['role'] as String;

      String targetRoute = '/patient-dashboard';

      if (roleStr == 'patient') {
        targetRoute = '/patient-dashboard';
      } else if (roleStr == 'clinic_admin') {
        targetRoute = '/clinic-dashboard';
      } else if (roleStr == 'pharmacy_admin') {
        targetRoute = '/pharmacy-dashboard';
      } else if (roleStr == 'doctor') {
        // Run secondary query for Doctors to check for approval
        final docData = await supabase.from('doctors').select('status').eq('id', user.id).maybeSingle();
        final String docStatus = docData?['status'] as String? ?? 'pending';

        if (docStatus == 'approved') {
          targetRoute = '/doctor-dashboard';
        } else {
          targetRoute = '/pending-approval';
        }
      }

      state = const AsyncData(null);
      return targetRoute;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
