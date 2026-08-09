import 'dart:io';
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

  Future<void> _runGcloudLogin(BuildContext context, WidgetRef ref) async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Launching "gcloud auth login"...'),
          backgroundColor: AppColors.accentBlue,
          duration: Duration(seconds: 2),
        ),
      );
      final result = await Process.run('gcloud', ['auth', 'login'], runInShell: true);
      if (result.exitCode == 0) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Successfully authenticated with gcloud CLI! Click Connect.'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('gcloud auth login failed: ${result.stderr}'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running gcloud: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

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
      ref.read(isConnectedProvider.notifier).state = false;

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
          content: Text('Loaded Service Account key for project "${saModel.projectId}"! Click Connect to authenticate.'),
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
    final isConnected = ref.watch(isConnectedProvider);
    final authState = ref.watch(authStateProvider);

    final isSuccessfullyConnected = isConnected && (authState.asData?.value.isSuccess == true);

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
                DropdownButtonFormField<AuthMode>(
                  initialValue: authMode,
                  isExpanded: true,
                  dropdownColor: AppColors.bgCard,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMain),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    fillColor: AppColors.bgInput,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return [
                      const Row(
                        children: [
                          Icon(Icons.key, size: 14, color: AppColors.accentBlue),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'ADC (gcloud auth application-default login)',
                              style: TextStyle(fontSize: 10, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Icon(Icons.terminal, size: 14, color: AppColors.accentBlue),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'gcloud CLI (gcloud auth login)',
                              style: TextStyle(fontSize: 10, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Icon(Icons.description, size: 14, color: AppColors.accentBlue),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Service Account (JSON Key)',
                              style: TextStyle(fontSize: 10, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                      ),
                    ];
                  },
                  items: const [
                    DropdownMenuItem(
                      value: AuthMode.adc,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.key, size: 13, color: AppColors.accentBlue),
                                SizedBox(width: 6),
                                Text('Application Default Credentials (ADC)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Command: gcloud auth application-default login',
                              style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: AuthMode.gcloudCli,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.terminal, size: 13, color: AppColors.accentBlue),
                                SizedBox(width: 6),
                                Text('gcloud CLI User Login', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Command: gcloud auth login',
                              style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: AuthMode.serviceAccount,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.description, size: 13, color: AppColors.accentBlue),
                                SizedBox(width: 6),
                                Text('Service Account Key File', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Uses: GCP Service Account JSON Key',
                              style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (newMode) {
                    if (newMode == null || newMode == authMode) return;
                    ref.read(authModeProvider.notifier).state = newMode;
                    ref.read(isConnectedProvider.notifier).state = false;

                    // Clear selections when switching auth mode
                    ref.read(selectedProjectProvider.notifier).state = null;
                    ref.read(selectedDatabaseProvider.notifier).state = null;
                    ref.read(selectedCollectionProvider.notifier).state = null;
                    ref.read(selectedDocumentProvider.notifier).state = null;
                    ref.read(documentsNotifierProvider.notifier).clearAll();
                  },
                ),
                const SizedBox(height: 6),

                // Dynamic Context View based on selected Auth Mode
                if (authMode == AuthMode.adc) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 12, color: AppColors.textMuted),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Uses system gcloud application-default credentials.',
                            style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (authMode == AuthMode.gcloudCli) ...[
                  if (!isSuccessfullyConnected) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isConnected && authState.asData?.value.isSuccess == false) ...[
                            Text(
                              authState.asData?.value.errorMessage ?? 'gcloud CLI login required',
                              style: const TextStyle(fontSize: 9, color: AppColors.accentRed),
                            ),
                            const SizedBox(height: 4),
                          ],
                          InkWell(
                            onTap: () => _runGcloudLogin(context, ref),
                            child: const Row(
                              children: [
                                Icon(Icons.login, size: 12, color: AppColors.accentBlue),
                                SizedBox(width: 4),
                                Text(
                                  'Run "gcloud auth login"',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.accentBlue,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else if (authMode == AuthMode.serviceAccount) ...[
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isConnected && serviceAccount == null) ...[
                          const Text(
                            'Please load a Service Account JSON Key file first.',
                            style: TextStyle(fontSize: 9, color: AppColors.accentRed),
                          ),
                          const SizedBox(height: 4),
                        ],
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
                    ),
                  ],
                ],

                const SizedBox(height: 6),
                // Connect / Connected Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuccessfullyConnected ? AppColors.bgInput : AppColors.accentBlue,
                      foregroundColor: isSuccessfullyConnected ? AppColors.textMuted : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: Icon(
                      isSuccessfullyConnected ? Icons.check_circle : Icons.power_settings_new,
                      size: 14,
                      color: isSuccessfullyConnected ? AppColors.accentGreen : Colors.white,
                    ),
                    label: Text(
                      isSuccessfullyConnected ? 'Connected' : 'Connect',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: isSuccessfullyConnected
                        ? null
                        : () {
                            ref.read(isConnectedProvider.notifier).state = true;
                            ref.invalidate(authStateProvider);
                            ref.invalidate(projectsListProvider);
                            ref.read(selectedProjectProvider.notifier).state = null;
                            ref.read(selectedDatabaseProvider.notifier).state = null;
                            ref.read(selectedCollectionProvider.notifier).state = null;
                            ref.read(selectedDocumentProvider.notifier).state = null;
                            ref.read(documentsNotifierProvider.notifier).clearAll();
                          },
                  ),
                ),
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
                    if (!isConnected || projects.isEmpty) {
                      return DropdownButtonFormField<GcpProject>(
                        items: const [],
                        onChanged: null,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: isConnected ? 'No GCP projects found' : 'Not Authenticated',
                          hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          fillColor: AppColors.bgInput,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: AppColors.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: AppColors.borderColor),
                          ),
                        ),
                      );
                    }
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
                  error: (err, _) => DropdownButtonFormField<GcpProject>(
                    items: const [],
                    onChanged: null,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Not Authenticated',
                      hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      fillColor: AppColors.bgInput,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                    ),
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
