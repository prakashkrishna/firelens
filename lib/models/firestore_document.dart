import 'dart:convert';
import 'package:googleapis/firestore/v1.dart';
import '../core/converters/firestore_json_converter.dart';

class FirestoreDocumentModel {
  final String path; // e.g. "projects/p1/databases/(default)/documents/users/doc1"
  final String id;   // e.g. "doc1"
  final Map<String, dynamic> data;
  final String createTime;
  final String updateTime;

  FirestoreDocumentModel({
    required this.path,
    required this.id,
    required this.data,
    required this.createTime,
    required this.updateTime,
  });

  factory FirestoreDocumentModel.fromApiDocument(Document doc) {
    final docName = doc.name ?? '';
    final docId = docName.split('/').last;
    final jsonMap = FirestoreJsonConverter.fieldsToJson(doc.fields);
    
    return FirestoreDocumentModel(
      path: docName,
      id: docId,
      data: jsonMap,
      createTime: doc.createTime ?? '',
      updateTime: doc.updateTime ?? '',
    );
  }

  String toFormattedJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  String get previewSummary {
    if (data.isEmpty) return '{}';
    final entries = data.entries.take(2).map((e) {
      final valStr = jsonEncode(e.value);
      return '${e.key}: $valStr';
    }).join(', ');
    return entries;
  }
}
