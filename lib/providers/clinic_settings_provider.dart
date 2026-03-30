import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final clinicSettingsProvider = AsyncNotifierProvider<ClinicSettingsNotifier, Map<String, dynamic>?>(() {
  return ClinicSettingsNotifier();
});

class ClinicSettingsNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  
  // Helper: TimeOfDay to HH:MM:SS string for Supabase PostgreSQL TIME column
  String timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  // Helper: HH:MM:SS string to TimeOfDay for Flutter UI
  TimeOfDay? stringToTimeOfDay(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
  }

  @override
  FutureOr<Map<String, dynamic>?> build() async {
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

    // 2. Fetch all configuration for this clinic
    final response = await supabase
        .from('clinic_settings')
        .select()
        .eq('clinic_id', clinicId)
        .maybeSingle();

    return response;
  }

  Future<void> saveSettings({
    required TimeOfDay morningStart,
    required TimeOfDay morningEnd,
    required TimeOfDay eveningStart,
    required TimeOfDay eveningEnd,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentSession?.user;
    
    if (user == null) {
      throw Exception('Admin is not currently logged in.');
    }
    
    try {
      final clinicData = await supabase
          .from('clinics')
          .select('id')
          .eq('admin_id', user.id)
          .maybeSingle();

      if (clinicData == null) {
        throw Exception('No clinic found to attach settings to.');
      }

      final String clinicId = clinicData['id'] as String;

      await supabase.from('clinic_settings').upsert({
        'clinic_id': clinicId,
        'morning_start': timeOfDayToString(morningStart),
        'morning_end': timeOfDayToString(morningEnd),
        'evening_start': timeOfDayToString(eveningStart),
        'evening_end': timeOfDayToString(eveningEnd),
      });

      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }
}
