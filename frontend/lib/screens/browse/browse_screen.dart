import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/scheme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/schemes_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/scheme_card.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../scheme_detail/scheme_detail_screen.dart';
import '../notifications/notifications_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  @override
  void initState() {
    super.initState();
    final SchemesProvider provider = context.read<SchemesProvider>();
    Future.microtask(() async {
      if (provider.categorySchemes.isEmpty) {
        await provider.loadByCategory(provider.selectedCategory);
      }
      if (provider.stateSchemes.isEmpty) {
        await provider.loadByState(provider.selectedState);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    final SchemesProvider schemesProvider = context.watch<SchemesProvider>();
    final BookmarksProvider bookmarksProvider = context.watch<BookmarksProvider>();
    final String selectedCategory = schemesProvider.selectedCategory;
    final String selectedState = schemesProvider.selectedState;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _BrowseHeader(
                loc: loc,
                onBookmarksTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const BookmarksScreen()),
                  );
                },
                onNotificationsTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      loc.translate('category_filters'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, int index) {
                    final String category = categories[index];
                    final bool selected = category == selectedCategory;
                    return _CategoryPill(
                      label: category,
                      selected: selected,
                      onTap: () => schemesProvider.loadByCategory(category),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: categories.length,
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  loc.translate('state_filters'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, int index) {
                    final String state = indianStates[index];
                    final bool selected = state == selectedState;
                    return _StateChip(
                      label: state,
                      selected: selected,
                      onTap: () => schemesProvider.loadByState(state),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: indianStates.length,
                ),
              ),
              const SizedBox(height: 28),
              _BrowseSection(
                title: '${loc.translate('category_filters')} • $selectedCategory',
                isLoading: schemesProvider.isLoading && schemesProvider.categorySchemes.isEmpty,
                schemes: schemesProvider.categorySchemes,
                bookmarksProvider: bookmarksProvider,
              ),
              const SizedBox(height: 24),
              _BrowseSection(
                title: '${loc.translate('state_filters')} • $selectedState',
                isLoading: schemesProvider.isLoading && schemesProvider.stateSchemes.isEmpty,
                schemes: schemesProvider.stateSchemes,
                bookmarksProvider: bookmarksProvider,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseHeader extends StatelessWidget {
  const _BrowseHeader({
    required this.loc,
    required this.onBookmarksTap,
    required this.onNotificationsTap,
  });

  final AppLocalizations loc;
  final VoidCallback onBookmarksTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        gradient: schemeBlueGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  loc.translate('browse_title'),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.translate('browse_intro'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white.withAlpha(217), height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _HeaderCircleButton(icon: Icons.bookmark_border_rounded, onTap: onBookmarksTap),
          const SizedBox(width: 12),
          _HeaderCircleButton(icon: Icons.notifications_none_rounded, onTap: onNotificationsTap),
        ],
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(54),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: selected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? primaryBlue : dividerColor),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: primaryBlue.withAlpha(61),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.white : neutralText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? secondaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? secondaryBlue : dividerColor),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected ? Colors.white : mutedText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
          ),
        ),
      ),
    );
  }
}

class _BrowseSection extends StatelessWidget {
  const _BrowseSection({
    required this.title,
    required this.isLoading,
    required this.schemes,
    required this.bookmarksProvider,
  });

  final String title;
  final bool isLoading;
  final List<Scheme> schemes;
  final BookmarksProvider bookmarksProvider;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${schemes.length} ${loc.translate('results_count')}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: mutedText, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading && schemes.isEmpty)
            const _LoadingState()
          else if (schemes.isEmpty)
            const _EmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: schemes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (BuildContext context, int index) {
                final Scheme scheme = schemes[index];
                return SchemeCard(
                  scheme: scheme,
                  isBookmarked: bookmarksProvider.isBookmarked(scheme.id),
                  onBookmark: () => bookmarksProvider.toggleBookmark(scheme),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SchemeDetailScreen(scheme: scheme)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: accentLightBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.search_off_outlined, color: primaryBlue, size: 36),
          ),
          const SizedBox(height: 18),
          Text(
            loc.translate('empty_results'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            loc.translate('browse_empty_hint'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mutedText, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 32,
            width: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              loc.translate('loading'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
