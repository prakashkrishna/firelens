class FirestoreDatabase {
  final String databaseId; // e.g. '(default)', 'analytics-db'
  final String name;       // Full resource name
  final String locationId; // e.g. 'nam5'

  const FirestoreDatabase({
    required this.databaseId,
    required this.name,
    required this.locationId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirestoreDatabase &&
          runtimeType == other.runtimeType &&
          databaseId == other.databaseId;

  @override
  int get hashCode => databaseId.hashCode;

  @override
  String toString() => databaseId;
}
