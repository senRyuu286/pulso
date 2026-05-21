import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/search_providers.dart';
import '../../domain/models/user_search_result.dart';
import '../../domain/repositories/user_repository.dart';

// ─── Search State ─────────────────────────────────────────────────────────────

sealed class SearchState {
  const SearchState();
}

final class SearchInitial extends SearchState {
  const SearchInitial();
}

final class SearchLoading extends SearchState {
  const SearchLoading();
}

final class SearchLoaded extends SearchState {
  const SearchLoaded(this.results);

  final List<UserSearchResult> results;
}

final class SearchError extends SearchState {
  const SearchError(this.message);

  final String message;
}

// ─── Search Notifier ──────────────────────────────────────────────────────────

final searchNotifierProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounce;

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchInitial();
  }

  UserRepository get _repository => ref.read(userRepositoryProvider);

  void onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const SearchInitial();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(trimmed));
  }

  Future<void> _search(String query) async {
    state = const SearchLoading();
    try {
      final results = await _repository.searchUsers(query);
      state = SearchLoaded(results);
    } catch (e) {
      state = SearchError(e.toString());
    }
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchInitial();
  }
}
