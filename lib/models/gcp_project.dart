class GcpProject {
  final String projectId;
  final String name;

  const GcpProject({
    required this.projectId,
    required this.name,
  });

  factory GcpProject.fromJson(Map<String, dynamic> json) {
    return GcpProject(
      projectId: json['projectId'] ?? '',
      name: json['name'] ?? json['projectId'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GcpProject &&
          runtimeType == other.runtimeType &&
          projectId == other.projectId;

  @override
  int get hashCode => projectId.hashCode;

  @override
  String toString() => name;
}
