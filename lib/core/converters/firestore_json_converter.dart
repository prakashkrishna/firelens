import 'package:googleapis/firestore/v1.dart';

/// Bidirectional converter between standard Dart JSON `Map<String, dynamic>`
/// and Firestore REST API [Value] objects.
class FirestoreJsonConverter {
  /// Converts a Firestore REST API Document [fields] map into standard Dart `Map<String, dynamic>`
  static Map<String, dynamic> fieldsToJson(Map<String, Value>? fields) {
    if (fields == null) return {};
    final result = <String, dynamic>{};
    fields.forEach((key, value) {
      result[key] = valueToDynamic(value);
    });
    return result;
  }

  /// Converts a single Firestore REST [Value] object to a standard Dart value
  static dynamic valueToDynamic(Value value) {
    if (value.nullValue != null) return null;
    if (value.booleanValue != null) return value.booleanValue;
    if (value.integerValue != null) return int.tryParse(value.integerValue!) ?? value.integerValue;
    if (value.doubleValue != null) return value.doubleValue;
    
    if (value.timestampValue != null) {
      return {
        '_type': 'Timestamp',
        'value': value.timestampValue,
      };
    }
    
    if (value.stringValue != null) return value.stringValue;
    if (value.referenceValue != null) return value.referenceValue;
    if (value.bytesValue != null) return value.bytesValue;

    if (value.geoPointValue != null) {
      return {
        '_type': 'GeoPoint',
        'latitude': value.geoPointValue!.latitude,
        'longitude': value.geoPointValue!.longitude,
      };
    }

    if (value.mapValue != null && value.mapValue!.fields != null) {
      return fieldsToJson(value.mapValue!.fields);
    }

    if (value.arrayValue != null && value.arrayValue!.values != null) {
      return value.arrayValue!.values!.map((v) => valueToDynamic(v)).toList();
    }

    return null;
  }

  /// Converts standard Dart `Map<String, dynamic>` into a Firestore REST API fields map
  static Map<String, Value> jsonToFields(Map<String, dynamic> json) {
    final result = <String, Value>{};
    json.forEach((key, value) {
      result[key] = dynamicToValue(value);
    });
    return result;
  }

  /// Converts a standard Dart value to a Firestore REST API [Value] object
  static Value dynamicToValue(dynamic value) {
    if (value == null) {
      return Value(nullValue: 'NULL_VALUE');
    }

    if (value is bool) {
      return Value(booleanValue: value);
    }

    if (value is int) {
      return Value(integerValue: value.toString());
    }

    if (value is double) {
      return Value(doubleValue: value);
    }

    if (value is String) {
      return Value(stringValue: value);
    }

    if (value is Map<String, dynamic>) {
      // Check for explicit Timestamp map representation (e.g. {"_type": "Timestamp", "value": "2026-07-23T11:30:00Z"})
      if (value['_type'] == 'Timestamp' && value.containsKey('value')) {
        final valStr = value['value'].toString();
        final dt = DateTime.tryParse(valStr);
        return Value(timestampValue: dt?.toUtc().toIso8601String() ?? valStr);
      }

      // Check for GeoPoint map representation (e.g. {"_type": "GeoPoint", "latitude": 37.77, "longitude": -122.41})
      if (value['_type'] == 'GeoPoint' ||
          (value.containsKey('latitude') && value.containsKey('longitude'))) {
        final lat = value['latitude'];
        final lng = value['longitude'];
        if (lat is num && lng is num) {
          return Value(
            geoPointValue: LatLng(
              latitude: lat.toDouble(),
              longitude: lng.toDouble(),
            ),
          );
        }
      }

      return Value(
        mapValue: MapValue(fields: jsonToFields(value)),
      );
    }

    if (value is List) {
      return Value(
        arrayValue: ArrayValue(
          values: value.map((v) => dynamicToValue(v)).toList(),
        ),
      );
    }

    return Value(stringValue: value.toString());
  }
}
