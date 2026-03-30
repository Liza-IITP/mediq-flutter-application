# 🏥 Mediq: Multi-Tenant Healthcare Ecosystem

A comprehensive, real-time healthcare management platform built with Flutter and Supabase. Mediq orchestrates the entire clinical workflow, providing dedicated, role-based environments for Patients, Doctors, Clinic Administrators, and Pharmacy Managers.

## ✨ Key Features & Architecture

### 🔐 Multi-Role Authentication & Routing
- **Role-Based Access Control (RBAC):** Secure authentication directing four distinct user types (Patient, Doctor, Clinic Admin, Pharmacy) to isolated dashboards.
- **State Management:** Fully reactive UI powered by `flutter_riverpod` (`AsyncNotifier`) for seamless data fetching and caching.

### ⏱️ Real-Time Patient Queue & ETA Engine
- **Live Ticket System:** Utilizes Supabase Realtime (WebSockets) to push queue updates to the patient's device without manual refreshing.
- **Dynamic ETA Calculation:** An algorithm that calculates Estimated Time of Arrival (ETA) by querying active appointments ahead of the user in the queue and multiplying by average consultation times, rendering color-coded wait statuses.

### 📁 Relational Medical Records Vault
- **PostgreSQL & JSONB:** Prescriptions are stored securely, with complex data (like multi-medicine arrays) stored as JSONB and mapped natively into Flutter `ChoiceChip` widgets.
- **Doctor's Ledger:** Doctors have a dedicated history vault to review past prescriptions, heavily optimized to only fetch their specific patient interactions.

### 💊 Global Pharmacy Inventory & Search
- **Debounced Search Engine:** A global medicine search feature equipped with input debouncing to minimize API calls while delivering instant, keystroke-level results.
- **Inventory Management:** Pharmacy admins can dynamically add, update, and manage stock levels and pricing in real-time.

### 📊 Clinic Administration Analytics
- **Master Appointment Ledger:** A centralized history tab for Clinic Admins to track all completed appointments.
- **Name Caching Optimization:** Implemented a local caching mechanism to resolve UUIDs to user names, drastically reducing duplicate database queries and improving ledger load times.

### 🎨 Premium Responsive UI/UX
- **Cross-Platform Constraints:** Features a custom `ResponsiveContainer` wrapper to prevent UI stretching on ultra-wide desktop monitors, locking the interface to a readable, optimal golden ratio.
- **Global Design System:** A unified, premium `ThemeData` implementation featuring a cohesive "Medical Teal" color palette, soft drop-shadows, and modern rounded input fields.

### 🛡️ Enterprise-Grade Security
- **Row Level Security (RLS):** Supabase database is locked down at the PostgreSQL level. Cryptographic policies ensure users can only `SELECT`, `INSERT`, or `UPDATE` rows that belong to their specific `auth.uid()`.
- **Environment Protection:** All API keys and sensitive URLs are abstracted using `flutter_dotenv` and excluded from version control via `.gitignore`.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **State Management:** Riverpod (`flutter_riverpod`)
* **Backend as a Service:** Supabase
* **Database:** PostgreSQL
* **Real-Time:** Supabase Streams / WebSockets

---

## 📂 Folder Structure

```text
lib/
├── models/          # Data classes and JSON serialization
├── providers/       # Riverpod AsyncNotifiers and state logic
├── routing/         # Navigation and role-based route guards
├── screens/         # UI Views (Dashboards, Auth, Records)
├── widgets/         # Reusable UI components (ResponsiveContainer)
└── main.dart        # Entry point and Global ThemeData