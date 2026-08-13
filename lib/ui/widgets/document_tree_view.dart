import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_toast.dart';
import '../../models/firestore_document.dart';
import '../../models/query_clause.dart';
import '../../state/document_provider.dart';
import '../../state/service_providers.dart';

class DocumentTreeView extends ConsumerStatefulWidget {
  final FirestoreDocumentModel document;
  final bool isReadOnly;
  final bool hideSubHeader;

  const DocumentTreeView({
    super.key,
    required this.document,
    this.isReadOnly = false,
    this.hideSubHeader = false,
  });

  @override
  ConsumerState<DocumentTreeView> createState() => _DocumentTreeViewState();
}

class _DocumentTreeViewState extends ConsumerState<DocumentTreeView> {
  bool _isProcessing = false;
  String? _treeError;
  final Set<String> _expandedKeys = {};

  String _detectTypeLabel(dynamic val) {
    if (val == null) return 'Null';
    if (val is bool) return 'Boolean';
    if (val is int) return 'Integer';
    if (val is double) return 'Double';
    if (val is String) return 'String';
    if (val is Map<String, dynamic>) {
      if (val['_type'] == 'Timestamp') return 'Timestamp';
      if (val['_type'] == 'GeoPoint' || (val.containsKey('latitude') && val.containsKey('longitude'))) {
        return 'GeoPoint';
      }
      return 'Map';
    }
    if (val is List) return 'Array';
    return 'Object';
  }

  Color _getTypeBadgeColor(String type) {
    switch (type) {
      case 'String':
        return AppColors.accentGreen;
      case 'Integer':
      case 'Double':
        return AppColors.accentBlue;
      case 'Boolean':
        return Colors.purpleAccent;
      case 'Timestamp':
        return AppColors.firebaseGold;
      case 'GeoPoint':
        return Colors.tealAccent;
      case 'Map':
      case 'Array':
        return AppColors.accentOrange;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatLocalIsoWithOffset(DateTime now) {
    final offset = now.timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    final isoWithoutZ = now.toIso8601String().split('.').first;
    return '$isoWithoutZ$sign$hours:$minutes';
  }

  FilterDataType _typeLabelToFilterType(String label) {
    switch (label) {
      case 'Integer':
        return FilterDataType.integer;
      case 'Double':
        return FilterDataType.doubleVal;
      case 'Boolean':
        return FilterDataType.boolean;
      case 'Timestamp':
        return FilterDataType.timestamp;
      case 'GeoPoint':
        return FilterDataType.geoPoint;
      case 'Null':
        return FilterDataType.nullValue;
      default:
        return FilterDataType.string;
    }
  }

  List<dynamic> _parsePathSegments(String path) {
    final normalized = path.replaceAll('.[', '.').replaceAll('[', '.').replaceAll(']', '');
    final parts = normalized.split('.');
    final result = <dynamic>[];
    for (final part in parts) {
      if (part.isEmpty) continue;
      final intVal = int.tryParse(part);
      if (intVal != null) {
        result.add(intVal);
      } else {
        result.add(part);
      }
    }
    return result;
  }

  dynamic _deepCopyJson(dynamic input) {
    if (input is Map) {
      return Map<String, dynamic>.from(
        input.map((k, v) => MapEntry(k.toString(), _deepCopyJson(v))),
      );
    } else if (input is List) {
      return List<dynamic>.from(input.map((v) => _deepCopyJson(v)));
    }
    return input;
  }

  void _setNestedValue(dynamic target, List<dynamic> segments, dynamic newValue) {
    if (segments.isEmpty) return;
    dynamic current = target;
    for (int i = 0; i < segments.length - 1; i++) {
      final seg = segments[i];
      if (seg is int && current is List) {
        current = current[seg];
      } else if (current is Map<String, dynamic>) {
        current = current[seg.toString()];
      }
    }

    final lastSeg = segments.last;
    if (current is List) {
      if (lastSeg is int && lastSeg < current.length) {
        current[lastSeg] = newValue;
      } else {
        current.add(newValue);
      }
    } else if (current is Map<String, dynamic>) {
      current[lastSeg.toString()] = newValue;
    }
  }

  void _deleteNestedKey(dynamic target, List<dynamic> segments) {
    if (segments.isEmpty) return;
    dynamic current = target;
    for (int i = 0; i < segments.length - 1; i++) {
      final seg = segments[i];
      if (seg is int && current is List) {
        current = current[seg];
      } else if (current is Map<String, dynamic>) {
        current = current[seg.toString()];
      }
    }

    final lastSeg = segments.last;
    if (current is List) {
      if (lastSeg is int && lastSeg < current.length) {
        current.removeAt(lastSeg);
      }
    } else if (current is Map<String, dynamic>) {
      current.remove(lastSeg.toString());
    }
  }

  Future<void> _pickDateTime(BuildContext ctx, TextEditingController controller, Function setDialogState) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: ctx,
      initialDate: now,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentBlue,
            surface: AppColors.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    if (!ctx.mounted) return;

    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentBlue,
            surface: AppColors.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute).toUtc();
    setDialogState(() {
      controller.text = dt.toIso8601String();
    });
  }

  Future<void> _deleteField(String fieldPath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete Field', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete field "$fieldPath"?\nThis operation cannot be undone.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Field', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
      _treeError = null;
    });

    try {
      debugPrint('[DocumentTreeView] Deleting field "$fieldPath"...');
      final service = ref.read(firestoreDataServiceProvider);
      final segments = _parsePathSegments(fieldPath);
      final hasArray = segments.any((s) => s is int);

      final FirestoreDocumentModel updatedDoc;
      if (hasArray) {
        final rootField = segments.first.toString();
        final docCopy = _deepCopyJson(widget.document.data) as Map<String, dynamic>;
        _deleteNestedKey(docCopy, segments);

        updatedDoc = await service.updateSingleField(
          documentPath: widget.document.path,
          fieldPath: rootField,
          fieldValue: docCopy[rootField],
        );
      } else {
        updatedDoc = await service.deleteSingleField(
          documentPath: widget.document.path,
          fieldPath: fieldPath,
        );
      }

      ref.read(selectedDocumentProvider.notifier).state = updatedDoc;
      AppToast.showSuccess('Field "$fieldPath" deleted successfully!');
    } catch (e) {
      debugPrint('[DocumentTreeView ERROR] Failed to delete field "$fieldPath": $e');
      setState(() => _treeError = 'Failed to delete field "$fieldPath": $e');
      AppToast.showError('Failed to delete field "$fieldPath": $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showAddFieldDialog({String parentPath = ''}) async {
    final keyController = TextEditingController();
    final valController = TextEditingController();
    final latController = TextEditingController(text: '37.7749');
    final lngController = TextEditingController(text: '-122.4194');
    FilterDataType selectedDataType = FilterDataType.string;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.borderColor),
          ),
          title: Row(
            children: [
              const Icon(Icons.add_box, color: AppColors.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                parentPath.isEmpty ? 'Add Single Field' : 'Add Child to "$parentPath"',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Field Name *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
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
                    controller: keyController,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: 'e.g. status, score, location',
                      hintStyle: TextStyle(color: AppColors.textDim, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Text('Data Type: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent && event.character != null && event.character!.isNotEmpty) {
                          final char = event.character!.toLowerCase();
                          final match = FilterDataType.values.firstWhere(
                            (type) => type.label.toLowerCase().startsWith(char),
                            orElse: () => selectedDataType,
                          );
                          if (match != selectedDataType) {
                            setDialogState(() {
                              selectedDataType = match;
                              if (match == FilterDataType.timestamp) {
                                valController.text = DateTime.now().toUtc().toIso8601String();
                              }
                            });
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: DropdownButton<FilterDataType>(
                        value: selectedDataType,
                        enableFeedback: true,
                        dropdownColor: AppColors.bgCard,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMain),
                        underline: const SizedBox(),
                        items: FilterDataType.values.map((type) {
                          return DropdownMenuItem<FilterDataType>(
                            value: type,
                            child: Text(type.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedDataType = val;
                              if (val == FilterDataType.timestamp) {
                                valController.text = DateTime.now().toUtc().toIso8601String();
                              } else if (val == FilterDataType.boolean) {
                                valController.text = 'true';
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Specialized Input Controls
                if (selectedDataType == FilterDataType.timestamp) ...[
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accentBlue)),
                        icon: const Icon(Icons.calendar_today, size: 14, color: AppColors.accentBlue),
                        label: const Text('Pick Date & Time', style: TextStyle(fontSize: 11, color: AppColors.accentBlue)),
                        onPressed: () => _pickDateTime(ctx, valController, setDialogState),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.firebaseGold)),
                        onPressed: () => setDialogState(() {
                          valController.text = DateTime.now().toUtc().toIso8601String();
                        }),
                        child: const Text('Now (UTC)', style: TextStyle(fontSize: 10, color: AppColors.firebaseGold)),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accentOrange)),
                        onPressed: () => setDialogState(() {
                          valController.text = _formatLocalIsoWithOffset(DateTime.now());
                        }),
                        child: const Text('Now (+Offset)', style: TextStyle(fontSize: 10, color: AppColors.accentOrange)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: TextField(
                      controller: valController,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ] else if (selectedDataType == FilterDataType.geoPoint) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Latitude (-90 to 90)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.bgInput,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.borderColor),
                              ),
                              child: TextField(
                                controller: latController,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontFamily: 'monospace'),
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Longitude (-180 to 180)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.bgInput,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.borderColor),
                              ),
                              child: TextField(
                                controller: lngController,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontFamily: 'monospace'),
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (selectedDataType == FilterDataType.boolean) ...[
                  const Text('Boolean Value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  SegmentedButton<bool>(
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.accentBlue
                            : AppColors.bgInput,
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
                        label: Text('true', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        icon: Icon(Icons.check_circle_outline, size: 14),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('false', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        icon: Icon(Icons.cancel_outlined, size: 14),
                      ),
                    ],
                    selected: {valController.text.toLowerCase() == 'true'},
                    onSelectionChanged: (newSelection) {
                      setDialogState(() {
                        valController.text = newSelection.first.toString();
                      });
                    },
                  ),
                ] else ...[
                  const Text('Field Value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    height: 70,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: TextField(
                      controller: valController,
                      maxLines: null,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: 'Enter field value...',
                        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],

                if (dialogError != null) ...[
                  const SizedBox(height: 8),
                  Text(dialogError!, style: const TextStyle(color: AppColors.accentRed, fontSize: 11)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
              onPressed: () async {
                final key = keyController.text.trim();
                if (key.isEmpty) {
                  setDialogState(() => dialogError = 'Field Name is required.');
                  return;
                }

                final fullFieldPath = parentPath.isEmpty ? key : '$parentPath.$key';
                dynamic parsedVal;
                final raw = valController.text.trim();

                try {
                  switch (selectedDataType) {
                    case FilterDataType.string:
                      parsedVal = raw;
                      break;
                    case FilterDataType.integer:
                      parsedVal = int.parse(raw);
                      break;
                    case FilterDataType.doubleVal:
                      parsedVal = double.parse(raw);
                      break;
                    case FilterDataType.boolean:
                      parsedVal = raw.toLowerCase() == 'true';
                      break;
                    case FilterDataType.timestamp:
                      parsedVal = {
                        '_type': 'Timestamp',
                        'value': raw,
                      };
                      break;
                    case FilterDataType.geoPoint:
                      final lat = double.parse(latController.text.trim());
                      final lng = double.parse(lngController.text.trim());
                      if (lat < -90 || lat > 90) throw 'Latitude must be between -90 and 90';
                      if (lng < -180 || lng > 180) throw 'Longitude must be between -180 and 180';
                      parsedVal = {
                        '_type': 'GeoPoint',
                        'latitude': lat,
                        'longitude': lng,
                      };
                      break;
                    case FilterDataType.nullValue:
                      parsedVal = null;
                      break;
                    default:
                      parsedVal = raw;
                  }
                } catch (e) {
                  setDialogState(() => dialogError = 'Invalid value for ${selectedDataType.label}: $e');
                  return;
                }

                Navigator.of(ctx).pop();
                setState(() => _isProcessing = true);
                try {
                  debugPrint('[DocumentTreeView] Adding field "$fullFieldPath"...');
                  final service = ref.read(firestoreDataServiceProvider);
                  final segments = _parsePathSegments(fullFieldPath);
                  final hasArray = segments.any((s) => s is int);

                  final FirestoreDocumentModel updatedDoc;
                  if (hasArray) {
                    final rootField = segments.first.toString();
                    final docCopy = _deepCopyJson(widget.document.data) as Map<String, dynamic>;
                    _setNestedValue(docCopy, segments, parsedVal);

                    updatedDoc = await service.updateSingleField(
                      documentPath: widget.document.path,
                      fieldPath: rootField,
                      fieldValue: docCopy[rootField],
                    );
                  } else {
                    updatedDoc = await service.updateSingleField(
                      documentPath: widget.document.path,
                      fieldPath: fullFieldPath,
                      fieldValue: parsedVal,
                    );
                  }
                  ref.read(selectedDocumentProvider.notifier).state = updatedDoc;
                  AppToast.showSuccess('Field "$fullFieldPath" added successfully!');
                } catch (e) {
                  debugPrint('[DocumentTreeView ERROR] Failed to add field "$fullFieldPath": $e');
                  setState(() => _treeError = 'Failed to add field "$fullFieldPath": $e');
                  AppToast.showError('Failed to add field "$fullFieldPath": $e');
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              child: const Text('Add Field', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditFieldDialog(String fieldPath, dynamic currentValue) async {
    final typeLabel = _detectTypeLabel(currentValue);
    FilterDataType selectedDataType = _typeLabelToFilterType(typeLabel);

    String initialText = '';
    String initialLat = '37.7749';
    String initialLng = '-122.4194';

    if (currentValue is Map<String, dynamic> && currentValue['_type'] == 'Timestamp') {
      initialText = currentValue['value']?.toString() ?? '';
    } else if (currentValue is Map<String, dynamic> && currentValue['_type'] == 'GeoPoint') {
      initialLat = currentValue['latitude']?.toString() ?? '37.7749';
      initialLng = currentValue['longitude']?.toString() ?? '-122.4194';
    } else if (currentValue != null) {
      initialText = currentValue.toString();
    }

    final valController = TextEditingController(text: initialText);
    final latController = TextEditingController(text: initialLat);
    final lngController = TextEditingController(text: initialLng);
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.borderColor),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit, color: AppColors.accentBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Modify Field "$fieldPath"',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Data Type: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent && event.character != null && event.character!.isNotEmpty) {
                          final char = event.character!.toLowerCase();
                          final match = FilterDataType.values.firstWhere(
                            (type) => type.label.toLowerCase().startsWith(char),
                            orElse: () => selectedDataType,
                          );
                          if (match != selectedDataType) {
                            setDialogState(() {
                              selectedDataType = match;
                              if (match == FilterDataType.timestamp && valController.text.isEmpty) {
                                valController.text = DateTime.now().toUtc().toIso8601String();
                              }
                            });
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: DropdownButton<FilterDataType>(
                        value: selectedDataType,
                        enableFeedback: true,
                        dropdownColor: AppColors.bgCard,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMain),
                        underline: const SizedBox(),
                        items: FilterDataType.values.map((type) {
                          return DropdownMenuItem<FilterDataType>(
                            value: type,
                            child: Text(type.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedDataType = val;
                              if (val == FilterDataType.timestamp && valController.text.isEmpty) {
                                valController.text = DateTime.now().toUtc().toIso8601String();
                              } else if (val == FilterDataType.boolean && valController.text != 'true' && valController.text != 'false') {
                                valController.text = 'true';
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Specialized Input Controls
                if (selectedDataType == FilterDataType.timestamp) ...[
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accentBlue)),
                        icon: const Icon(Icons.calendar_today, size: 14, color: AppColors.accentBlue),
                        label: const Text('Pick Date & Time', style: TextStyle(fontSize: 11, color: AppColors.accentBlue)),
                        onPressed: () => _pickDateTime(ctx, valController, setDialogState),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.firebaseGold)),
                        onPressed: () => setDialogState(() {
                          valController.text = DateTime.now().toUtc().toIso8601String();
                        }),
                        child: const Text('Now (UTC)', style: TextStyle(fontSize: 10, color: AppColors.firebaseGold)),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accentOrange)),
                        onPressed: () => setDialogState(() {
                          valController.text = _formatLocalIsoWithOffset(DateTime.now());
                        }),
                        child: const Text('Now (+Offset)', style: TextStyle(fontSize: 10, color: AppColors.accentOrange)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: TextField(
                      controller: valController,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontFamily: 'monospace'),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                    ),
                  ),
                ] else if (selectedDataType == FilterDataType.geoPoint) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Latitude (-90 to 90)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.bgInput,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.borderColor),
                              ),
                              child: TextField(
                                controller: latController,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontFamily: 'monospace'),
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Longitude (-180 to 180)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.bgInput,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.borderColor),
                              ),
                              child: TextField(
                                controller: lngController,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontFamily: 'monospace'),
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (selectedDataType == FilterDataType.boolean) ...[
                  const Text('Boolean Value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  SegmentedButton<bool>(
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.accentBlue
                            : AppColors.bgInput,
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
                        label: Text('true', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        icon: Icon(Icons.check_circle_outline, size: 14),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('false', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        icon: Icon(Icons.cancel_outlined, size: 14),
                      ),
                    ],
                    selected: {valController.text.toLowerCase() == 'true'},
                    onSelectionChanged: (newSelection) {
                      setDialogState(() {
                        valController.text = newSelection.first.toString();
                      });
                    },
                  ),
                ] else ...[
                  const Text('Field Value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    height: 80,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: TextField(
                      controller: valController,
                      maxLines: null,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: 'Enter new field value...',
                        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],

                if (dialogError != null) ...[
                  const SizedBox(height: 8),
                  Text(dialogError!, style: const TextStyle(color: AppColors.accentRed, fontSize: 11)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
              onPressed: () async {
                dynamic parsedVal;
                final raw = valController.text.trim();
                try {
                  switch (selectedDataType) {
                    case FilterDataType.string:
                      parsedVal = raw;
                      break;
                    case FilterDataType.integer:
                      parsedVal = int.parse(raw);
                      break;
                    case FilterDataType.doubleVal:
                      parsedVal = double.parse(raw);
                      break;
                    case FilterDataType.boolean:
                      parsedVal = raw.toLowerCase() == 'true';
                      break;
                    case FilterDataType.timestamp:
                      parsedVal = {
                        '_type': 'Timestamp',
                        'value': raw,
                      };
                      break;
                    case FilterDataType.geoPoint:
                      final lat = double.parse(latController.text.trim());
                      final lng = double.parse(lngController.text.trim());
                      if (lat < -90 || lat > 90) throw 'Latitude must be between -90 and 90';
                      if (lng < -180 || lng > 180) throw 'Longitude must be between -180 and 180';
                      parsedVal = {
                        '_type': 'GeoPoint',
                        'latitude': lat,
                        'longitude': lng,
                      };
                      break;
                    case FilterDataType.nullValue:
                      parsedVal = null;
                      break;
                    default:
                      parsedVal = raw;
                  }
                } catch (e) {
                  setDialogState(() => dialogError = 'Invalid value for ${selectedDataType.label}: $e');
                  return;
                }

                Navigator.of(ctx).pop();
                setState(() => _isProcessing = true);
                try {
                  debugPrint('[DocumentTreeView] Updating field "$fieldPath"...');
                  final service = ref.read(firestoreDataServiceProvider);
                  final segments = _parsePathSegments(fieldPath);
                  final hasArray = segments.any((s) => s is int);

                  final FirestoreDocumentModel updatedDoc;
                  if (hasArray) {
                    final rootField = segments.first.toString();
                    final docCopy = _deepCopyJson(widget.document.data) as Map<String, dynamic>;
                    _setNestedValue(docCopy, segments, parsedVal);

                    updatedDoc = await service.updateSingleField(
                      documentPath: widget.document.path,
                      fieldPath: rootField,
                      fieldValue: docCopy[rootField],
                    );
                  } else {
                    updatedDoc = await service.updateSingleField(
                      documentPath: widget.document.path,
                      fieldPath: fieldPath,
                      fieldValue: parsedVal,
                    );
                  }
                  ref.read(selectedDocumentProvider.notifier).state = updatedDoc;
                  AppToast.showSuccess('Field "$fieldPath" updated successfully!');
                } catch (e) {
                  debugPrint('[DocumentTreeView ERROR] Failed to update field "$fieldPath": $e');
                  setState(() => _treeError = 'Failed to update field "$fieldPath": $e');
                  AppToast.showError('Failed to update field "$fieldPath": $e');
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              child: const Text('Save Field', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow(String key, dynamic value, bool isReadOnly, {String path = '', double depth = 0}) {
    final fieldPath = path.isEmpty ? key : '$path.$key';
    final typeLabel = _detectTypeLabel(value);
    final badgeColor = _getTypeBadgeColor(typeLabel);

    final isMapOrArray = (value is Map<String, dynamic> && value['_type'] == null) || (value is List && value.isNotEmpty);
    final isExpanded = _expandedKeys.contains(fieldPath);

    String valueDisplay;
    if (value is Map<String, dynamic> && value['_type'] == 'Timestamp') {
      valueDisplay = value['value']?.toString() ?? '';
    } else if (value is Map<String, dynamic> && value['_type'] == 'GeoPoint') {
      valueDisplay = 'Lat: ${value['latitude']}, Lng: ${value['longitude']}';
    } else if (value is Map<String, dynamic>) {
      valueDisplay = '{${value.length} fields}';
    } else if (value is List) {
      valueDisplay = '[${value.length} items]';
    } else {
      valueDisplay = value.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: EdgeInsets.only(left: 12 + depth, right: 12, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            children: [
              if (isMapOrArray)
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedKeys.remove(fieldPath);
                      } else {
                        _expandedKeys.add(fieldPath);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),

              // Key Name
              Text(
                key,
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMain),
              ),
              const SizedBox(width: 8),

              // Type Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
              const SizedBox(width: 12),

              // Value Display
              Expanded(
                child: Text(
                  valueDisplay,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textMuted),
                ),
              ),

              // Actions in Edit Mode
              if (!isReadOnly) ...[
                if (isMapOrArray)
                  IconButton(
                    icon: const Icon(Icons.add, size: 16, color: AppColors.accentBlue),
                    tooltip: 'Add child field to "$fieldPath"',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: _isProcessing ? null : () => _showAddFieldDialog(parentPath: fieldPath),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.accentBlue),
                    tooltip: 'Modify field "$fieldPath"',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: _isProcessing ? null : () => _showEditFieldDialog(fieldPath, value),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.accentRed),
                  tooltip: 'Delete field "$fieldPath"',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: _isProcessing ? null : () => _deleteField(fieldPath),
                ),
              ],
            ],
          ),
        ),

        // Expanded Nested Sub-Tree Children
        if (isExpanded) ...[
          if (value is Map<String, dynamic>)
            ...value.entries
                .where((e) => e.key != '_type')
                .map((e) => _buildFieldRow(e.key, e.value, isReadOnly, path: fieldPath, depth: depth + 16)),
          if (value is List)
            ...value.asMap().entries.map((e) => _buildFieldRow('[${e.key}]', e.value, isReadOnly, path: fieldPath, depth: depth + 16)),
        ],
      ],
    );
  }

  void showAddFieldDialog([String? parentPath]) {
    _showAddFieldDialog(parentPath: parentPath ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = widget.isReadOnly;
    final entries = widget.document.data.entries.toList();

    return Column(
      children: [
        // Sub-header for Tree View Actions
        if (!widget.hideSubHeader) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black.withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FIELDS (${entries.length})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                ),
                if (!isReadOnly)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add Single Field', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: _isProcessing ? null : () => _showAddFieldDialog(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],

        if (_treeError != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: AppColors.accentRed.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: AppColors.accentRed),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    _treeError!,
                    style: const TextStyle(color: AppColors.accentRed, fontSize: 11, fontFamily: 'monospace'),
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
                    Clipboard.setData(ClipboardData(text: _treeError!));
                    AppToast.showInfo('Error message copied to clipboard!');
                  },
                ),
              ],
            ),
          ),

        // Tree Fields List
        Expanded(
          child: entries.isEmpty
              ? const Center(
                  child: Text(
                    'No fields in document',
                    style: TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _buildFieldRow(entry.key, entry.value, isReadOnly);
                  },
                ),
        ),
      ],
    );
  }
}
