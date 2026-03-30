import 'package:go_router/go_router.dart';
import '../models/user_role.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboards/dashboards.dart';

final appRouter = GoRouter(
  initialLocation: '/role-selection',
  routes: [
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/login/:role',
      builder: (context, state) {
        final roleString = state.pathParameters['role'];
        final role = UserRole.values.firstWhere(
            (r) => r.toDatabaseString == roleString,
            orElse: () => UserRole.patient); 
        return LoginScreen(role: role);
      },
    ),
    GoRoute(
      path: '/sign-up/:role',
      builder: (context, state) {
        final roleString = state.pathParameters['role'];
        final role = UserRole.values.firstWhere(
            (r) => r.toDatabaseString == roleString,
            orElse: () => UserRole.patient); 
        return SignUpScreen(role: role);
      },
    ),
    GoRoute(path: '/patient-dashboard', builder: (c, s) => const PatientDashboard()),
    GoRoute(path: '/clinic-dashboard', builder: (c, s) => const ClinicDashboard()),
    GoRoute(path: '/pharmacy-dashboard', builder: (c, s) => const PharmacyDashboard()),
    GoRoute(path: '/doctor-dashboard', builder: (c, s) => const DoctorDashboard()),
    GoRoute(path: '/pending-approval', builder: (c, s) => const PendingApprovalScreen()),
  ],
);
