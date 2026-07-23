import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gcp_project.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

final projectsListProvider = FutureProvider<List<GcpProject>>((ref) async {
  final authMode = ref.watch(authModeProvider);
  final serviceAccount = ref.watch(serviceAccountProvider);
  final service = ref.watch(resourceManagerServiceProvider);

  if (authMode == AuthMode.serviceAccount && serviceAccount != null) {
    final saProject = GcpProject(
      projectId: serviceAccount.projectId,
      name: '${serviceAccount.projectId} (Service Account)',
    );
    try {
      final projects = await service.listProjects();
      if (!projects.any((p) => p.projectId == saProject.projectId)) {
        return [saProject, ...projects];
      }
      return projects;
    } catch (_) {
      return [saProject];
    }
  }

  return await service.listProjects();
});

final selectedProjectProvider = StateProvider<GcpProject?>((ref) => null);
