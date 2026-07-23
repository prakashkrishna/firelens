import 'package:flutter_test/flutter_test.dart';
import 'package:firelens/core/converters/firestore_json_converter.dart';

void main() {
  group('FirestoreJsonConverter Tests', () {
    test('converts primitive values correctly to and from JSON', () {
      final jsonInput = {
        'name': 'Alex',
        'age': 30,
        'rating': 4.5,
        'isActive': true,
        'notes': null,
      };

      final fields = FirestoreJsonConverter.jsonToFields(jsonInput);

      expect(fields['name']?.stringValue, 'Alex');
      expect(fields['age']?.integerValue, '30');
      expect(fields['rating']?.doubleValue, 4.5);
      expect(fields['isActive']?.booleanValue, true);
      expect(fields['notes']?.nullValue, 'NULL_VALUE');

      final reconstructedJson = FirestoreJsonConverter.fieldsToJson(fields);

      expect(reconstructedJson, equals(jsonInput));
    });

    test('converts nested maps and lists correctly', () {
      final jsonInput = {
        'user': {
          'email': 'alex@dev.com',
          'permissions': ['admin', 'editor'],
        },
      };

      final fields = FirestoreJsonConverter.jsonToFields(jsonInput);
      final reconstructed = FirestoreJsonConverter.fieldsToJson(fields);

      expect(reconstructed, equals(jsonInput));
    });

    test('treats plain strings strictly as stringValue and _type Timestamp maps as timestampValue', () {
      final jsonInput = {
        'plainString': '2026-07-23T11:30:00Z',
        'timestampObj': {
          '_type': 'Timestamp',
          'value': '2026-07-23T17:00:00+05:30',
        },
      };

      final fields = FirestoreJsonConverter.jsonToFields(jsonInput);

      // Plain string stays stringValue
      expect(fields['plainString']?.stringValue, '2026-07-23T11:30:00Z');
      expect(fields['plainString']?.timestampValue, isNull);

      // Explicit Timestamp object map becomes native timestampValue
      expect(fields['timestampObj']?.timestampValue, isNotNull);

      final reconstructed = FirestoreJsonConverter.fieldsToJson(fields);
      expect(reconstructed['plainString'], '2026-07-23T11:30:00Z');
      expect(reconstructed['timestampObj']['_type'], 'Timestamp');
    });

    test('converts latitude/longitude maps to native Firestore geoPointValue', () {
      final jsonInput = {
        'location': {
          '_type': 'GeoPoint',
          'latitude': 37.7749,
          'longitude': -122.4194,
        },
      };

      final fields = FirestoreJsonConverter.jsonToFields(jsonInput);

      expect(fields['location']?.geoPointValue?.latitude, 37.7749);
      expect(fields['location']?.geoPointValue?.longitude, -122.4194);

      final reconstructed = FirestoreJsonConverter.fieldsToJson(fields);
      expect(reconstructed['location']['_type'], 'GeoPoint');
      expect(reconstructed['location']['latitude'], 37.7749);
      expect(reconstructed['location']['longitude'], -122.4194);
    });
  });
}
