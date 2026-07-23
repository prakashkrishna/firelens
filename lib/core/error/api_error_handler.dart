import 'package:googleapis/firestore/v1.dart';

class ApiErrorHandler {
  static String parseError(dynamic error) {
    if (error == null) return 'Unknown error occurred.';
    
    if (error is DetailedApiRequestError) {
      return 'API Error (${error.status}): ${error.message}';
    }
    
    final str = error.toString();
    if (str.contains('PERMISSION_DENIED') || str.contains('403')) {
      return 'Permission Denied: Ensure your GCP credentials have Firestore/Datastore permissions.';
    }
    if (str.contains('NOT_FOUND') || str.contains('404')) {
      return 'Resource Not Found: Check project ID or collection name.';
    }
    
    return str;
  }
}
