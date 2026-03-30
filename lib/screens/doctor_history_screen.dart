import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/doctor_history_provider.dart';

class DoctorHistoryScreen extends ConsumerWidget {
  const DoctorHistoryScreen({super.key});

  String _formatDate(String? raw) {
    if (raw == null) return 'N/A';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(doctorHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Prescription History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: historyState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No past prescriptions yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: records.length,
            itemBuilder: (context, i) => _HistoryCard(
              record: records[i],
              formatDate: _formatDate,
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final String Function(String?) formatDate;
  const _HistoryCard({required this.record, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final patientName = record['patient_name'] ?? 'Unknown Patient';
    final diagnosis = record['diagnosis'] ?? 'N/A';
    final symptoms = record['symptoms'] ?? 'N/A';
    final notes = record['notes'];
    final dateStr = formatDate(record['created_at'] as String?);

    final rawMeds = record['medicines'];
    List<String> medicines = [];
    if (rawMeds is List) {
      medicines = rawMeds.map((e) => e.toString()).toList();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.indigo.shade400],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.person, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(patientName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ]),
                Text(dateStr,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Diagnosis'),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Text(diagnosis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                _Label('Symptoms'),
                const SizedBox(height: 4),
                Text(symptoms, style: const TextStyle(fontSize: 14)),
                if (medicines.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Label('Prescribed Medicines'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: medicines
                        .map((med) => Chip(
                              avatar: const Icon(Icons.medication,
                                  size: 16, color: Colors.white),
                              label: Text(med,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13)),
                              backgroundColor: Colors.indigo.shade400,
                            ))
                        .toList(),
                  ),
                ],
                if (notes != null && notes.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Label("Notes"),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(notes.toString(),
                        style: const TextStyle(
                            fontStyle: FontStyle.italic, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 1.2),
      );
}
