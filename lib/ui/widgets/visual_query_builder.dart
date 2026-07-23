import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_toast.dart';
import '../../models/query_clause.dart';

class VisualQueryBuilder extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<String> onQueryChanged;

  const VisualQueryBuilder({
    super.key,
    required this.initialQuery,
    required this.onQueryChanged,
  });

  @override
  State<VisualQueryBuilder> createState() => _VisualQueryBuilderState();
}

class _VisualQueryBuilderState extends State<VisualQueryBuilder> {
  final List<FilterClause> _filters = [];
  final List<SortClause> _sorts = [];

  static const List<String> _operators = [
    '==',
    '!=',
    '>',
    '>=',
    '<',
    '<=',
    'array-contains',
    'array-contains-any',
    'in',
    'not-in',
  ];

  @override
  void initState() {
    super.initState();
    _parseInitialQuery();
  }

  void _parseInitialQuery() {
    final parsed = QueryParser.parse(widget.initialQuery);
    _filters.clear();
    _sorts.clear();
    _filters.addAll(parsed.filters);
    _sorts.addAll(parsed.sorts);
  }

  void _notifyChange() {
    final queryString = QueryParser.stringify(_filters, _sorts);
    widget.onQueryChanged(queryString);
  }

  void _showDataTypeInfoDialog(
    BuildContext context,
    FilterDataType dataType,
    ValueChanged<String> onUseSample,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.borderColor),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.accentBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              '${dataType.label} Data Type',
              style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dataType.description,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Text(
                'EXAMPLE SYNTAX:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.firebaseGold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              if (dataType == FilterDataType.timestamp) ...[
                _buildExampleCard(
                  context,
                  label: 'UTC Format (ending in Z)',
                  sample: '2026-07-22T20:00:00Z',
                  onUseSample: onUseSample,
                ),
                const SizedBox(height: 8),
                _buildExampleCard(
                  context,
                  label: 'Timezone Offset Format (+05:30)',
                  sample: '2026-07-22T22:30:00+05:30',
                  onUseSample: onUseSample,
                ),
              ] else ...[
                _buildExampleCard(
                  context,
                  label: 'Standard Format',
                  sample: dataType.example,
                  onUseSample: onUseSample,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context, {
    required String label,
    required String sample,
    required ValueChanged<String> onUseSample,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  sample,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 14, color: AppColors.textMain),
                tooltip: 'Copy Example',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sample));
                  AppToast.showInfo(context, 'Example copied to clipboard');
                },
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  onUseSample(sample);
                  Navigator.of(context).pop();
                },
                child: const Text('Use', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Clauses Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.filter_alt, size: 14, color: AppColors.firebaseGold),
                  SizedBox(width: 6),
                  Text(
                    'FILTER CONDITIONS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, size: 14, color: AppColors.accentBlue),
                label: const Text('Add Filter', style: TextStyle(fontSize: 11, color: AppColors.accentBlue)),
                onPressed: () {
                  setState(() {
                    _filters.add(FilterClause(field: '', operator: '==', value: '', dataType: FilterDataType.string));
                  });
                  _notifyChange();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (_filters.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'No filter conditions added. Click "+ Add Filter".',
                style: TextStyle(fontSize: 11, color: AppColors.textDim),
              ),
            ),

          ..._filters.asMap().entries.map((entry) {
            final idx = entry.key;
            final filter = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  // Field input
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: TextField(
                        controller: TextEditingController(text: filter.field)
                          ..selection = TextSelection.collapsed(offset: filter.field.length),
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMain),
                        decoration: const InputDecoration(
                          hintText: 'Field (e.g. status)',
                          hintStyle: TextStyle(color: AppColors.textDim, fontSize: 11),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                        ),
                        onChanged: (val) {
                          filter.field = val;
                          _notifyChange();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Operator Dropdown
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _operators.contains(filter.operator) ? filter.operator : '==',
                        focusNode: FocusNode(),
                        enableFeedback: true,
                        dropdownColor: AppColors.bgCard,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.firebaseGold),
                        isDense: true,
                        items: _operators.map((op) {
                          return DropdownMenuItem<String>(
                            value: op,
                            child: Text(op),
                          );
                        }).toList(),
                        onChanged: (op) {
                          if (op != null) {
                            setState(() {
                              filter.operator = op;
                            });
                            _notifyChange();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Data Type Selector Dropdown
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent && event.character != null && event.character!.isNotEmpty) {
                            final char = event.character!.toLowerCase();
                            final match = FilterDataType.values.firstWhere(
                              (type) => type.label.toLowerCase().startsWith(char),
                              orElse: () => filter.dataType,
                            );
                            if (match != filter.dataType) {
                              setState(() {
                                filter.dataType = match;
                                if (match == FilterDataType.boolean && filter.value != 'true' && filter.value != 'false') {
                                  filter.value = 'true';
                                } else if (match == FilterDataType.nullValue) {
                                  filter.value = 'null';
                                }
                              });
                              _notifyChange();
                              return KeyEventResult.handled;
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: DropdownButton<FilterDataType>(
                          value: filter.dataType,
                          enableFeedback: true,
                          dropdownColor: AppColors.bgCard,
                          style: const TextStyle(fontSize: 11, color: AppColors.accentBlue, fontWeight: FontWeight.w600),
                          isDense: true,
                          items: FilterDataType.values.map((type) {
                            return DropdownMenuItem<FilterDataType>(
                              value: type,
                              child: Text(type.label),
                            );
                          }).toList(),
                          onChanged: (type) {
                            if (type != null) {
                              setState(() {
                                filter.dataType = type;
                                if (type == FilterDataType.boolean && filter.value != 'true' && filter.value != 'false') {
                                  filter.value = 'true';
                                } else if (type == FilterDataType.nullValue) {
                                  filter.value = 'null';
                                }
                              });
                              _notifyChange();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Data Type Info & Sample Copy Button (Option A)
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 15, color: AppColors.accentBlue),
                    tooltip: '${filter.dataType.label} Type Info & Examples',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                    onPressed: () {
                      _showDataTypeInfoDialog(context, filter.dataType, (sampleValue) {
                        setState(() {
                          filter.value = sampleValue;
                        });
                        _notifyChange();
                      });
                    },
                  ),
                  const SizedBox(width: 6),

                  // Value Widget (Contextual based on DataType)
                  Expanded(
                    flex: 3,
                    child: _buildValueWidget(filter),
                  ),
                  const SizedBox(width: 6),

                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.accentRed),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    onPressed: () {
                      setState(() {
                        _filters.removeAt(idx);
                      });
                      _notifyChange();
                    },
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Sort Clauses Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.sort, size: 14, color: AppColors.firebaseGold),
                  SizedBox(width: 6),
                  Text(
                    'SORTING ORDER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, size: 14, color: AppColors.accentBlue),
                label: const Text('Add Sort', style: TextStyle(fontSize: 11, color: AppColors.accentBlue)),
                onPressed: () {
                  setState(() {
                    _sorts.add(SortClause(field: '', direction: 'ASC'));
                  });
                  _notifyChange();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (_sorts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'No sorting added. Click "+ Add Sort".',
                style: TextStyle(fontSize: 11, color: AppColors.textDim),
              ),
            ),

          ..._sorts.asMap().entries.map((entry) {
            final idx = entry.key;
            final sort = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: TextField(
                        controller: TextEditingController(text: sort.field)
                          ..selection = TextSelection.collapsed(offset: sort.field.length),
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMain),
                        decoration: const InputDecoration(
                          hintText: 'Sort field (e.g. createdAt)',
                          hintStyle: TextStyle(color: AppColors.textDim, fontSize: 11),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                        ),
                        onChanged: (val) {
                          sort.field = val;
                          _notifyChange();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: sort.direction,
                        focusNode: FocusNode(),
                        enableFeedback: true,
                        dropdownColor: AppColors.bgCard,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.firebaseGold),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 'ASC', child: Text('ASC')),
                          DropdownMenuItem(value: 'DESC', child: Text('DESC')),
                        ],
                        onChanged: (dir) {
                          if (dir != null) {
                            setState(() {
                              sort.direction = dir;
                            });
                            _notifyChange();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.accentRed),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    onPressed: () {
                      setState(() {
                        _sorts.removeAt(idx);
                      });
                      _notifyChange();
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildValueWidget(FilterClause filter) {
    if (filter.dataType == FilterDataType.nullValue) {
      return Container(
        height: 30,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgInput.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: const Text('null', style: TextStyle(fontSize: 11, color: AppColors.textDim, fontStyle: FontStyle.italic)),
      );
    }

    if (filter.dataType == FilterDataType.boolean) {
      final currentBool = filter.value.toLowerCase() == 'true' ? 'true' : 'false';
      return Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentBool,
            dropdownColor: AppColors.bgCard,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMain),
            isDense: true,
            items: const [
              DropdownMenuItem(value: 'true', child: Text('true')),
              DropdownMenuItem(value: 'false', child: Text('false')),
            ],
            onChanged: (bVal) {
              if (bVal != null) {
                setState(() {
                  filter.value = bVal;
                });
                _notifyChange();
              }
            },
          ),
        ),
      );
    }

    String hintText = "Value (e.g. 'active')";
    TextInputType keyboard = TextInputType.text;
    List<TextInputFormatter>? formatters;

    switch (filter.dataType) {
      case FilterDataType.integer:
        hintText = 'Integer (e.g. 25)';
        keyboard = const TextInputType.numberWithOptions(signed: true);
        formatters = [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))];
        break;
      case FilterDataType.doubleVal:
        hintText = 'Double (e.g. 99.99)';
        keyboard = const TextInputType.numberWithOptions(decimal: true, signed: true);
        formatters = [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))];
        break;
      case FilterDataType.timestamp:
        hintText = 'ISO Date (e.g. 2026-07-22T22:30:00+05:30)';
        break;
      case FilterDataType.array:
        hintText = "['val1', 'val2']";
        break;
      case FilterDataType.mapVal:
        hintText = '{"key": "value"}';
        break;
      case FilterDataType.reference:
        hintText = 'projects/.../documents/col/docId';
        break;
      case FilterDataType.geoPoint:
        hintText = '{"latitude": 37.77, "longitude": -122.41}';
        break;
      case FilterDataType.bytes:
        hintText = 'Base64 string (e.g. aGVsbG8=)';
        break;
      default:
        hintText = "Value (e.g. active)";
    }

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: TextField(
        controller: TextEditingController(text: filter.value)
          ..selection = TextSelection.collapsed(offset: filter.value.length),
        keyboardType: keyboard,
        inputFormatters: formatters,
        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMain),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 11),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
        onChanged: (val) {
          filter.value = val;
          _notifyChange();
        },
      ),
    );
  }
}
