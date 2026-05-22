import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pulso_theme_extension.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/models/user_search_result.dart';
import '../providers/search_notifier.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final searchState = ref.watch(searchNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              focusNode: _focus,
              onChanged: (q) =>
                  ref.read(searchNotifierProvider.notifier).onQueryChanged(q),
              onClear: () {
                _controller.clear();
                ref.read(searchNotifierProvider.notifier).clear();
              },
            ),
            Expanded(
              child: switch (searchState) {
                SearchInitial() => _EmptyPrompt(cs: cs),
                SearchLoading() => Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  ),
                SearchError(:final message) => _ErrorState(
                    message: message,
                    cs: cs,
                  ),
                SearchLoaded(:final results) => results.isEmpty
                    ? _NoResults(cs: cs)
                    : _ResultList(results: results),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          style: AppTextStyles.body.copyWith(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Search users...',
            hintStyle:
                AppTextStyles.body.copyWith(color: pulso.textPlaceholder),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: cs.onSurfaceVariant),
            suffixIcon: ListenableBuilder(
              listenable: controller,
              builder: (_, _) => controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                      onPressed: onClear,
                    )
                  : const SizedBox.shrink(),
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({required this.results});

  final List<UserSearchResult> results;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) =>
          _UserRow(result: results[index]),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.result});

  final UserSearchResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      onTap: () => context.push(AppRoutes.profileFor(result.id)),
      leading: AppAvatar(
        size: 40,
        avatarUrl: result.avatarUrl,
        username: result.username,
        showBorder: false,
      ),
      title: Text(
        '@${result.username}',
        style: AppTextStyles.label.copyWith(color: cs.onSurface),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          size: 20, color: cs.onSurfaceVariant),
    );
  }
}


class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Find people by username',
            style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No users found.',
        style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.cs});

  final String message;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Search failed. Please try again.',
        style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }
}
