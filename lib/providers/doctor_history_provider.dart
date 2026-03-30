import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final doctorHistoryProvider =
    AsyncNotifierProvider<DoctorHistoryNotifier, List<Map<String, dynamic>>>(
  () => DoctorHistoryNotifier(),
);

class DoctorHistoryNotifier
    extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentSession?.user;

    if (user == null) return [];

    // Fetch all prescriptions written by this doctor, newest first.
    final prescriptions = await supabase
        .from('prescriptions')
        .select('*')
        .eq('doctor_id', user.id)
        .order('created_at', ascending: false);

    // Resolve each patient's name directly from users table (patient_id == users.id).
    final enriched = <Map<String, dynamic>>[];
    for (final rx in prescriptions) {
      final patientId = rx['patient_id'];
      String patientName = 'Unknown Patient';

      if (patientId != null) {
        final row = await supabase
            .from('users')
            .select('name')
            .eq('id', patientId)
            .maybeSingle();
        if (row != null && row['name'] != null) {
          patientName = row['name'] as String;
        }
      }

      enriched.add({...rx, 'patient_name': patientName});
    }

    return enriched;
  }
}
