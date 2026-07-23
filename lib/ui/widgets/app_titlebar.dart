import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';

class AppTitlebar extends ConsumerWidget {
  const AppTitlebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return Container(
      height: 38,
      color: const Color(0xFF101218),
      child: Row(
        children: [
          // Drag area for window titlebar
          Expanded(
            child: WindowCaption(
              brightness: Brightness.dark,
              backgroundColor: Colors.transparent,
              title: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.firebaseGold,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Firestore Client',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  authAsync.when(
                    data: (res) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: res.isSuccess
                            ? AppColors.accentGreen.withValues(alpha: 0.15)
                            : AppColors.accentRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: res.isSuccess
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: res.isSuccess
                                  ? AppColors.accentGreen
                                  : AppColors.accentRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            res.isSuccess
                                ? res.accountEmail
                                : 'ADC Auth Error',
                            style: TextStyle(
                              color: res.isSuccess
                                  ? AppColors.accentGreen
                                  : AppColors.accentRed,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textMuted,
                      ),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
