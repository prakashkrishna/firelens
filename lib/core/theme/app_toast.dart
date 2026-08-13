import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';

class AppToast {
  static void showSuccess(dynamic arg1, [String? arg2]) {
    final message = _extractMessage(arg1, arg2);
    debugPrint('[AppToast SUCCESS] $message');
    _show(
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF195B2A), // Vibrant Catchy Emerald Green
      borderColor: const Color(0xFF2EA043),
    );
  }

  static void showError(dynamic arg1, [String? arg2]) {
    final message = _extractMessage(arg1, arg2);
    debugPrint('[AppToast ERROR] $message');
    _show(
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFF6E1E1E), // Catchy Deep Crimson Red
      borderColor: const Color(0xFFF85149),
    );
  }

  static void showInfo(dynamic arg1, [String? arg2]) {
    final message = _extractMessage(arg1, arg2);
    debugPrint('[AppToast INFO] $message');
    _show(
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: const Color(0xFF18497E), // Catchy Sapphire Blue
      borderColor: const Color(0xFF388BFD),
    );
  }

  static String _extractMessage(dynamic arg1, String? arg2) {
    if (arg2 != null) return arg2;
    if (arg1 is String) return arg1;
    return arg1?.toString() ?? '';
  }

  static void _show({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    final messenger = globalMessengerKey.currentState;
    if (messenger == null) {
      debugPrint('[AppToast WARN] globalMessengerKey.currentState is null! Cannot display toast: $message');
      return;
    }

    // Schedule toast display after current frame to guarantee delivery even during widget rebuild loops
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.fixed,
          elevation: 8,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: const Duration(seconds: 4),
          shape: Border(
            top: BorderSide(color: borderColor, width: 1.5),
          ),
          content: Row(
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: SelectableText(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(60, 28),
                ),
                icon: const Icon(Icons.copy, size: 12),
                label: const Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message));
                  showInfo('Copied to clipboard!');
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}
