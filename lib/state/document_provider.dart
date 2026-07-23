import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firestore_document.dart';
import '../models/query_clause.dart';
import 'project_provider.dart';
import 'database_provider.dart';
import 'collection_provider.dart';
import 'query_provider.dart';
import 'service_providers.dart';

class DocumentsState {
  final List<FirestoreDocumentModel> documents;
  final bool isLoading;
  final String? errorMessage;
  final String? nextPageToken;

  const DocumentsState({
    required this.documents,
    required this.isLoading,
    this.errorMessage,
    this.nextPageToken,
  });

  factory DocumentsState.initial() => const DocumentsState(
        documents: [],
        isLoading: false,
      );

  DocumentsState copyWith({
    List<FirestoreDocumentModel>? documents,
    bool? isLoading,
    String? errorMessage,
    String? nextPageToken,
  }) {
    return DocumentsState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      nextPageToken: nextPageToken,
    );
  }
}

class DocumentsNotifier extends StateNotifier<DocumentsState> {
  final Ref ref;
  final Map<String, DocumentsState> _collectionCache = {};

  DocumentsNotifier(this.ref) : super(DocumentsState.initial());

  String _cacheKey(String projectId, String databaseId, String collectionId) {
    return '$projectId/$databaseId/$collectionId';
  }

  /// Restores cached documents if collection was previously fetched, or initializes empty
  void onCollectionSelected(String projectId, String databaseId, String collectionId) {
    final key = _cacheKey(projectId, databaseId, collectionId);
    if (_collectionCache.containsKey(key)) {
      final cachedState = _collectionCache[key]!;
      state = cachedState;
      if (cachedState.documents.isNotEmpty) {
        ref.read(selectedDocumentProvider.notifier).state = cachedState.documents.first;
      }
    } else {
      state = DocumentsState.initial();
    }
  }

  void clearAll() {
    _collectionCache.clear();
    state = DocumentsState.initial();
  }

  void clear() {
    state = DocumentsState.initial();
  }

  Future<void> executeQuery() async {
    final project = ref.read(selectedProjectProvider);
    final database = ref.read(selectedDatabaseProvider);
    final collection = ref.read(selectedCollectionProvider);
    final mode = ref.read(fetchModeProvider);
    final input = ref.read(queryInputProvider).trim();
    final pageSize = ref.read(pageSizeProvider);
    final pageToken = ref.read(pageTokenProvider);

    if (project == null || database == null || collection == null) {
      state = state.copyWith(
        errorMessage: 'Please select a Project, Database, and Collection first.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final service = ref.read(firestoreDataServiceProvider);

      if (mode == FetchMode.byDocId) {
        var docId = input.trim();
        if ((docId.startsWith("'") && docId.endsWith("'")) ||
            (docId.startsWith('"') && docId.endsWith('"'))) {
          docId = docId.substring(1, docId.length - 1).trim();
        }

        if (docId.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Please enter a Document ID.',
          );
          return;
        }

        final doc = await service.getDocument(
          projectId: project.projectId,
          databaseId: database.databaseId,
          collectionId: collection,
          documentId: docId,
        );

        if (doc != null) {
          state = DocumentsState(
            documents: [doc],
            isLoading: false,
            nextPageToken: null,
          );
          ref.read(selectedDocumentProvider.notifier).state = doc;
        } else {
          state = DocumentsState(
            documents: [],
            isLoading: false,
            errorMessage: 'Document "$docId" not found in collection "$collection".',
          );
          ref.read(selectedDocumentProvider.notifier).state = null;
        }
      } else {
        // FetchMode.query
        if (input.isNotEmpty) {
          final syntaxError = QueryParser.validateSyntax(input);
          if (syntaxError != null) {
            state = state.copyWith(
              isLoading: false,
              errorMessage: syntaxError,
            );
            return;
          }
        }

        // Parse structured query filters and sorts
        final parsed = QueryParser.parse(input);

        if (parsed.filters.isNotEmpty || parsed.sorts.isNotEmpty) {
          final result = await service.runStructuredQuery(
            projectId: project.projectId,
            databaseId: database.databaseId,
            collectionId: collection,
            filters: parsed.filters,
            sorts: parsed.sorts,
            pageSize: pageSize,
          );

          state = DocumentsState(
            documents: result.documents,
            isLoading: false,
            nextPageToken: result.nextPageToken,
          );

          if (result.documents.isNotEmpty) {
            ref.read(selectedDocumentProvider.notifier).state = result.documents.first;
          } else {
            ref.read(selectedDocumentProvider.notifier).state = null;
          }

          final key = _cacheKey(project.projectId, database.databaseId, collection);
          _collectionCache[key] = state;
          return;
        }

        // Smart fallback: If input is a single token ID without spaces or WHERE/ORDER BY keywords, try exact document ID lookup first!
        if (input.isNotEmpty &&
            !input.toUpperCase().contains('WHERE') &&
            !input.toUpperCase().contains('ORDER BY') &&
            !input.contains(' ')) {
          try {
            final singleDoc = await service.getDocument(
              projectId: project.projectId,
              databaseId: database.databaseId,
              collectionId: collection,
              documentId: input,
            );

            if (singleDoc != null) {
              state = DocumentsState(
                documents: [singleDoc],
                isLoading: false,
                nextPageToken: null,
              );
              ref.read(selectedDocumentProvider.notifier).state = singleDoc;

              final key = _cacheKey(project.projectId, database.databaseId, collection);
              _collectionCache[key] = state;
              return;
            }
          } catch (_) {
            // If not found by direct ID, continue to list documents
          }
        }

        final result = await service.listDocuments(
          projectId: project.projectId,
          databaseId: database.databaseId,
          collectionId: collection,
          pageSize: pageSize,
          pageToken: pageToken,
        );

        state = DocumentsState(
          documents: result.documents,
          isLoading: false,
          nextPageToken: result.nextPageToken,
        );

        if (result.documents.isNotEmpty) {
          ref.read(selectedDocumentProvider.notifier).state = result.documents.first;
        } else {
          ref.read(selectedDocumentProvider.notifier).state = null;
        }
      }

      // Save to cache after successful fetch
      final key = _cacheKey(project.projectId, database.databaseId, collection);
      _collectionCache[key] = state;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Adds a newly created document to state, selects it, and updates collection cache
  void addCreatedDocument(String projectId, String databaseId, String collectionId, FirestoreDocumentModel newDoc) {
    final updatedDocs = [newDoc, ...state.documents.where((d) => d.id != newDoc.id)];
    state = state.copyWith(
      documents: updatedDocs,
      isLoading: false,
      errorMessage: null,
    );
    ref.read(selectedDocumentProvider.notifier).state = newDoc;
    final key = _cacheKey(projectId, databaseId, collectionId);
    _collectionCache[key] = state;
  }
}

final documentsNotifierProvider =
    StateNotifierProvider<DocumentsNotifier, DocumentsState>((ref) {
  return DocumentsNotifier(ref);
});

final selectedDocumentProvider = StateProvider<FirestoreDocumentModel?>((ref) => null);
final isReadOnlyProvider = StateProvider<bool>((ref) => true);
final isSavingProvider = StateProvider<bool>((ref) => false);
