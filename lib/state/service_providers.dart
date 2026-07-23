import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/gcp_resource_manager_service.dart';
import '../services/firestore_admin_service.dart';
import '../services/firestore_data_service.dart';
import 'auth_provider.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (result) => result.client,
    loading: () => http.Client(),
    error: (_, _) => http.Client(),
  );
});

final resourceManagerServiceProvider = Provider<GcpResourceManagerService>((ref) {
  final client = ref.watch(httpClientProvider);
  return GcpResourceManagerService(client);
});

final firestoreAdminServiceProvider = Provider<FirestoreAdminService>((ref) {
  final client = ref.watch(httpClientProvider);
  return FirestoreAdminService(client);
});

final firestoreDataServiceProvider = Provider<FirestoreDataService>((ref) {
  final client = ref.watch(httpClientProvider);
  return FirestoreDataService(client);
});
