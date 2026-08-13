import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_toast.dart';
import '../../state/document_provider.dart';
import '../../state/service_providers.dart';
import 'document_tree_view.dart';
import 'json_text_editing_controller.dart';

class JsonEditorPane extends ConsumerStatefulWidget {
  const JsonEditorPane({super.key});

  @override
  ConsumerState<JsonEditorPane> createState() => _JsonEditorPaneState();
}

class _JsonEditorPaneState extends ConsumerState<JsonEditorPane> {
  late JsonTextEditingController _docTextController;
  final GlobalKey<State<DocumentTreeView>> _treeKey = GlobalKey();

  bool _isSaving = false;
  String? _errorMessage;
  bool _isTreeView = true; // Default to Tree View
  bool _isEditMode = false; // Default Edit Mode to OFF (Read-Only)

  @override
  void initState() {
    super.initState();
    _docTextController = JsonTextEditingController();
  }

  @override
  void dispose() {
    _docTextController.dispose();
    super.dispose();
  }

  void _syncDocText(String newText) {
    if (_docTextController.text != newText) {
      _docTextController.text = newText;
    }
  }

  Future<void> _saveChanges() async {
    final selectedDoc = ref.read(selectedDocumentProvider);
    if (selectedDoc == null) return;

    // Pre-save JSON Syntax Validation
    Map<String, dynamic> updatedFields;
    try {
      updatedFields = jsonDecode(_docTextController.text) as Map<String, dynamic>;
    } catch (e) {
      setState(() {
        _errorMessage = 'Syntax Error: Invalid JSON format. Cannot save document.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(firestoreDataServiceProvider);
      final updatedDoc = await service.saveDocument(
        documentPath: selectedDoc.path,
        jsonData: updatedFields,
      );

      // Update provider state with edited document
      ref.read(selectedDocumentProvider.notifier).state = updatedDoc;

      if (mounted) {
        AppToast.showSuccess(context, 'Document saved successfully!');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save document: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDoc = ref.watch(selectedDocumentProvider);

    if (selectedDoc == null) {
      return Container(
        color: AppColors.bgDark,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_outlined, size: 48, color: AppColors.textDim),
              SizedBox(height: 12),
              Text(
                'No Document Selected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Select a document from the left list to view or edit its fields.',
                style: TextStyle(fontSize: 12, color: AppColors.textDim),
              ),
            ],
          ),
        ),
      );
    }

    // Keep text controller synchronized with current document
    _syncDocText(selectedDoc.toFormattedJson());

    return Container(
      color: AppColors.bgDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header: Document ID & Edit Mode Toggle Pane
          Container(
            width: double.infinity,
            color: AppColors.bgSidebar,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left-Aligned Document Label
                  const Text('Document: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.firebaseGold, fontSize: 12)),
                  SelectableText(
                    selectedDoc.id,
                    style: const TextStyle(fontFamily: 'monospace', color: AppColors.textMain, fontSize: 12),
                  ),
                  const SizedBox(width: 12),

                  // Interactive Edit Mode Toggle Badge (OFF by default)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isEditMode = !_isEditMode;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Tooltip(
                      message: _isEditMode ? 'Click to switch to Read-Only Mode' : 'Click to enable Edit Mode',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isEditMode ? AppColors.accentOrange.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _isEditMode ? AppColors.accentOrange : AppColors.borderColor,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isEditMode ? Icons.edit_note : Icons.lock_outline,
                              size: 14,
                              color: _isEditMode ? AppColors.accentOrange : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isEditMode ? 'Edit Mode ON' : 'Read-Only',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isEditMode ? AppColors.accentOrange : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Action Buttons
                  // Copy Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMain,
                      side: const BorderSide(color: AppColors.borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy JSON', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: selectedDoc.toFormattedJson()));
                      AppToast.showInfo(context, 'Document JSON copied to clipboard');
                    },
                  ),
                  const SizedBox(width: 8),

                  // Paste Button (Raw JSON mode & Edit Mode active)
                  if (_isEditMode && !_isTreeView) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentBlue,
                        side: const BorderSide(color: AppColors.accentBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.paste_rounded, size: 14),
                      label: const Text('Paste JSON', style: TextStyle(fontSize: 11)),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data != null && data.text != null && data.text!.isNotEmpty) {
                          try {
                            final decoded = jsonDecode(data.text!);
                            final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
                            setState(() {
                              _docTextController.text = formatted;
                            });
                            if (context.mounted) {
                              AppToast.showInfo(context, 'Pasted formatted JSON into editor');
                            }
                          } catch (_) {
                            setState(() {
                              _docTextController.text = data.text!;
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Save Changes Button (Edit Mode active)
                  if (_isEditMode)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.firebaseGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 0,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.save_outlined, size: 14),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : _saveChanges,
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // 2. Sub-Header Pane: Fields Count, TreeView / Raw JSON Switcher & Add Field Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Colors.black.withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _isTreeView ? 'FIELDS (${selectedDoc.data.length})' : 'RAW JSON DATA',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // View Mode Switcher Segmented Button (Moved Below)
                    SegmentedButton<bool>(
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) => states.contains(WidgetState.selected)
                              ? AppColors.accentBlue
                              : AppColors.bgCard,
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) => states.contains(WidgetState.selected)
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                        iconColor: WidgetStateProperty.resolveWith<Color>(
                          (states) => states.contains(WidgetState.selected)
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                        side: WidgetStateProperty.all(const BorderSide(color: AppColors.borderColor)),
                      ),
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Tree View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          icon: Icon(Icons.account_tree_outlined, size: 14),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Raw JSON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          icon: Icon(Icons.code, size: 14),
                        ),
                      ],
                      selected: {_isTreeView},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _isTreeView = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),

                // Add Single Field Button (Tree View & Edit Mode active)
                if (_isTreeView && _isEditMode)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add Single Field', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      (_treeKey.currentState as dynamic)?.showAddFieldDialog();
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Error Banner (if any syntax or save error occurs)
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.accentRed.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.accentRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: AppColors.accentRed, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentRed,
                      side: BorderSide(color: AppColors.accentRed.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(60, 28),
                    ),
                    icon: const Icon(Icons.copy, size: 12),
                    label: const Text('Copy Error', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _errorMessage!));
                      AppToast.showInfo('Error message copied to clipboard!');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14, color: AppColors.accentRed),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),

          // 3. Content Body: Tree View or Raw Highlighting JSON Editor
          Expanded(
            child: _isTreeView
                ? DocumentTreeView(
                    key: _treeKey,
                    document: selectedDoc,
                    isReadOnly: !_isEditMode,
                    hideSubHeader: true,
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.bgDark,
                    child: Column(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _docTextController,
                            readOnly: !_isEditMode,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: AppColors.textMain,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              fillColor: AppColors.bgInput,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: AppColors.borderColor),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
