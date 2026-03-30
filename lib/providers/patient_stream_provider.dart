import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final activeAppointmentStream = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentSession?.user;

  if (user == null) {
    return const Stream.empty();
  }

  // 1. Establish the socket mapped precisely mapping the specific boundaries structurally
  final stream = supabase
      .from('appointments')
      .stream(primaryKey: ['id'])
      .eq('patient_id', user.id)
      .order('appointment_date')
      .order('queue_number');

  // 2. Intercept the Socket packet mapping the missing relational IDs sequentially natively
  return stream.asyncMap((appointments) async {
    final List<Map<String, dynamic>> enrichedAppointments = [];

    for (var appt in appointments) {
      if (appt['status'] != 'scheduled') continue;
      final docId = appt['doctor_id'];
      String doctorName = 'Unknown Doctor';

      if (docId != null) {
        // We can query the 'users' table natively where ID matches the doctor's bound ID.
        final userResponse = await supabase
            .from('users')
            .select('name')
            .eq('id', docId)
            .maybeSingle();

        if (userResponse != null && userResponse['name'] != null) {
          doctorName = userResponse['name'];
        }
      }

      // 3. Clone array forcing custom JSON injections
      final enrichedAppt = Map<String, dynamic>.from(appt);
      enrichedAppt['doctor_name'] = doctorName;
      enrichedAppointments.add(enrichedAppt);
    }

    return enrichedAppointments;
  });
});
