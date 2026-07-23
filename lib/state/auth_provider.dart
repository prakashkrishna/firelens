import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth/adc_auth_service.dart';

enum AuthMode {
  adc,
  serviceAccount,
}

class ServiceAccountModel {
  final String filePath;
  final String projectId;
  final String clientEmail;
  final String jsonContent;

  ServiceAccountModel({
    required this.filePath,
    required this.projectId,
    required this.clientEmail,
    required this.jsonContent,
  });

  factory ServiceAccountModel.fromFile(String path, String content) {
    final Map<String, dynamic> parsed = jsonDecode(content);
    final projectId = parsed['project_id'] as String? ?? 'unknown-project';
    final clientEmail = parsed['client_email'] as String? ?? '';
    return ServiceAccountModel(
      filePath: path,
      projectId: projectId,
      clientEmail: clientEmail,
      jsonContent: content,
    );
  }
}

final authModeProvider = StateProvider<AuthMode>((ref) => AuthMode.adc);
final serviceAccountProvider = StateProvider<ServiceAccountModel?>((ref) => null);

final adcAuthServiceProvider = Provider<AdcAuthService>((ref) {
  return AdcAuthService();
});

final authStateProvider = FutureProvider<AdcAuthResult>((ref) async {
  final authMode = ref.watch(authModeProvider);
  final serviceAccount = ref.watch(serviceAccountProvider);
  final authService = ref.watch(adcAuthServiceProvider);

  if (authMode == AuthMode.serviceAccount && serviceAccount != null) {
    return authService.authenticateServiceAccount(serviceAccount.jsonContent);
  }

  return authService.authenticate();
});
