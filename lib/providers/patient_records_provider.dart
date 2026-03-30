import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final patientRecordsProvider =
    AsyncNotifierProvider<PatientRecordsNotifier, List<Map<String, dynamic>>>(
  () => PatientRecordsNotifier(),
);

class PatientRecordsNotifier
    extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentSession?.user;

    if (user == null) return [];

    // Step 1: Fetch raw prescriptions for this patient, newest first.
    final prescriptions = await supabase
        .from('prescriptions')
        .select('*')
        .eq('patient_id', user.id)
        .order('created_at', ascending: false);

    // Step 2: Sequentially resolve doctor names directly from users table
    // because doctor_id == users.id in this schema architecture.
    final enriched = <Map<String, dynamic>>[];
    for (final rx in prescriptions) {
      final docId = rx['doctor_id'];
      String doctorName = 'Unknown Doctor';

      if (docId != null) {
        final userRow = await supabase
            .from('users')
            .select('name')
            .eq('id', docId)
            .maybeSingle();
        if (userRow != null && userRow['name'] != null) {
          doctorName = userRow['name'] as String;
        }
      }

      enriched.add({...rx, 'doctor_name': doctorName});
    }

    return enriched;
  }
}
