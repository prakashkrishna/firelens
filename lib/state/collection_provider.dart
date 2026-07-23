import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'project_provider.dart';
import 'database_provider.dart';
import 'service_providers.dart';

final collectionsListProvider = FutureProvider<List<String>>((ref) async {
  final project = ref.watch(selectedProjectProvider);
  final database = ref.watch(selectedDatabaseProvider);

  if (project == null || database == null) return [];

  final service = ref.watch(firestoreAdminServiceProvider);
  return await service.listCollectionIds(project.projectId, database.databaseId);
});

final selectedCollectionProvider = StateProvider<String?>((ref) => null);
