import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final patientBookingProvider = Provider<PatientBookingService>((ref) {
  return PatientBookingService();
});

class PatientBookingService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchClinics() async {
    final response = await _supabase.from('clinics').select('id, name, address');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchDoctorsByClinic(String clinicId) async {
    // Exclusively pull approved doctors tied to clinic natively embedding users relational arrays.
    final response = await _supabase
        .from('doctors')
        .select('*, users!inner(name)')
        .eq('clinic_id', clinicId)
        .eq('status', 'approved');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> bookAppointment({
    required String clinicId,
    required String doctorId,
    required String slot,
  }) async {
    final user = _supabase.auth.currentSession?.user;
    if (user == null) {
      throw Exception('Patient is not logged in.');
    }

    // Format local bounding explicitly avoiding native UTC overlaps
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      // 1. Math block scanning queue limits descending restricting boundaries mathematically safely.
      final maxQueueResponse = await _supabase
          .from('appointments')
          .select('queue_number')
          .eq('doctor_id', doctorId)
          .eq('appointment_date', todayStr)
          .eq('slot', slot)
          .order('queue_number', ascending: false)
          .limit(1)
          .maybeSingle();

      int newQueueNumber = 1; 
      if (maxQueueResponse != null && maxQueueResponse['queue_number'] != null) {
        newQueueNumber = (maxQueueResponse['queue_number'] as int) + 1;
      }

      // 2. Insert the appointment securely binding status identically natively
      await _supabase.from('appointments').insert({
        'patient_id': user.id,
        'doctor_id': doctorId,
        'clinic_id': clinicId,
        'appointment_date': todayStr,
        'slot': slot,
        'queue_number': newQueueNumber,
        'status': 'scheduled',
      });
    } catch (e) {
      throw Exception('Failed to book appointment: $e');
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId);
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }
}
