import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/patient_records_provider.dart';

class MedicalRecordsScreen extends ConsumerWidget {
  const MedicalRecordsScreen({super.key});

  String _formatDate(String? rawDate) {
    if (rawDate == null) return 'Unknown Date';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsState = ref.watch(patientRecordsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('My Medical Records'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: recordsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Failed to load records: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_information_outlined,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'You have no past medical records.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return _PrescriptionCard(
                record: records[index],
                formatDate: _formatDate,
              );
            },
          );
        },
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final String Function(String?) formatDate;

  const _PrescriptionCard({required this.record, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final doctorName = record['doctor_name'] ?? 'Unknown Doctor';
    final diagnosis = record['diagnosis'] ?? 'N/A';
    final symptoms = record['symptoms'] ?? 'N/A';
    final notes = record['notes'];
    final dateStr = formatDate(record['created_at'] as String?);

    // Safely parse JSONB medicines array
    final rawMeds = record['medicines'];
    List<String> medicines = [];
    if (rawMeds is List) {
      medicines = rawMeds.map((e) => e.toString()).toList();
    } else if (rawMeds is String && rawMeds.isNotEmpty) {
      medicines = [rawMeds];
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
          // ── Header band ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade400],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Dr. $doctorName',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Diagnosis
                _SectionLabel(label: 'Diagnosis'),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    diagnosis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 12),

                // Symptoms
                _SectionLabel(label: 'Symptoms'),
                const SizedBox(height: 4),
                Text(symptoms,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black87)),

                // Medicines (Chips)
                if (medicines.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionLabel(label: 'Prescribed Medicines'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: medicines
                        .map(
                          (med) => Chip(
                            avatar: const Icon(Icons.medication,
                                size: 16, color: Colors.white),
                            label: Text(med,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            backgroundColor: Colors.teal.shade400,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        )
                        .toList(),
                  ),
                ],

                // Notes (optional)
                if (notes != null &&
                    notes.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionLabel(label: 'Doctor\'s Notes'),
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
                            fontSize: 13,
                            color: Colors.black87,
                            fontStyle: FontStyle.italic)),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2),
    );
  }
}
