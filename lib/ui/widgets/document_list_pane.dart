import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_toast.dart';
import '../../state/project_provider.dart';
import '../../state/database_provider.dart';
import '../../state/collection_provider.dart';
import '../../state/document_provider.dart';
import '../../state/query_provider.dart';
import 'add_document_dialog.dart';

class DocumentListPane extends ConsumerWidget {
  const DocumentListPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsState = ref.watch(documentsNotifierProvider);
    final selectedDoc = ref.watch(selectedDocumentProvider);
    final currentPageIndex = ref.watch(currentPageIndexProvider);
    final pageHistory = ref.watch(pageHistoryProvider);

    final selectedProject = ref.watch(selectedProjectProvider);
    final selectedDatabase = ref.watch(selectedDatabaseProvider);
    final selectedCollection = ref.watch(selectedCollectionProvider);

    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: AppColors.bgSidebar,
        border: Border(right: BorderSide(color: AppColors.borderColor)),
      ),
      child: Column(
        children: [
          // Pane Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: Colors.black.withValues(alpha: 0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Documents (${docsState.documents.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16, color: AppColors.accentBlue),
                  tooltip: selectedCollection != null
                      ? 'Add Document to "$selectedCollection"'
                      : 'Select a collection first',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: (selectedProject != null &&
                          selectedDatabase != null &&
                          selectedCollection != null)
                      ? () {
                          showDialog(
                            context: context,
                            builder: (context) => AddDocumentDialog(
                              project: selectedProject,
                              database: selectedDatabase,
                              collectionId: selectedCollection,
                            ),
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Document List
          Expanded(
            child: docsState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.firebaseGold))
                : docsState.errorMessage != null
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.error_outline, size: 16, color: AppColors.accentRed),
                                      SizedBox(width: 6),
                                      Text('Query Error', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 14, color: AppColors.accentRed),
                                    tooltip: 'Copy Error Text',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: docsState.errorMessage!));
                                      AppToast.showInfo(context, 'Error copied to clipboard');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                docsState.errorMessage!,
                                style: const TextStyle(color: AppColors.accentRed, fontSize: 11, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : docsState.documents.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No documents loaded.\nClick "Execute Query" to fetch.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textDim, fontSize: 11),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: docsState.documents.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final doc = docsState.documents[index];
                              final isSelected = selectedDoc?.id == doc.id;
                              return InkWell(
                                onTap: () {
                                  ref.read(selectedDocumentProvider.notifier).state = doc;
                                  ref.read(isReadOnlyProvider.notifier).state = true; // Lock read-only on click
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: isSelected
                                      ? const BoxDecoration(
                                          color: AppColors.bgCard,
                                          border: Border(
                                            left: BorderSide(
                                              color: AppColors.firebaseGold,
                                              width: 3,
                                            ),
                                          ),
                                        )
                                      : null,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.id,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.firebaseGold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        doc.previewSummary,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          const Divider(height: 1),

          // Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.black.withValues(alpha: 0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page ${currentPageIndex + 1}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                Row(
                  children: [
                    // Prev Button
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      color: currentPageIndex > 0 ? AppColors.textMain : AppColors.textDim,
                      onPressed: currentPageIndex > 0
                          ? () {
                              final newIndex = currentPageIndex - 1;
                              ref.read(currentPageIndexProvider.notifier).state = newIndex;
                              ref.read(pageTokenProvider.notifier).state = pageHistory[newIndex];
                              ref.read(documentsNotifierProvider.notifier).executeQuery();
                            }
                          : null,
                    ),
                    // Next Button
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      color: docsState.nextPageToken != null ? AppColors.textMain : AppColors.textDim,
                      onPressed: docsState.nextPageToken != null
                          ? () {
                              final nextToken = docsState.nextPageToken;
                              final newIndex = currentPageIndex + 1;

                              // Update page history
                              final newHistory = List<String?>.from(pageHistory);
                              if (newHistory.length <= newIndex) {
                                newHistory.add(nextToken);
                              } else {
                                newHistory[newIndex] = nextToken;
                              }

                              ref.read(pageHistoryProvider.notifier).state = newHistory;
                              ref.read(currentPageIndexProvider.notifier).state = newIndex;
                              ref.read(pageTokenProvider.notifier).state = nextToken;
                              ref.read(documentsNotifierProvider.notifier).executeQuery();
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
