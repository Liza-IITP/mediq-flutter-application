import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provides the currently selected shift. By default, before 14:00 (2:00 PM) is Morning.
final selectedSlotProvider = NotifierProvider<SelectedSlotNotifier, String>(() {
  return SelectedSlotNotifier();
});

class SelectedSlotNotifier extends Notifier<String> {
  @override
  String build() {
    final currentHour = DateTime.now().hour;
    return currentHour < 14 ? 'morning' : 'evening';
  }

  void updateSlot(String newSlot) {
    state = newSlot;
  }
}

final doctorQueueProvider = AsyncNotifierProvider<DoctorQueueNotifier, List<Map<String, dynamic>>>(() {
  return DoctorQueueNotifier();
});

class DoctorQueueNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentSession?.user;
    
    if (user == null) {
      throw Exception('Doctor is not currently logged in.');
    }

    // Riverpod natively watches this slot provider and recalculates seamlessly whenever it flips!
    final currentSlot = ref.watch(selectedSlotProvider);

    // Format today's date safely natively into SQL YYYY-MM-DD
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final response = await supabase
        .from('appointments')
        .select('*, patient:users(name)')
        .eq('doctor_id', user.id)
        .eq('appointment_date', todayStr)
        .eq('slot', currentSlot)
        .eq('status', 'scheduled')
        .order('queue_number', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> slidePatient(String appointmentId) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentSession?.user;
      
      if (user == null) {
        throw Exception('Doctor is not logged in.');
      }

      final currentSlot = ref.read(selectedSlotProvider);
      
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 1. Find the current MAX queue_number for today's slot
      final maxResponse = await supabase
          .from('appointments')
          .select('queue_number')
          .eq('doctor_id', user.id)
          .eq('appointment_date', todayStr)
          .eq('slot', currentSlot)
          .eq('status', 'scheduled')
          .order('queue_number', ascending: false)
          .limit(1)
          .maybeSingle();

      int nextQueueNumber = 1;
      if (maxResponse != null && maxResponse['queue_number'] != null) {
        nextQueueNumber = (maxResponse['queue_number'] as int) + 1;
      }

      // 2. Update the target appointment with the new highest queue number
      await supabase
          .from('appointments')
          .update({'queue_number': nextQueueNumber})
          .eq('id', appointmentId);

      // Successfully updated, refresh the queue
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to slide patient: $e');
    }
  }

  Future<void> completeCheckup({
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required String symptoms,
    required String diagnosis,
    required List<String> medicines,
    required String notes,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Insert into prescriptions table
      await supabase.from('prescriptions').insert({
        'appointment_id': appointmentId,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'symptoms': symptoms,
        'diagnosis': diagnosis,
        'medicines': medicines, // Supabase automatically converts Dart List natively mapping strings to JSONB arrays
        'notes': notes,
      });

      // 2. Update appointments table queue status to completed
      await supabase
          .from('appointments')
          .update({'status': 'completed'})
          .eq('id', appointmentId);

      // Cleanly remove from active memory
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to complete checkup: $e');
    }
  }
}
