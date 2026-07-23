class FilterClause {
  String field;
  String operator;
  String value;
  FilterDataType dataType;

  FilterClause({
    this.field = '',
    this.operator = '==',
    this.value = '',
    this.dataType = FilterDataType.string,
  });

  String get formattedValue {
    final trimmedVal = value.trim();
    switch (dataType) {
      case FilterDataType.string:
      case FilterDataType.timestamp:
      case FilterDataType.reference:
      case FilterDataType.bytes:
        return "'$trimmedVal'";
      case FilterDataType.integer:
      case FilterDataType.doubleVal:
      case FilterDataType.boolean:
      case FilterDataType.nullValue:
      case FilterDataType.array:
      case FilterDataType.mapVal:
      case FilterDataType.geoPoint:
        return trimmedVal.isEmpty ? '""' : trimmedVal;
    }
  }
}

class SortClause {
  String field;
  String direction;

  SortClause({
    this.field = '',
    this.direction = 'ASC',
  });
}

enum FilterDataType {
  string(
    label: 'String',
    description: 'Plain text string value (wrapped in quotes).',
    example: "'active'",
  ),
  integer(
    label: 'Integer',
    description: 'Whole number integer value.',
    example: "42",
  ),
  doubleVal(
    label: 'Double',
    description: 'Decimal floating point number.',
    example: "99.99",
  ),
  boolean(
    label: 'Boolean',
    description: 'Boolean value (true or false).',
    example: "true",
  ),
  timestamp(
    label: 'Timestamp',
    description: 'UTC timestamp (ending in Z) or local timestamp with timezone offset (+05:30) in ISO 8601 format.',
    example: "2026-07-22T20:00:00Z\n2026-07-22T22:30:00+05:30",
  ),
  array(
    label: 'Array',
    description: 'List of elements in JSON array format.',
    example: "['admin', 'editor']",
  ),
  mapVal(
    label: 'Map',
    description: 'Nested key-value object map in JSON format.',
    example: '{"role": "admin", "active": true}',
  ),
  nullValue(
    label: 'Null',
    description: 'Null / empty value.',
    example: "null",
  ),
  reference(
    label: 'Reference',
    description: 'Firestore Document Reference path.',
    example: "'projects/my-project/databases/(default)/documents/users/user_123'",
  ),
  geoPoint(
    label: 'GeoPoint',
    description: 'Geographic latitude and longitude coordinates.',
    example: '{"latitude": 37.7749, "longitude": -122.4194}',
  ),
  bytes(
    label: 'Bytes',
    description: 'Base64 encoded binary data string.',
    example: "'aGVsbG8gd29ybGQ='",
  );

  final String label;
  final String description;
  final String example;

  const FilterDataType({
    required this.label,
    required this.description,
    required this.example,
  });

  @override
  String toString() => label;
}

class QueryParser {
  /// Validates the query string for syntax errors before execution
  static String? validateSyntax(String rawQuery) {
    final trimmed = rawQuery.trim();
    if (trimmed.isEmpty) return null;

    // Check for unmatched quotes
    int singleQuotes = 0;
    int doubleQuotes = 0;
    for (int i = 0; i < trimmed.length; i++) {
      if (trimmed[i] == "'") singleQuotes++;
      if (trimmed[i] == '"') doubleQuotes++;
    }
    if (singleQuotes % 2 != 0) return "Syntax Error: Unmatched single quote (') in query.";
    if (doubleQuotes % 2 != 0) return 'Syntax Error: Unmatched double quote (") in query.';

    final tokens = trimmed.split(RegExp(r'(?=WHERE|ORDER BY)', caseSensitive: false));

    for (final token in tokens) {
      final t = token.trim();
      if (t.isEmpty) continue;

      if (t.toUpperCase().startsWith('WHERE')) {
        final body = t.substring(5).trim();
        if (body.isEmpty) {
          return 'Syntax Error: Trailing or incomplete "WHERE" clause.';
        }

        final clauses = body.split(RegExp(r'\s+AND\s+', caseSensitive: false));
        for (final clause in clauses) {
          final match = RegExp(r'^(\w+)\s*(==|!=|>=|<=|>|<|array-contains-any|array-contains|not-in|in)\s*(.*)$')
              .firstMatch(clause.trim());

          if (match == null) {
            return 'Syntax Error: Invalid WHERE clause format near "${clause.trim()}". Expected format: WHERE field == value';
          }

          final val = match.group(3)?.trim() ?? '';
          if (val.isEmpty) {
            return 'Syntax Error: Missing value in WHERE clause near "${clause.trim()}".';
          }
        }
      } else if (t.toUpperCase().startsWith('ORDER BY')) {
        final body = t.substring(8).trim();
        if (body.isEmpty) {
          return 'Syntax Error: Trailing or incomplete "ORDER BY" clause.';
        }
      }
    }

    return null;
  }

  /// Converts visual filter and sort clauses into a single Firestore query string
  static String stringify(List<FilterClause> filters, List<SortClause> sorts) {
    final parts = <String>[];

    final filterParts = <String>[];
    for (final f in filters) {
      if (f.field.trim().isNotEmpty) {
        filterParts.add('${f.field.trim()} ${f.operator} ${f.formattedValue}');
      }
    }

    if (filterParts.isNotEmpty) {
      parts.add('WHERE ${filterParts.join(' AND ')}');
    }

    for (final s in sorts) {
      if (s.field.trim().isNotEmpty) {
        parts.add('ORDER BY ${s.field.trim()} ${s.direction}');
      }
    }

    return parts.join(' ');
  }

  /// Parses a raw query string into filter and sort clauses
  static ({List<FilterClause> filters, List<SortClause> sorts}) parse(String rawQuery) {
    final filters = <FilterClause>[];
    final sorts = <SortClause>[];

    if (rawQuery.trim().isEmpty) {
      return (filters: filters, sorts: sorts);
    }

    final tokens = rawQuery.trim().split(RegExp(r'(?=WHERE|ORDER BY)', caseSensitive: false));

    for (final token in tokens) {
      final t = token.trim();
      if (t.toUpperCase().startsWith('WHERE')) {
        final body = t.substring(5).trim();
        final clauses = body.split(RegExp(r'\s+AND\s+', caseSensitive: false));
        for (final clause in clauses) {
          final match = RegExp(r'^(\w+)\s*(==|!=|>=|<=|>|<|array-contains-any|array-contains|not-in|in)\s*(.*)$')
              .firstMatch(clause.trim());
          if (match != null) {
            final fName = match.group(1) ?? '';
            final op = match.group(2) ?? '==';
            var val = (match.group(3) ?? '').trim();

            FilterDataType type = FilterDataType.string;
            if (val == 'null') {
              type = FilterDataType.nullValue;
            } else if (val == 'true' || val == 'false') {
              type = FilterDataType.boolean;
            } else if (val.startsWith('[') && val.endsWith(']')) {
              type = FilterDataType.array;
            } else if (val.startsWith('{') && val.endsWith('}')) {
              type = val.contains('latitude') ? FilterDataType.geoPoint : FilterDataType.mapVal;
            } else if (int.tryParse(val) != null) {
              type = FilterDataType.integer;
            } else if (double.tryParse(val) != null) {
              type = FilterDataType.doubleVal;
            } else if ((val.startsWith("'") && val.endsWith("'")) || (val.startsWith('"') && val.endsWith('"'))) {
              val = val.substring(1, val.length - 1);
              if (val.contains('projects/') && val.contains('/documents/')) {
                type = FilterDataType.reference;
              } else if (RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(val)) {
                type = FilterDataType.timestamp;
              } else {
                type = FilterDataType.string;
              }
            }

            filters.add(FilterClause(
              field: fName,
              operator: op,
              value: val,
              dataType: type,
            ));
          }
        }
      } else if (t.toUpperCase().startsWith('ORDER BY')) {
        final body = t.substring(8).trim();
        final parts = body.split(RegExp(r'\s+'));
        final field = parts.isNotEmpty ? parts[0] : '';
        final dir = parts.length > 1 ? parts[1].toUpperCase() : 'ASC';
        if (field.isNotEmpty) {
          sorts.add(SortClause(field: field, direction: dir == 'DESC' ? 'DESC' : 'ASC'));
        }
      }
    }

    return (filters: filters, sorts: sorts);
  }
}
