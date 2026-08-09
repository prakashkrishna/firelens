import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class AdcAuthResult {
  final http.Client client;
  final String accountEmail;
  final bool isSuccess;
  final String? errorMessage;

  AdcAuthResult({
    required this.client,
    required this.accountEmail,
    required this.isSuccess,
    this.errorMessage,
  });
}

class AdcAuthService {
  static const List<String> scopes = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/datastore',
  ];

  /// Authenticates using Windows Application Default Credentials (gcloud ADC / GOOGLE_APPLICATION_CREDENTIALS)
  Future<AdcAuthResult> authenticate() async {
    try {
      final client = await clientViaApplicationDefaultCredentials(
        scopes: scopes,
      );

      return AdcAuthResult(
        client: client,
        accountEmail: 'ADC Authenticated',
        isSuccess: true,
      );
    } catch (e) {
      return AdcAuthResult(
        client: http.Client(),
        accountEmail: 'Not Authenticated',
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Authenticates using gcloud CLI user login (`gcloud auth print-access-token`)
  Future<AdcAuthResult> authenticateGcloudCli() async {
    try {
      final tokenResult = await Process.run('gcloud', ['auth', 'print-access-token'], runInShell: true);
      if (tokenResult.exitCode != 0) {
        final err = (tokenResult.stderr as String).trim();
        return AdcAuthResult(
          client: http.Client(),
          accountEmail: 'gcloud CLI Error',
          isSuccess: false,
          errorMessage: err.isEmpty ? 'Failed to get access token from gcloud CLI. Have you run "gcloud auth login"?' : err,
        );
      }

      final token = (tokenResult.stdout as String).trim();
      if (token.isEmpty) {
        return AdcAuthResult(
          client: http.Client(),
          accountEmail: 'gcloud CLI Error',
          isSuccess: false,
          errorMessage: 'gcloud returned an empty access token.',
        );
      }

      String email = 'gcloud CLI User';
      try {
        final accountResult = await Process.run('gcloud', ['config', 'get-value', 'account'], runInShell: true);
        if (accountResult.exitCode == 0) {
          final fetchedEmail = (accountResult.stdout as String).trim();
          if (fetchedEmail.isNotEmpty) {
            email = fetchedEmail;
          }
        }
      } catch (_) {}

      final credentials = AccessCredentials(
        AccessToken(
          'Bearer',
          token,
          DateTime.now().toUtc().add(const Duration(minutes: 55)),
        ),
        null,
        scopes,
      );

      final client = authenticatedClient(http.Client(), credentials);

      return AdcAuthResult(
        client: client,
        accountEmail: email,
        isSuccess: true,
      );
    } catch (e) {
      return AdcAuthResult(
        client: http.Client(),
        accountEmail: 'gcloud CLI Error',
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Authenticates using a Service Account JSON Key file
  Future<AdcAuthResult> authenticateServiceAccount(String jsonContent) async {
    try {
      final credentials = ServiceAccountCredentials.fromJson(jsonContent);
      final client = await clientViaServiceAccount(
        credentials,
        scopes,
      );

      return AdcAuthResult(
        client: client,
        accountEmail: credentials.email,
        isSuccess: true,
      );
    } catch (e) {
      return AdcAuthResult(
        client: http.Client(),
        accountEmail: 'Service Account Error',
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }
}

