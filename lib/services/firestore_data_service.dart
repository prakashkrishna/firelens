import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart' as http;
import '../core/converters/firestore_json_converter.dart';
import '../models/firestore_document.dart';
import '../models/query_clause.dart';

class QueryResult {
  final List<FirestoreDocumentModel> documents;
  final String? nextPageToken;

  QueryResult({
    required this.documents,
    this.nextPageToken,
  });
}

class FirestoreDataService {
  final http.Client client;

  FirestoreDataService(this.client);

  /// Fetches a single document directly by ID
  Future<FirestoreDocumentModel?> getDocument({
    required String projectId,
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) async {
    try {
      final api = FirestoreApi(client);
      final name =
          'projects/$projectId/databases/$databaseId/documents/$collectionId/$documentId';

      final doc = await api.projects.databases.documents.get(name);
      return FirestoreDocumentModel.fromApiDocument(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Lists documents in a collection with pagination support
  Future<QueryResult> listDocuments({
    required String projectId,
    required String databaseId,
    required String collectionId,
    int pageSize = 25,
    String? pageToken,
  }) async {
    try {
      final api = FirestoreApi(client);
      final parent =
          'projects/$projectId/databases/$databaseId/documents';

      final response = await api.projects.databases.documents.list(
        parent,
        collectionId,
        pageSize: pageSize,
        pageToken: pageToken,
      );

      final docs = (response.documents ?? [])
          .map((doc) => FirestoreDocumentModel.fromApiDocument(doc))
          .toList();

      return QueryResult(
        documents: docs,
        nextPageToken: response.nextPageToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Executes a structured Firestore REST API query with filters, sorting, and pagination
  Future<QueryResult> runStructuredQuery({
    required String projectId,
    required String databaseId,
    required String collectionId,
    required List<FilterClause> filters,
    required List<SortClause> sorts,
    int pageSize = 25,
  }) async {
    try {
      final api = FirestoreApi(client);
      final parent = 'projects/$projectId/databases/$databaseId/documents';

      final structuredQuery = StructuredQuery(
        from: [CollectionSelector(collectionId: collectionId)],
        limit: pageSize,
      );

      // Build Filters
      if (filters.isNotEmpty) {
        final filterList = <Filter>[];
        for (final f in filters) {
          if (f.field.trim().isEmpty) continue;

          String restOp = 'EQUAL';
          switch (f.operator) {
            case '==':
              restOp = 'EQUAL';
              break;
            case '!=':
              restOp = 'NOT_EQUAL';
              break;
            case '>':
              restOp = 'GREATER_THAN';
              break;
            case '>=':
              restOp = 'GREATER_THAN_OR_EQUAL';
              break;
            case '<':
              restOp = 'LESS_THAN';
              break;
            case '<=':
              restOp = 'LESS_THAN_OR_EQUAL';
              break;
            case 'array-contains':
              restOp = 'ARRAY_CONTAINS';
              break;
            case 'array-contains-any':
              restOp = 'ARRAY_CONTAINS_ANY';
              break;
            case 'in':
              restOp = 'IN';
              break;
            case 'not-in':
              restOp = 'NOT_IN';
              break;
          }

          dynamic parsedVal;
          final rawVal = f.value.trim();
          switch (f.dataType) {
            case FilterDataType.string:
              parsedVal = (rawVal.startsWith("'") && rawVal.endsWith("'")) || (rawVal.startsWith('"') && rawVal.endsWith('"'))
                  ? rawVal.substring(1, rawVal.length - 1)
                  : rawVal;
              break;
            case FilterDataType.integer:
              parsedVal = int.tryParse(rawVal) ?? 0;
              break;
            case FilterDataType.doubleVal:
              parsedVal = double.tryParse(rawVal) ?? 0.0;
              break;
            case FilterDataType.boolean:
              parsedVal = rawVal.toLowerCase() == 'true';
              break;
            case FilterDataType.timestamp:
              final dt = DateTime.tryParse(rawVal) ?? DateTime.now();
              parsedVal = dt.toUtc().toIso8601String();
              break;
            case FilterDataType.nullValue:
              parsedVal = null;
              break;
            case FilterDataType.array:
            case FilterDataType.mapVal:
            case FilterDataType.reference:
            case FilterDataType.geoPoint:
            case FilterDataType.bytes:
              parsedVal = rawVal;
              break;
          }

          final restValue = FirestoreJsonConverter.dynamicToValue(parsedVal);

          filterList.add(Filter(
            fieldFilter: FieldFilter(
              field: FieldReference(fieldPath: f.field.trim()),
              op: restOp,
              value: restValue,
            ),
          ));
        }

        if (filterList.length == 1) {
          structuredQuery.where = filterList.first;
        } else if (filterList.length > 1) {
          structuredQuery.where = Filter(
            compositeFilter: CompositeFilter(
              op: 'AND',
              filters: filterList,
            ),
          );
        }
      }

      // Build Sorts
      if (sorts.isNotEmpty) {
        final orderList = <Order>[];
        for (final s in sorts) {
          if (s.field.trim().isNotEmpty) {
            orderList.add(Order(
              field: FieldReference(fieldPath: s.field.trim()),
              direction: s.direction.toUpperCase() == 'DESC' ? 'DESCENDING' : 'ASCENDING',
            ));
          }
        }
        structuredQuery.orderBy = orderList;
      }

      final request = RunQueryRequest(structuredQuery: structuredQuery);
      final responseList = await api.projects.databases.documents.runQuery(
        request,
        parent,
      );

      final docs = responseList
          .where((res) => res.document != null)
          .map((res) => FirestoreDocumentModel.fromApiDocument(res.document!))
          .toList();

      return QueryResult(
        documents: docs,
        nextPageToken: null,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Updates/Patches an existing document or creates a new document with clean JSON map
  Future<FirestoreDocumentModel> saveDocument({
    required String documentPath,
    required Map<String, dynamic> jsonData,
  }) async {
    try {
      final api = FirestoreApi(client);
      final fields = FirestoreJsonConverter.jsonToFields(jsonData);

      final docToUpdate = Document()..fields = fields;

      final updatedDoc = await api.projects.databases.documents.patch(
        docToUpdate,
        documentPath,
      );

      return FirestoreDocumentModel.fromApiDocument(updatedDoc);
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a new document in a collection with custom ID or auto-generated ID
  Future<FirestoreDocumentModel> createDocument({
    required String projectId,
    required String databaseId,
    required String collectionId,
    String? documentId,
    required Map<String, dynamic> jsonData,
  }) async {
    try {
      final api = FirestoreApi(client);
      final parent = 'projects/$projectId/databases/$databaseId/documents';
      final fields = FirestoreJsonConverter.jsonToFields(jsonData);
      final docToCreate = Document()..fields = fields;

      final createdDoc = await api.projects.databases.documents.createDocument(
        docToCreate,
        parent,
        collectionId,
        documentId: (documentId != null && documentId.trim().isNotEmpty)
            ? documentId.trim()
            : null,
      );

      return FirestoreDocumentModel.fromApiDocument(createdDoc);
    } catch (e) {
      rethrow;
    }
  }

  /// Helper to convert dot-notated field paths (e.g. "userProfile.role") into nested Firestore Value maps
  Map<String, Value> _buildNestedFieldMap(String fieldPath, Value fieldValue) {
    final parts = fieldPath.split('.');
    if (parts.length == 1) {
      return {parts[0]: fieldValue};
    }

    Value currentVal = fieldValue;
    for (int i = parts.length - 1; i >= 1; i--) {
      currentVal = Value(
        mapValue: MapValue(
          fields: {parts[i]: currentVal},
        ),
      );
    }
    return {parts[0]: currentVal};
  }

  /// Updates or adds a single field in a document using package:googleapis patch with updateMask_fieldPaths
  Future<FirestoreDocumentModel> updateSingleField({
    required String documentPath,
    required String fieldPath,
    required dynamic fieldValue,
  }) async {
    try {
      final api = FirestoreApi(client);
      final val = FirestoreJsonConverter.dynamicToValue(fieldValue);
      final fieldsMap = _buildNestedFieldMap(fieldPath, val);
      final docToPatch = Document()..fields = fieldsMap;

      final updatedDoc = await api.projects.databases.documents.patch(
        docToPatch,
        documentPath,
        updateMask_fieldPaths: [fieldPath],
      );

      return FirestoreDocumentModel.fromApiDocument(updatedDoc);
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a single field from a document using package:googleapis patch with updateMask_fieldPaths
  Future<FirestoreDocumentModel> deleteSingleField({
    required String documentPath,
    required String fieldPath,
  }) async {
    try {
      final api = FirestoreApi(client);
      // Specifying updateMask_fieldPaths while omitting fieldPath from fields removes it from Firestore document
      final docToPatch = Document()..fields = {};

      final updatedDoc = await api.projects.databases.documents.patch(
        docToPatch,
        documentPath,
        updateMask_fieldPaths: [fieldPath],
      );

      return FirestoreDocumentModel.fromApiDocument(updatedDoc);
    } catch (e) {
      rethrow;
    }
  }
}
