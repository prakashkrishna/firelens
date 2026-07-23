import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_toast.dart';
import '../../models/gcp_project.dart';
import '../../models/firestore_database.dart';
import '../../state/auth_provider.dart';
import '../../state/project_provider.dart';
import '../../state/database_provider.dart';
import '../../state/collection_provider.dart';
import '../../state/document_provider.dart';
import '../../state/query_provider.dart';

import 'add_collection_dialog.dart';

class SidebarExplorer extends ConsumerWidget {
  const SidebarExplorer({super.key});

  Future<void> _pickServiceAccountFile(BuildContext context, WidgetRef ref) async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      const typeGroup = XTypeGroup(
        label: 'JSON Files (*.json)',
        extensions: <String>['json'],
      );
      final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

      if (file == null) return;

      final content = await file.readAsString();
      final saModel = ServiceAccountModel.fromFile(file.path, content);

      ref.read(serviceAccountProvider.notifier).state = saModel;
      ref.read(authModeProvider.notifier).state = AuthMode.serviceAccount;

      final saProject = GcpProject(
        projectId: saModel.projectId,
        name: '${saModel.projectId} (Service Account)',
      );
      ref.read(selectedProjectProvider.notifier).state = saProject;
      ref.read(selectedDatabaseProvider.notifier).state = null;
      ref.read(selectedCollectionProvider.notifier).state = null;
      ref.read(selectedDocumentProvider.notifier).state = null;
      ref.read(documentsNotifierProvider.notifier).clearAll();

      messenger.showSnackBar(
        SnackBar(
          content: Text('Loaded Service Account key for project "${saModel.projectId}"!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load Service Account JSON: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authMode = ref.watch(authModeProvider);
    final serviceAccount = ref.watch(serviceAccountProvider);

    final projectsAsync = ref.watch(projectsListProvider);
    final selectedProject = ref.watch(selectedProjectProvider);

    final databasesAsync = ref.watch(databasesListProvider);
    final selectedDatabase = ref.watch(selectedDatabaseProvider);

    final collectionsAsync = ref.watch(collectionsListProvider);
    final selectedCollection = ref.watch(selectedCollectionProvider);

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.bgSidebar,
        border: Border(right: BorderSide(color: AppColors.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auth Mode Header Section
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AUTHENTICATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<AuthMode>(
                        style: SegmentedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          selectedBackgroundColor: AppColors.accentBlue,
                          selectedForegroundColor: Colors.white,
                          backgroundColor: AppColors.bgInput,
                          foregroundColor: AppColors.textMuted,
                          side: const BorderSide(color: AppColors.borderColor),
                          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        segments: const [
                          ButtonSegment<AuthMode>(
                            value: AuthMode.adc,
                            label: Text('ADC'),
                            icon: Icon(Icons.key, size: 12),
                          ),
                          ButtonSegment<AuthMode>(
                            value: AuthMode.serviceAccount,
                            label: Text('Service Account'),
                            icon: Icon(Icons.description, size: 12),
                          ),
                        ],
                        selected: {authMode},
                        onSelectionChanged: (newSelection) {
                          final newMode = newSelection.first;
                          ref.read(authModeProvider.notifier).state = newMode;

                          // Clear selections when switching auth mode
                          ref.read(selectedProjectProvider.notifier).state = null;
                          ref.read(selectedDatabaseProvider.notifier).state = null;
                          ref.read(selectedCollectionProvider.notifier).state = null;
                          ref.read(selectedDocumentProvider.notifier).state = null;
                          ref.read(documentsNotifierProvider.notifier).clearAll();

                          if (newMode == AuthMode.serviceAccount && serviceAccount == null) {
                            _pickServiceAccountFile(context, ref);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (authMode == AuthMode.serviceAccount) ...[
                  const SizedBox(height: 6),
                  if (serviceAccount != null) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, size: 14, color: AppColors.accentGreen),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  serviceAccount.projectId,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (serviceAccount.clientEmail.isNotEmpty)
                                  Text(
                                    serviceAccount.clientEmail,
                                    style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.folder_open, size: 14, color: AppColors.accentBlue),
                            tooltip: 'Change JSON Key File',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            onPressed: () => _pickServiceAccountFile(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accentBlue),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        icon: const Icon(Icons.upload_file, size: 14, color: AppColors.accentBlue),
                        label: const Text('Load JSON Key File', style: TextStyle(fontSize: 11, color: AppColors.accentBlue)),
                        onPressed: () => _pickServiceAccountFile(context, ref),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const Divider(height: 12),
          // Project Selector Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECT GCP PROJECT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                projectsAsync.when(
                  data: (projects) {
                    final validSelectedProject = projects.contains(selectedProject) ? selectedProject : null;
                    return DropdownButtonFormField<GcpProject>(
                      initialValue: validSelectedProject,
                      isExpanded: true,
                      focusNode: FocusNode(),
                      enableFeedback: true,
                      dropdownColor: AppColors.bgCard,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMain),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      fillColor: AppColors.bgInput,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                    ),
                    items: projects.map((proj) {
                      return DropdownMenuItem<GcpProject>(
                        value: proj,
                        child: Text(proj.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (proj) {
                      ref.read(selectedProjectProvider.notifier).state = proj;
                      ref.read(selectedDatabaseProvider.notifier).state = null;
                      ref.read(selectedCollectionProvider.notifier).state = null;
                      ref.read(selectedDocumentProvider.notifier).state = null;
                      ref.read(documentsNotifierProvider.notifier).clearAll();
                    },
                  );
                },
                  loading: () => const LinearProgressIndicator(color: AppColors.firebaseGold),
                  error: (err, _) => Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          'Error: $err',
                          style: const TextStyle(color: AppColors.accentRed, fontSize: 11),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 14, color: AppColors.accentRed),
                        tooltip: 'Copy Error Text',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: err.toString()));
                          AppToast.showInfo(context, 'Project error copied to clipboard');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Database Selector Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECT DATABASE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                databasesAsync.when(
                  data: (databases) => DropdownButtonFormField<FirestoreDatabase>(
                    initialValue: selectedDatabase,
                    isExpanded: true,
                    focusNode: FocusNode(),
                    enableFeedback: true,
                    dropdownColor: AppColors.bgCard,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMain),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      fillColor: AppColors.bgInput,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                    ),
                    items: databases.map((db) {
                      return DropdownMenuItem<FirestoreDatabase>(
                        value: db,
                        child: Text(db.databaseId, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (db) {
                      ref.read(selectedDatabaseProvider.notifier).state = db;
                      ref.read(selectedCollectionProvider.notifier).state = null;
                      ref.read(selectedDocumentProvider.notifier).state = null;
                      ref.read(documentsNotifierProvider.notifier).clearAll();
                    },
                  ),
                  loading: () => const LinearProgressIndicator(color: AppColors.firebaseGold),
                  error: (err, _) => Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          'Error: $err',
                          style: const TextStyle(color: AppColors.accentRed, fontSize: 11),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 14, color: AppColors.accentRed),
                        tooltip: 'Copy Error Text',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: err.toString()));
                          AppToast.showInfo(context, 'Database error copied to clipboard');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Collections List Section
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8, top: 12, bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'COLLECTIONS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16, color: AppColors.accentBlue),
                  tooltip: 'Add New Collection',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: (selectedProject != null && selectedDatabase != null)
                      ? () {
                          showDialog(
                            context: context,
                            builder: (context) => AddCollectionDialog(
                              project: selectedProject,
                              database: selectedDatabase,
                            ),
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),

          Expanded(
            child: collectionsAsync.when(
              data: (collections) {
                if (collections.isEmpty) {
                  return const Center(
                    child: Text(
                      'No collections found\n(or select a DB first)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textDim, fontSize: 11),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final col = collections[index];
                    final isSelected = col == selectedCollection;
                    return InkWell(
                      onTap: () {
                        ref.read(selectedCollectionProvider.notifier).state = col;
                        ref.read(selectedDocumentProvider.notifier).state = null;
                        ref.read(currentPageIndexProvider.notifier).state = 0;
                        ref.read(pageHistoryProvider.notifier).state = [null];
                        ref.read(pageTokenProvider.notifier).state = null;

                        final proj = ref.read(selectedProjectProvider);
                        final db = ref.read(selectedDatabaseProvider);
                        if (proj != null && db != null) {
                          ref.read(documentsNotifierProvider.notifier).onCollectionSelected(
                            proj.projectId,
                            db.databaseId,
                            col,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.15) : null,
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.folder_open : Icons.folder,
                              size: 16,
                              color: isSelected ? AppColors.accentBlue : AppColors.firebaseGold,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                col,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? AppColors.accentBlue : AppColors.textMain,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.firebaseGold)),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
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
                              Text(
                                'Collection Error',
                                style: TextStyle(
                                  color: AppColors.accentRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 14, color: AppColors.accentRed),
                            tooltip: 'Copy Error Text',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: err.toString()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Collection error copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        err.toString(),
                        style: const TextStyle(
                          color: AppColors.accentRed,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
