import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final pharmacyInventoryProvider = AsyncNotifierProvider<PharmacyInventoryNotifier, List<Map<String, dynamic>>>(() {
  return PharmacyInventoryNotifier();
});

class PharmacyInventoryNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentSession?.user;
    
    if (user == null) {
      throw Exception('Pharmacy Admin is not logged in.');
    }

    // 1. Fetch exact pharmacy boundaries sequentially.
    final pharmacyResponse = await supabase
        .from('pharmacies')
        .select('id')
        .eq('admin_id', user.id)
        .maybeSingle();

    if (pharmacyResponse == null || pharmacyResponse['id'] == null) {
      return []; 
    }

    final pharmacyId = pharmacyResponse['id'];

    // 2. Translate table mapping strictly alphabetic strings to arrays natively
    final inventoryResponse = await supabase
        .from('pharmacy_inventory')
        .select('*')
        .eq('pharmacy_id', pharmacyId)
        .order('medicine_name', ascending: true);

    return List<Map<String, dynamic>>.from(inventoryResponse);
  }

  Future<void> addMedicine({
    required String medicineName,
    required int quantity,
    required double price,
    required String usageInstructions,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentSession?.user;
      if (user == null) throw Exception('Auth error');

      final pharmacyResponse = await supabase
          .from('pharmacies')
          .select('id')
          .eq('admin_id', user.id)
          .maybeSingle();
          
      if (pharmacyResponse == null) throw Exception('Pharmacy boundaries lost.');

      // Safely serialize Dart numerics directly to Postgres payload formatting!
      await supabase.from('pharmacy_inventory').insert({
        'pharmacy_id': pharmacyResponse['id'],
        'medicine_name': medicineName,
        'quantity': quantity,
        'price': price,
        'usage_instructions': usageInstructions,
      });

      // Synchronously pop back fetching the mapped table anew natively
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to add medicine: $e');
    }
  }

  Future<void> deleteMedicine(String medicineId) async {
    try {
      await Supabase.instance.client
          .from('pharmacy_inventory')
          .delete()
          .eq('id', medicineId);
          
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to delete medicine: $e');
    }
  }
}
