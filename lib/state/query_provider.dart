import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FetchMode {
  query,
  byDocId,
}

final fetchModeProvider = StateProvider<FetchMode>((ref) => FetchMode.query);
final queryInputProvider = StateProvider<String>((ref) => '');
final pageSizeProvider = StateProvider<int>((ref) => 5);
final pageTokenProvider = StateProvider<String?>((ref) => null);
final pageHistoryProvider = StateProvider<List<String?>>((ref) => [null]);
final currentPageIndexProvider = StateProvider<int>((ref) => 0);
