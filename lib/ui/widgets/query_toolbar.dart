import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/query_provider.dart';
import '../../state/document_provider.dart';
import 'custom_combobox.dart';
import 'query_help_dialog.dart';
import 'visual_query_builder.dart';

class QueryToolbar extends ConsumerStatefulWidget {
  const QueryToolbar({super.key});

  @override
  ConsumerState<QueryToolbar> createState() => _QueryToolbarState();
}

class _QueryToolbarState extends ConsumerState<QueryToolbar> {
  late TextEditingController _inputController;
  bool _isBuilderOpen = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _updateQuery(String text) {
    if (_inputController.text != text) {
      _inputController.text = text;
    }
    ref.read(queryInputProvider.notifier).state = text;
  }

  void _appendQuery(String snippet) {
    final current = _inputController.text.trim();
    if (current.isEmpty) {
      _updateQuery(snippet);
      return;
    }

    String result;
    if (snippet.startsWith('WHERE ')) {
      final snippetClause = snippet.substring(6).trim();
      if (RegExp(r'\bWHERE\b', caseSensitive: false).hasMatch(current)) {
        result = '$current AND $snippetClause';
      } else {
        result = '$current $snippet';
      }
    } else {
      result = '$current $snippet';
    }

    _updateQuery(result);
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(fetchModeProvider);
    final pageSize = ref.watch(pageSizeProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSidebar,
        border: Border(bottom: BorderSide(color: AppColors.borderColor)),
      ),
      child: Column(
        children: [
          // Responsive Query Toolbar Bar (Expands full width on desktop)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 850;

                Widget inputFieldWidget = Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMain,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            border: InputBorder.none,
                            hintText: mode == FetchMode.query
                                ? "WHERE field == 'value' ORDER BY field DESC"
                                : 'Enter exact Document ID...',
                            hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
                          ),
                          onChanged: (val) {
                            ref.read(queryInputProvider.notifier).state = val;
                            if (_isBuilderOpen) {
                              setState(() {}); // Re-render builder sync
                            }
                          },
                          onSubmitted: (_) {
                            ref.read(documentsNotifierProvider.notifier).executeQuery();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.accentBlue),
                        tooltip: 'All Query Operations Guide',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => QueryHelpDialog(
                              onReplaceQuery: (selectedQuery) {
                                _updateQuery(selectedQuery);
                                ref.read(fetchModeProvider.notifier).state = FetchMode.query;
                                if (_isBuilderOpen) setState(() {});
                              },
                              onAppendQuery: (snippet) {
                                _appendQuery(snippet);
                                ref.read(fetchModeProvider.notifier).state = FetchMode.query;
                                if (_isBuilderOpen) setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );

                final children = [
                  // Mode Switch Toggle
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Row(
                      children: [
                        _buildModeTab('Query / Filter', FetchMode.query, mode),
                        _buildModeTab('By Doc ID', FetchMode.byDocId, mode),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Input field (Expanded on wide desktop, sized on narrow test screens)
                  if (isWideScreen)
                    Expanded(child: inputFieldWidget)
                  else
                    SizedBox(width: 280, child: inputFieldWidget),

                  const SizedBox(width: 8),

                  // Visual Builder Toggle Button
                  if (mode == FetchMode.query)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _isBuilderOpen ? AppColors.accentBlue.withValues(alpha: 0.15) : AppColors.bgCard,
                        foregroundColor: _isBuilderOpen ? AppColors.accentBlue : AppColors.textMain,
                        side: BorderSide(color: _isBuilderOpen ? AppColors.accentBlue : AppColors.borderColor),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: Icon(_isBuilderOpen ? Icons.tune : Icons.tune_outlined, size: 14),
                      label: Text(
                        _isBuilderOpen ? 'Hide Builder' : 'Visual Builder',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        setState(() {
                          _isBuilderOpen = !_isBuilderOpen;
                        });
                      },
                    ),
                  const SizedBox(width: 8),

                  // Editable Custom ComboBox Page Limit Selector
                  if (mode == FetchMode.query) ...[
                    const Text('Page Limit:', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(width: 6),
                    CustomComboBox(
                      initialValue: pageSize,
                      onChanged: (newSize) {
                        ref.read(pageSizeProvider.notifier).state = newSize;
                      },
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Execute Query Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Execute Query', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      ref.read(documentsNotifierProvider.notifier).executeQuery();
                    },
                  ),
                ];

                if (isWideScreen) {
                  return Row(children: children);
                } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: children),
                  );
                }
              },
            ),
          ),

          // Collapsible Visual Query Builder Panel (Full Width)
          if (_isBuilderOpen && mode == FetchMode.query)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: VisualQueryBuilder(
                key: ValueKey(_inputController.text),
                initialQuery: _inputController.text,
                onQueryChanged: (newQuery) {
                  _updateQuery(newQuery);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, FetchMode targetMode, FetchMode activeMode) {
    final isSelected = targetMode == activeMode;
    return GestureDetector(
      onTap: () {
        ref.read(fetchModeProvider.notifier).state = targetMode;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bgCard : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.textMain : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
