import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firestore_database.dart';
import 'project_provider.dart';
import 'service_providers.dart';

final databasesListProvider = FutureProvider<List<FirestoreDatabase>>((ref) async {
  final selectedProject = ref.watch(selectedProjectProvider);
  if (selectedProject == null) return [];
  
  final service = ref.watch(firestoreAdminServiceProvider);
  return await service.listDatabases(selectedProject.projectId);
});

final selectedDatabaseProvider = StateProvider<FirestoreDatabase?>((ref) => null);
