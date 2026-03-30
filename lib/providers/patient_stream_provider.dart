import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final activeAppointmentStream = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentSession?.user;

  if (user == null) {
    return const Stream.empty();
  }

  final stream = supabase
      .from('appointments')
      .stream(primaryKey: ['id'])
      .eq('patient_id', user.id)
      .order('appointment_date')
      .order('queue_number');

  return stream.asyncMap((appointments) async {
    final List<Map<String, dynamic>> enrichedAppointments = [];

    for (var appt in appointments) {
      if (appt['status'] != 'scheduled') continue;

      final docId = appt['doctor_id'];
      final myQueueNum = appt['queue_number'] as int? ?? 0;
      final apptDate = appt['appointment_date'] as String?;
      final slot = appt['slot'] as String?;
      String doctorName = 'Unknown Doctor';

      // Resolve doctor name
      if (docId != null) {
        final userResponse = await supabase
            .from('users')
            .select('name')
            .eq('id', docId)
            .maybeSingle();

        if (userResponse != null && userResponse['name'] != null) {
          doctorName = userResponse['name'] as String;
        }
      }

      // ETA: count how many 'scheduled' appointments for the same
      // doctor / date / slot have a queue_number strictly less than mine.
      int peopleAhead = 0;
      if (docId != null && apptDate != null && slot != null) {
        final aheadResponse = await supabase
            .from('appointments')
            .select('id')
            .eq('doctor_id', docId)
            .eq('appointment_date', apptDate)
            .eq('slot', slot)
            .eq('status', 'scheduled')
            .lt('queue_number', myQueueNum);

        peopleAhead = (aheadResponse as List).length;
      }

      final enrichedAppt = Map<String, dynamic>.from(appt);
      enrichedAppt['doctor_name'] = doctorName;
      enrichedAppt['people_ahead'] = peopleAhead;
      enrichedAppointments.add(enrichedAppt);
    }

    return enrichedAppointments;
  });
});
