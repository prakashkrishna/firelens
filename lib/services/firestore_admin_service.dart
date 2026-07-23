import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart' as http;
import '../models/firestore_database.dart';

class FirestoreAdminService {
  final http.Client client;

  FirestoreAdminService(this.client);

  /// Lists all database instances in a given GCP project
  Future<List<FirestoreDatabase>> listDatabases(String projectId) async {
    try {
      final api = FirestoreApi(client);
      final parent = 'projects/$projectId';
      final response = await api.projects.databases.list(parent);
      final databases = response.databases ?? [];

      if (databases.isEmpty) {
        // Fallback default database if list API returns empty but database exists
        return [
          FirestoreDatabase(
            databaseId: '(default)',
            name: '$parent/databases/(default)',
            locationId: 'default',
          ),
        ];
      }

      return databases.map((db) {
        final dbId = db.name?.split('/').last ?? '(default)';
        return FirestoreDatabase(
          databaseId: dbId,
          name: db.name ?? '$parent/databases/$dbId',
          locationId: db.locationId ?? 'unknown',
        );
      }).toList();
    } catch (_) {
      // Return default database if admin listing fails due to permissions
      return [
        FirestoreDatabase(
          databaseId: '(default)',
          name: 'projects/$projectId/databases/(default)',
          locationId: 'default',
        ),
      ];
    }
  }

  /// Lists top-level collection IDs in the selected database
  Future<List<String>> listCollectionIds(String projectId, String databaseId) async {
    try {
      final api = FirestoreApi(client);
      final parent = 'projects/$projectId/databases/$databaseId/documents';
      final request = ListCollectionIdsRequest();
      
      final response = await api.projects.databases.documents.listCollectionIds(
        request,
        parent,
      );

      return response.collectionIds ?? [];
    } catch (e) {
      rethrow;
    }
  }
}
