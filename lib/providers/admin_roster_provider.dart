import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminRosterProvider = AsyncNotifierProvider<AdminRosterNotifier, List<Map<String, dynamic>>>(() {
  return AdminRosterNotifier();
});

class AdminRosterNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentSession?.user;
    
    if (user == null) {
      throw Exception('Admin is not currently logged in.');
    }

    // 1. Fetch clinic for this admin
    final clinicData = await supabase
        .from('clinics')
        .select('id')
        .eq('admin_id', user.id)
        .maybeSingle();

    if (clinicData == null) {
      throw Exception('No clinic found for your account. Please contact support.');
    }

    final clinicId = clinicData['id'] as String;

    // 2. Fetch all doctors for this clinic, joined with users table
    // Ensure that id UUID REFERENCES users(id) is established natively on Supabase
    final response = await supabase
        .from('doctors')
        .select('*, users(name, email)')
        .eq('clinic_id', clinicId);

    // Convert to list of typed maps
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> approveDoctor(String doctorId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('doctors')
          .update({'status': 'approved'})
          .eq('id', doctorId);

      // Successfully updated on the database, now refresh local state
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to approve doctor: $e');
    }
  }
}
