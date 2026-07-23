import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_titlebar.dart';
import '../widgets/sidebar_explorer.dart';
import '../widgets/query_toolbar.dart';
import '../widgets/document_list_pane.dart';
import '../widgets/json_editor_pane.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Column(
        children: [
          // Top Window Titlebar
          const AppTitlebar(),

          // Main Workspace Layout
          Expanded(
            child: Row(
              children: [
                // Left Sidebar Explorer covering top-to-bottom (Auth, Project, Database, Collections)
                const SidebarExplorer(),

                // Right Workspace Area (Query Toolbar + Document Panes)
                Expanded(
                  child: Column(
                    children: [
                      // Query Toolbar at top of document area
                      const QueryToolbar(),

                      // Document List & JSON Detail Editor Panes
                      const Expanded(
                        child: Row(
                          children: [
                            // Collection Documents List & Pagination
                            DocumentListPane(),

                            // Document View & Edit Pane (Tree / Raw JSON)
                            Expanded(
                              child: JsonEditorPane(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Status Bar
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFF0D0F14),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Ready | Native Windows Firestore Client',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'package:googleapis REST',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
