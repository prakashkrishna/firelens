import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/auth/adc_auth_service.dart';

enum AuthMode {
  adc,
  gcloudCli,
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
final isConnectedProvider = StateProvider<bool>((ref) => false);

final adcAuthServiceProvider = Provider<AdcAuthService>((ref) {
  return AdcAuthService();
});

final authStateProvider = FutureProvider<AdcAuthResult>((ref) async {
  final isConnected = ref.watch(isConnectedProvider);
  if (!isConnected) {
    return AdcAuthResult(
      client: http.Client(),
      accountEmail: 'Not Connected',
      isSuccess: false,
    );
  }

  final authMode = ref.watch(authModeProvider);
  final serviceAccount = ref.watch(serviceAccountProvider);
  final authService = ref.watch(adcAuthServiceProvider);

  if (authMode == AuthMode.serviceAccount) {
    if (serviceAccount == null) {
      return AdcAuthResult(
        client: http.Client(),
        accountEmail: 'No Service Account Key',
        isSuccess: false,
        errorMessage: 'Please load a Service Account JSON Key file first.',
      );
    }
    return authService.authenticateServiceAccount(serviceAccount.jsonContent);
  }

  if (authMode == AuthMode.gcloudCli) {
    return authService.authenticateGcloudCli();
  }

  return authService.authenticate();
});


