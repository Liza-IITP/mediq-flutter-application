import 'package:flutter/material.dart';
import 'dart:async';
import '../medical_records_screen.dart';
import '../doctor_history_screen.dart';
import '../../widgets/responsive_container.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/admin_roster_provider.dart';
import '../../providers/clinic_settings_provider.dart';
import '../../providers/clinic_ledger_provider.dart';
import '../../providers/doctor_queue_provider.dart';
import '../../providers/patient_stream_provider.dart';
import '../../providers/patient_booking_provider.dart';
import '../../providers/medicine_search_provider.dart';
import '../../providers/pharmacy_inventory_provider.dart';

class PatientDashboard extends ConsumerWidget {
  const PatientDashboard({super.key});

  void _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.go('/role-selection');
  }

  void _openBookingForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BookingFormSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineSearchScreen()));
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => _openBookingForm(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Book New Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'My Active Appointment',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ref.watch(activeAppointmentStream).when(
              data: (appointments) {
                if (appointments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Text(
                        'You have no upcoming appointments.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    return _buildLiveTicketCard(context, ref, appointments[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error loading queue: $err')),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicalRecordsScreen()),
                );
              },
              icon: const Icon(Icons.history_edu_outlined),
              label: const Text(
                'My Medical Records',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.blue, width: 1.5),
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        ),   // ResponsiveContainer
      ),
    );
  }

  Widget _buildLiveTicketCard(BuildContext context, WidgetRef ref, Map<String, dynamic> appointment) {
    final docName = appointment['doctor_name'] ?? 'Unknown Doctor';
    final date = appointment['appointment_date'] ?? 'Unknown Date';
    final slot = appointment['slot']?.toString().toUpperCase() ?? 'N/A';
    final queueNum = appointment['queue_number']?.toString() ?? '--';
    final apptId = appointment['id'];
    final peopleAhead = appointment['people_ahead'] as int? ?? 0;
    final etaMinutes = peopleAhead * 15;
    final etaText = peopleAhead == 0
        ? '🎉 You are next!'
        : 'Estimated Wait: ~$etaMinutes mins';

    void handleCancel() async {
      try {
        await ref.read(patientBookingProvider).cancelAppointment(apptId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment cancelled.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade200, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: const Text(
              'LIVE TICKET',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.green,
            child: Text(
              '#$queueNum',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(docName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$date • $slot Shift', style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: peopleAhead == 0 ? Colors.green.shade100 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: peopleAhead == 0 ? Colors.green.shade400 : Colors.orange.shade300,
              ),
            ),
            child: Text(
              etaText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: peopleAhead == 0 ? Colors.green.shade800 : Colors.orange.shade900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: handleCancel,
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: const Text('Cancel Appointment', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _BookingFormSheet extends ConsumerStatefulWidget {
  const _BookingFormSheet();
  @override
  ConsumerState<_BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends ConsumerState<_BookingFormSheet> {
  String? _selectedClinicId;
  String? _selectedDoctorId;
  String _selectedSlot = 'morning';
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _clinics = [];
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoadingClinics = true;
  bool _isLoadingDoctors = false;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    try {
      final clinics = await ref.read(patientBookingProvider).fetchClinics();
      if (mounted) {
        setState(() {
          _clinics = clinics;
          _isLoadingClinics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingClinics = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load clinics: $e')));
      }
    }
  }

  Future<void> _loadDoctors(String clinicId) async {
    setState(() {
      _isLoadingDoctors = true;
      _selectedDoctorId = null; // Reset doctor explicitly securely
      _doctors = [];
    });

    try {
      final doctors = await ref.read(patientBookingProvider).fetchDoctorsByClinic(clinicId);
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoadingDoctors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDoctors = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load doctors: $e')));
      }
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedClinicId == null || _selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both a Clinic and a Doctor.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(patientBookingProvider).bookAppointment(
        clinicId: _selectedClinicId!,
        doctorId: _selectedDoctorId!,
        slot: _selectedSlot,
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss explicitly native routing
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment successfully booked!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Book Appointment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // 1. Clinic Dropdown
            _isLoadingClinics
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Clinic', border: OutlineInputBorder()),
                    initialValue: _selectedClinicId,
                    items: _clinics.map((clinic) {
                      return DropdownMenuItem<String>(
                        value: clinic['id'] as String,
                        child: Text(clinic['name'] as String),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null && val != _selectedClinicId) {
                        setState(() => _selectedClinicId = val);
                        _loadDoctors(val);
                      }
                    },
                  ),
            const SizedBox(height: 16),
            
            // 2. Doctor Dropdown
            _isLoadingDoctors
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Doctor', border: OutlineInputBorder()),
                    initialValue: _selectedDoctorId,
                    hint: Text(_selectedClinicId == null ? 'Select a clinic first' : 'Select Doctor'),
                    items: _doctors.map((doc) {
                      final userName = doc['users']?['name'] ?? 'Unknown Doctor';
                      return DropdownMenuItem<String>(
                        value: doc['id'] as String,
                        child: Text(userName),
                      );
                    }).toList(),
                    onChanged: _selectedClinicId == null 
                      ? null 
                      : (val) => setState(() => _selectedDoctorId = val),
                  ),
            const SizedBox(height: 24),

            // 3. Slot Selector (Morning / Evening)
            const Text('Select Shift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'morning', label: Text('Morning')),
                ButtonSegment(value: 'evening', label: Text('Evening')),
              ],
              selected: {_selectedSlot},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _selectedSlot = newSelection.first);
              },
            ),
            const SizedBox(height: 32),

            // 4. Submit Action
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitBooking,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}

class ClinicDashboard extends ConsumerStatefulWidget {
  const ClinicDashboard({super.key});

  @override
  ConsumerState<ClinicDashboard> createState() => _ClinicDashboardState();
}

class _ClinicDashboardState extends ConsumerState<ClinicDashboard> {
  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/role-selection');
  }

  @override
  Widget build(BuildContext context) {
    final rosterState = ref.watch(adminRosterProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Clinic Admin Dashboard'),
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending Approvals'),
              Tab(text: 'Doctor Roster'),
              Tab(text: 'Clinic Settings'),
              Tab(text: 'History Ledger'),
            ],
          ),
        ),
        body: rosterState.when(
          data: (doctors) {
            final pendingDocs = doctors.where((d) => d['status'] == 'pending').toList();
            final approvedDocs = doctors.where((d) => d['status'] == 'approved').toList();

            return TabBarView(
              children: [
                _buildRosterList(pendingDocs, isPending: true),
                _buildRosterList(approvedDocs, isPending: false),
                const _ClinicSettingsTab(),
                const _ClinicLedgerTab(),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRosterList(List<Map<String, dynamic>> doctors, {required bool isPending}) {
    if (doctors.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'No pending approvals.' : 'No doctors in roster.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        final doc = doctors[index];
        final userData = doc['users'] as Map<String, dynamic>?;
        final name = userData?['name'] ?? 'Unknown Name';
        final email = userData?['email'] ?? 'Unknown Email';
        final doctorId = doc['id'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(email),
            trailing: isPending
                ? ElevatedButton(
                    onPressed: () async {
                      try {
                        await ref.read(adminRosterProvider.notifier).approveDoctor(doctorId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Doctor approved successfully!')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to approve: $e')),
                        );
                      }
                    },
                    child: const Text('Approve'),
                  )
                : const Chip(
                    label: Text('Approved'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
          ),
        );
      },
    );
  }
}

class _ClinicSettingsTab extends ConsumerStatefulWidget {
  const _ClinicSettingsTab();

  @override
  ConsumerState<_ClinicSettingsTab> createState() => _ClinicSettingsTabState();
}

class _ClinicSettingsTabState extends ConsumerState<_ClinicSettingsTab> {
  TimeOfDay? _morningStart;
  TimeOfDay? _morningEnd;
  TimeOfDay? _eveningStart;
  TimeOfDay? _eveningEnd;
  bool _initialized = false;

  Future<void> _pickTime(BuildContext context, TimeOfDay? initial, Function(TimeOfDay) onSelected) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => onSelected(picked));
    }
  }

  void _save() async {
    if (_morningStart == null || _morningEnd == null || _eveningStart == null || _eveningEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select all shift timings')));
      return;
    }

    try {
      await ref.read(clinicSettingsProvider.notifier).saveSettings(
        morningStart: _morningStart!,
        morningEnd: _morningEnd!,
        eveningStart: _eveningStart!,
        eveningEnd: _eveningEnd!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(clinicSettingsProvider);

    return settingsState.when(
      data: (settings) {
        if (!_initialized) {
          if (settings != null) {
            final notifier = ref.read(clinicSettingsProvider.notifier);
            _morningStart = notifier.stringToTimeOfDay(settings['morning_start']);
            _morningEnd = notifier.stringToTimeOfDay(settings['morning_end']);
            _eveningStart = notifier.stringToTimeOfDay(settings['evening_start']);
            _eveningEnd = notifier.stringToTimeOfDay(settings['evening_end']);
          }
          _initialized = true;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Morning Shift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTimeRow('Start Time', _morningStart, (time) => _morningStart = time),
            _buildTimeRow('End Time', _morningEnd, (time) => _morningEnd = time),
            const Divider(height: 32),
            const Text('Evening Shift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTimeRow('Start Time', _eveningStart, (time) => _eveningStart = time),
            _buildTimeRow('End Time', _eveningEnd, (time) => _eveningEnd = time),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildTimeRow(String label, TimeOfDay? time, Function(TimeOfDay) onSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          TextButton.icon(
            onPressed: () => _pickTime(context, time, onSelected),
            icon: const Icon(Icons.access_time),
            label: Text(time?.format(context) ?? 'Select Time'),
          ),
        ],
      ),
    );
  }
}

// ── Clinic History Ledger Tab ─────────────────────────────────────────────────

class _ClinicLedgerTab extends ConsumerWidget {
  const _ClinicLedgerTab();

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
    final ledgerState = ref.watch(clinicLedgerProvider);

    return ledgerState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
      data: (appointments) {
        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 72, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'No completed appointments yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appt = appointments[index];
            final patientName = appt['patient_name'] ?? 'Unknown';
            final doctorName = appt['doctor_name'] ?? 'Unknown';
            final date = _formatDate(appt['appointment_date'] as String?);
            final slot = (appt['slot'] as String?)?.toUpperCase() ?? 'N/A';
            final queueNum = appt['queue_number']?.toString() ?? '--';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Text('#$queueNum',
                      style: TextStyle(
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                title: Text(patientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Dr. $doctorName',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('$date  •  $slot Shift',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text('Completed',
                      style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PharmacyDashboard extends ConsumerWidget {
  const PharmacyDashboard({super.key});

  void _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.go('/role-selection');
  }

  void _showAddMedicineSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddMedicineFormSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryState = ref.watch(pharmacyInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Inventory'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicineSheet(context),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: inventoryState.when(
        data: (inventory) {
          if (inventory.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Your store inventory is empty.\nTap the + button to add medicines natively.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80), // Padding offset dynamically clearing the FAB constraints
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final item = inventory[index];
              final id = item['id'];
              final name = item['medicine_name'] ?? 'Unknown';
              final price = item['price'] ?? 0;
              final qty = item['quantity'] ?? 0;
              
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.medication, color: Colors.white),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Price: \$$price   •   In Stock: $qty'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      try {
                        await ref.read(pharmacyInventoryProvider.notifier).deleteMedicine(id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine removed.')));
                        }
                      } catch (e) {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                         }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading inventory: $err')),
      ),
    );
  }
}

class _AddMedicineFormSheet extends ConsumerStatefulWidget {
  const _AddMedicineFormSheet();
  @override
  ConsumerState<_AddMedicineFormSheet> createState() => _AddMedicineFormSheetState();
}

class _AddMedicineFormSheetState extends ConsumerState<_AddMedicineFormSheet> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameCtrl.text.trim();
    final qtyText = _qtyCtrl.text.trim();
    final priceText = _priceCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    if (name.isEmpty || qtyText.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
      return;
    }

    // Explictly cast string forms bounding down cleanly onto int/double primitives avoiding exception errors natively.
    final int? quantity = int.tryParse(qtyText);
    final double? price = double.tryParse(priceText);

    if (quantity == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid numerical figures for price and quantity.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(pharmacyInventoryProvider.notifier).addMedicine(
        medicineName: name,
        quantity: quantity,
        price: price,
        usageInstructions: notes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine added securely to pharmacy inventory!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insertion Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Draggable wraps safely padding keyboard views without clipping bottom context!
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: controller,
            children: [
              const Text('Add to Inventory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Medicine Name (*)', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      decoration: const InputDecoration(labelText: 'Stock Qty (*)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: 'Price \$ (*)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Usage / Notes', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add to Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class DoctorDashboard extends ConsumerWidget {
  const DoctorDashboard({super.key});

  void _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.go('/role-selection');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(doctorQueueProvider);
    final selectedSlot = ref.watch(selectedSlotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu),
            tooltip: 'Prescription History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctorHistoryScreen()),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToggle(ref, selectedSlot),
          Expanded(
            child: queueState.when(
              data: (appointments) {
                if (appointments.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No appointments scheduled for this slot yet.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final currentPatient = appointments.first;
                final upNext = appointments.skip(1).toList();

                return Column(
                  children: [
                    _buildCurrentPatientCard(context, ref, currentPatient),
                    const Divider(height: 32),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Up Next',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _buildUpNextList(upNext)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error loading queue: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(WidgetRef ref, String currentSlot) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'morning', label: Text('Morning Shift')),
          ButtonSegment(value: 'evening', label: Text('Evening Shift')),
        ],
        selected: {currentSlot},
        onSelectionChanged: (Set<String> newSelection) {
          ref.read(selectedSlotProvider.notifier).updateSlot(newSelection.first);
        },
      ),
    );
  }

  Widget _buildCurrentPatientCard(BuildContext context, WidgetRef ref, Map<String, dynamic> appointment) {
    final patientName = appointment['patient']?['name'] ?? 'Unknown Patient';
    final queueNumber = appointment['queue_number']?.toString() ?? '--';
    final appointmentId = appointment['id'];

    void handleSlidePatient() async {
      try {
        await ref.read(doctorQueueProvider.notifier).slidePatient(appointmentId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient slid to bottom of queue.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sliding patient: $e')));
        }
      }
    }

    void handleStartCheckup() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _PrescriptionFormSheet(appointment: appointment),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'CURRENT PATIENT',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.blue,
            child: Text(
              '#$queueNumber',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            patientName,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: handleSlidePatient,
                icon: const Icon(Icons.arrow_downward),
                label: const Text('Slide Patient'),
              ),
              ElevatedButton.icon(
                onPressed: handleStartCheckup,
                icon: const Icon(Icons.medical_services),
                label: const Text('Start Check-up'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildUpNextList(List<Map<String, dynamic>> upNext) {
    if (upNext.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Queue is empty.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: upNext.length,
      itemBuilder: (context, index) {
        final appointment = upNext[index];
        final patientName = appointment['patient']?['name'] ?? 'Unknown Patient';
        final queueNumber = appointment['queue_number']?.toString() ?? '--';

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text('#$queueNumber', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
            ),
            title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Pending Approval')), body: const Center(child: Text('Your account is pending clinic approval.')));
}

class MedicineSearchScreen extends ConsumerStatefulWidget {
  const MedicineSearchScreen({super.key});
  @override
  ConsumerState<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends ConsumerState<MedicineSearchScreen> {
  Timer? _debounce;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    // Native 500ms wrapper stalling HTTP payload execution preventing spam
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(medicineSearchProvider.notifier).searchMedicine(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(medicineSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Medicine Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search for medicines...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearchChanged('');
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: searchState.when(
              data: (results) {
                if (results.isEmpty && _searchCtrl.text.trim().isNotEmpty) {
                  return const Center(child: Text('No matching medicines in stock globally.', style: TextStyle(color: Colors.grey, fontSize: 16)));
                } else if (results.isEmpty) {
                  return const Center(child: Text('Start typing to search global pharmacies.', style: TextStyle(color: Colors.grey, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    final pharmacyData = item['pharmacies'];
                    final storeName = pharmacyData?['name'] ?? 'Unknown Pharmacy';
                    final storeAddress = pharmacyData?['address'] ?? '';
                    final storePhone = pharmacyData?['phone'] ?? '';

                    final medicineName = item['medicine_name'] ?? 'Unknown';
                    final price = item['price'] ?? 0;
                    final qty = item['quantity'] ?? 0;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(medicineName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                                Text(
                                  '\$$price',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('$qty left in stock!', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                            const Divider(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.storefront, color: Colors.blue.shade700, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(storeName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                        if (storeAddress.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(storeAddress, style: TextStyle(color: Colors.blue.shade800, fontSize: 12)),
                                        ],
                                        if (storePhone.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text('📞 $storePhone', style: TextStyle(color: Colors.blue.shade800, fontSize: 12)),
                                        ]
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Search failed: $err')),
            ),
          )
        ],
      ),
    );
  }
}

class _PrescriptionFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> appointment;
  const _PrescriptionFormSheet({required this.appointment});

  @override
  ConsumerState<_PrescriptionFormSheet> createState() => _PrescriptionFormSheetState();
}

class _PrescriptionFormSheetState extends ConsumerState<_PrescriptionFormSheet> {
  final _symptomsCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<TextEditingController> _medicineControllers = [TextEditingController()];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    for (var c in _medicineControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() async {
    final symptoms = _symptomsCtrl.text.trim();
    final diagnosis = _diagnosisCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final medicines = _medicineControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (symptoms.isEmpty || diagnosis.isEmpty || medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Symptoms, Diagnosis, and at least one Medicine are required.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(doctorQueueProvider.notifier).completeCheckup(
        appointmentId: widget.appointment['id'],
        patientId: widget.appointment['patient_id'],
        doctorId: widget.appointment['doctor_id'],
        symptoms: symptoms,
        diagnosis: diagnosis,
        medicines: medicines,
        notes: notes,
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-up marked completed and prescription saved!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Draggable scrolls the bottom sheet cleanly behind the keyboard natively
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: controller,
            children: [
              const Text('Check-up Form', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _symptomsCtrl,
                decoration: const InputDecoration(labelText: 'Symptoms (*)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diagnosisCtrl,
                decoration: const InputDecoration(labelText: 'Diagnosis (*)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              const Text('Medicines (*)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(_medicineControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _medicineControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Medicine ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          if (_medicineControllers.length > 1) {
                            setState(() {
                              _medicineControllers[index].dispose();
                              _medicineControllers.removeAt(index);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _medicineControllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Medicine'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mark Done & Send', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        );
      },
    );
  }
}
