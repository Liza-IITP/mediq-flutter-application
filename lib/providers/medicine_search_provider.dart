import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final medicineSearchProvider = AsyncNotifierProvider<MedicineSearchNotifier, List<Map<String, dynamic>>>(() {
  return MedicineSearchNotifier();
});

class MedicineSearchNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() {
    // Starts implicitly explicitly bounding empty lists natively ready for active searches
    return [];
  }

  Future<void> searchMedicine(String query) async {
    // Instantly trap empty clears cleanly removing caches natively stopping HTTP overlaps.
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final supabase = Supabase.instance.client;
      
      // Execute PostgREST parsing 'ilike' matching explicitly linking generic dependencies securely 
      final response = await supabase
          .from('pharmacy_inventory')
          .select('*, pharmacies(name, address, phone)')
          .ilike('medicine_name', '%$query%')
          .gt('quantity', 0) // Only fetch positive inventory boundaries
          .order('price', ascending: true);

      state = AsyncValue.data(List<Map<String, dynamic>>.from(response));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
