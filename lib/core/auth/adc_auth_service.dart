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
