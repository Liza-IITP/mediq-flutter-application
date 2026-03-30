enum UserRole {
  patient,
  clinicAdmin,
  doctor,
  pharmacyAdmin;

  String get toDatabaseString {
    switch (this) {
      case UserRole.patient:
        return 'patient';
      case UserRole.clinicAdmin:
        return 'clinic_admin';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.pharmacyAdmin:
        return 'pharmacy_admin';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.clinicAdmin:
        return 'Clinic Admin';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.pharmacyAdmin:
        return 'Pharmacy';
    }
  }
}
