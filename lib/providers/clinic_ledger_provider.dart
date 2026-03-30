import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final clinicLedgerProvider =
    AsyncNotifierProvider<ClinicLedgerNotifier, List<Map<String, dynamic>>>(
  () => ClinicLedgerNotifier(),
);

class ClinicLedgerNotifier
    extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentSession?.user;

    if (user == null) return [];

    // Step 1: Resolve this admin's clinic_id.
    final clinicRow = await supabase
        .from('clinics')
        .select('id')
        .eq('admin_id', user.id)
        .maybeSingle();

    if (clinicRow == null) return [];
    final clinicId = clinicRow['id'] as String;

    // Step 2: Fetch all completed appointments for this clinic.
    final appointments = await supabase
        .from('appointments')
        .select('*')
        .eq('clinic_id', clinicId)
        .eq('status', 'completed')
        .order('appointment_date', ascending: false)
        .order('queue_number', ascending: true);

    // Step 3: Resolve patient and doctor names from users table.
    final enriched = <Map<String, dynamic>>[];
    final nameCache = <String, String>{};

    Future<String> resolveName(String? id) async {
      if (id == null) return 'Unknown';
      if (nameCache.containsKey(id)) return nameCache[id]!;
      final row = await supabase
          .from('users')
          .select('name')
          .eq('id', id)
          .maybeSingle();
      final name = (row?['name'] as String?) ?? 'Unknown';
      nameCache[id] = name;
      return name;
    }

    for (final appt in appointments) {
      final patientName = await resolveName(appt['patient_id'] as String?);
      final doctorName = await resolveName(appt['doctor_id'] as String?);
      enriched.add({
        ...appt,
        'patient_name': patientName,
        'doctor_name': doctorName,
      });
    }

    return enriched;
  }
}
