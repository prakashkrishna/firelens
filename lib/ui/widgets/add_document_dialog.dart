import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_toast.dart';
import '../../models/gcp_project.dart';
import '../../models/firestore_database.dart';
import '../../state/document_provider.dart';
import '../../state/service_providers.dart';

class AddDocumentDialog extends ConsumerStatefulWidget {
  final GcpProject project;
  final FirestoreDatabase database;
  final String collectionId;

  const AddDocumentDialog({
    super.key,
    required this.project,
    required this.database,
    required this.collectionId,
  });

  @override
  ConsumerState<AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends ConsumerState<AddDocumentDialog> {
  final _documentIdController = TextEditingController();
  late TextEditingController _jsonController;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController(text: "{\n}");
  }

  @override
  void dispose() {
    _documentIdController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  String _formatLocalIsoWithOffset(DateTime now) {
    final offset = now.timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    final isoWithoutZ = now.toIso8601String().split('.').first;
    return '$isoWithoutZ$sign$hours:$minutes';
  }

  void _insertSnippet(String baseKey, dynamic value) {
    try {
      final decoded = jsonDecode(_jsonController.text) as Map<String, dynamic>;
      String targetKey = baseKey;
      int count = 1;
      while (decoded.containsKey(targetKey)) {
        targetKey = '${baseKey}_$count';
        count++;
      }
      decoded[targetKey] = value;
      setState(() {
        _jsonController.text = const JsonEncoder.withIndent('  ').convert(decoded);
      });
    } catch (_) {
      setState(() {
        _jsonController.text = const JsonEncoder.withIndent('  ').convert({baseKey: value});
      });
    }
  }

  Future<void> _submit() async {
    final docId = _documentIdController.text.trim();
    final jsonStr = _jsonController.text.trim();

    Map<String, dynamic> jsonMap;
    try {
      jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      setState(() => _errorMessage = 'Invalid JSON: $e');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(firestoreDataServiceProvider);
      final createdDoc = await service.createDocument(
        projectId: widget.project.projectId,
        databaseId: widget.database.databaseId,
        collectionId: widget.collectionId,
        documentId: docId.isNotEmpty ? docId : null,
        jsonData: jsonMap,
      );

      // Add newly created document to state
      ref.read(documentsNotifierProvider.notifier).addCreatedDocument(
            widget.project.projectId,
            widget.database.databaseId,
            widget.collectionId,
            createdDoc,
          );

      if (mounted) {
        Navigator.of(context).pop();
        AppToast.showSuccess(context, 'Document "${createdDoc.id}" created successfully!');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to create document: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderColor),
      ),
      title: Row(
        children: [
          const Icon(Icons.note_add, color: AppColors.accentBlue, size: 20),
          const SizedBox(width: 8),
          Text(
            'Add Document to "${widget.collectionId}"',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Document ID (Optional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: TextField(
                  controller: _documentIdController,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    hintText: 'Leave blank for auto-generated ID',
                    hintStyle: TextStyle(color: AppColors.textDim, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Document Data (JSON)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: AppColors.accentBlue),
                        ),
                        icon: const Icon(Icons.access_time, size: 12, color: AppColors.accentBlue),
                        label: const Text('+ Timestamp', style: TextStyle(fontSize: 11, color: AppColors.accentBlue)),
                        onPressed: () => _insertSnippet('timestamp', {
                          '_type': 'Timestamp',
                          'value': DateTime.now().toUtc().toIso8601String(),
                        }),
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: AppColors.accentOrange),
                        ),
                        icon: const Icon(Icons.access_time_filled, size: 12, color: AppColors.accentOrange),
                        label: const Text('+ Offset TS', style: TextStyle(fontSize: 11, color: AppColors.accentOrange)),
                        onPressed: () => _insertSnippet('timestamp', {
                          '_type': 'Timestamp',
                          'value': _formatLocalIsoWithOffset(DateTime.now()),
                        }),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: AppColors.firebaseGold),
                        ),
                        icon: const Icon(Icons.location_on, size: 12, color: AppColors.firebaseGold),
                        label: const Text('+ GeoPoint', style: TextStyle(fontSize: 11, color: AppColors.firebaseGold)),
                        onPressed: () => _insertSnippet('location', {
                          '_type': 'GeoPoint',
                          'latitude': 37.7749,
                          'longitude': -122.4194,
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 260,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: TextField(
                  controller: _jsonController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.5, color: AppColors.textMain),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.accentRed, fontSize: 11)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: _isSubmitting
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check, size: 14),
          label: const Text('Create Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }
}
