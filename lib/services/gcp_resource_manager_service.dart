import 'package:googleapis/cloudresourcemanager/v1.dart';
import 'package:http/http.dart' as http;
import '../models/gcp_project.dart';

class GcpResourceManagerService {
  final http.Client client;

  GcpResourceManagerService(this.client);

  Future<List<GcpProject>> listProjects() async {
    try {
      final api = CloudResourceManagerApi(client);
      final response = await api.projects.list();
      final projects = response.projects ?? [];

      return projects
          .where((p) => p.projectId != null && p.lifecycleState == 'ACTIVE')
          .map((p) => GcpProject(
                projectId: p.projectId!,
                name: p.name ?? p.projectId!,
              ))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
