import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_client/models/query_clause.dart';

void main() {
  group('QueryParser Syntax Validation Tests', () {
    test('detects trailing WHERE syntax error', () {
      final query = "WHERE site_id == 'office' WHERE";
      final error = QueryParser.validateSyntax(query);
      expect(error, contains('Syntax Error'));
    });

    test('detects unmatched single quotes', () {
      final query = "WHERE site_id == 'office";
      final error = QueryParser.validateSyntax(query);
      expect(error, equals("Syntax Error: Unmatched single quote (') in query."));
    });

    test('passes valid query', () {
      final query = "WHERE dev_id == 'gw_office' ORDER BY createdAt DESC";
      final error = QueryParser.validateSyntax(query);
      expect(error, isNull);
    });

    test('stringifies multiple filters with AND operator', () {
      final filters = [
        FilterClause(field: 'age', operator: '==', value: '20', dataType: FilterDataType.integer),
        FilterClause(field: 'ada', operator: '==', value: '2222', dataType: FilterDataType.integer),
      ];
      final stringified = QueryParser.stringify(filters, []);
      expect(stringified, equals('WHERE age == 20 AND ada == 2222'));
    });

    test('parses multiple AND filters into separate FilterClause objects', () {
      final query = 'WHERE age == 20 AND ada == 2222 ORDER BY score DESC';
      final parsed = QueryParser.parse(query);
      expect(parsed.filters.length, equals(2));
      expect(parsed.filters[0].field, equals('age'));
      expect(parsed.filters[0].value, equals('20'));
      expect(parsed.filters[1].field, equals('ada'));
      expect(parsed.filters[1].value, equals('2222'));
      expect(parsed.sorts.length, equals(1));
      expect(parsed.sorts[0].field, equals('score'));
      expect(parsed.sorts[0].direction, equals('DESC'));
    });
  });
}
