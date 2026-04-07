import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic.dart';

final clinicsProvider = FutureProvider.autoDispose<List<Clinic>>((ref) async {
  final response = await Supabase.instance.client.from('clinics').select();
  return (response as List<dynamic>).map((e) => Clinic.fromJson(e as Map<String, dynamic>)).toList();
});
