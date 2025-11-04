import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/scheme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/schemes_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/scheme_card.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../notifications/notifications_screen.dart';
import '../scheme_detail/scheme_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final SchemesProvider provider = context.read<SchemesProvider>();
    Future.microtask(() async {
      if (provider.recommendations.isEmpty) {
        await provider.loadRecommendations();
      }
      await provider.fetchAllCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final SchemesProvider provider = context.read<SchemesProvider>();
    await provider.loadRecommendations();
    await provider.fetchAllCategories(forceRefresh: true);
  }

  void _openBrowse({String? category, String? state}) {
    final SchemesProvider provider = context.read<SchemesProvider>();
    if (category != null) {
      provider.loadByCategory(category);
    }
    if (state != null) {
      provider.loadByState(state);
    }
    context.read<NavigationProvider>().setIndex(1);
  }

  void _onSearchChanged(String value) {
    context.read<SchemesProvider>().search(value);
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SchemesProvider>().search('');
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    final UserProfileProvider profileProvider = context.watch<UserProfileProvider>();
    final SchemesProvider schemesProvider = context.watch<SchemesProvider>();
    final BookmarksProvider bookmarksProvider = context.watch<BookmarksProvider>();

    final List<Scheme> visibleSchemes = _searchController.text.isNotEmpty
        ? schemesProvider.searchResults
        : schemesProvider.recommendations;
    final Scheme? heroScheme = schemesProvider.heroScheme;
    final bool isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        color: primaryBlue,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _HomeHeader(
                loc: loc,
                profileProvider: profileProvider,
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onClearSearch: _clearSearch,
                featuredScheme: heroScheme,
                onOpenBrowse: _openBrowse,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (schemesProvider.isOffline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _OfflineBanner(message: loc.translate('no_connection')),
                      ),
                    if (isSearching)
                      _SearchResultsSection(
                        results: visibleSchemes,
                        loc: loc,
                        bookmarksProvider: bookmarksProvider,
                        isLoading: schemesProvider.isLoading,
                      )
                    else ...<Widget>[
                      _SectionHeading(
                        title: loc.translate('home_recommended_heading'),
                        subtitle: loc.translate('based_on_profile'),
                        actionLabel: loc.translate('view_all'),
                        onActionTap: _openBrowse,
                      ),
                      _RecommendationCarousel(
                        schemes: schemesProvider.topFeaturedSchemes,
                        bookmarksProvider: bookmarksProvider,
                      ),
                      const SizedBox(height: 28),
                      _SectionHeading(
                        title: loc.translate('categories_heading'),
                        subtitle: loc.translate('categories_subtitle'),
                        onActionTap: _openBrowse,
                      ),
                      const SizedBox(height: 16),
                      _CategoryGrid(
                        onCategoryTap: (String category) => _openBrowse(category: category),
                      ),
                      const SizedBox(height: 32),
                      _SectionHeading(
                        title: loc.translate('home_latest_heading'),
                        subtitle: loc.translate('home_latest_subtitle'),
                      ),
                      const SizedBox(height: 16),
                      _LatestSchemesList(
                        schemes: schemesProvider.allSchemes.take(3).toList(),
                        bookmarksProvider: bookmarksProvider,
                      ),
                      const SizedBox(height: 32),
                      _SchemesForYouCTA(
                        label: loc.translate('cta_schemes_for_you'),
                        onTap: _openBrowse,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.loc,
    required this.profileProvider,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.featuredScheme,
    required this.onOpenBrowse,
  });

  final AppLocalizations loc;
  final UserProfileProvider profileProvider;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final Scheme? featuredScheme;
  final VoidCallback onOpenBrowse;

  @override
  Widget build(BuildContext context) {
    final String profileName = profileProvider.profile?.name.trim() ?? '';
    final String profileOccupation = profileProvider.profile?.occupation.trim() ?? '';
    final String profileLabel = profileName.isNotEmpty
        ? '${profileName.toUpperCase()} · ${loc.translate('based_on_profile')}'
        : (profileOccupation.isNotEmpty
            ? '${profileOccupation.toUpperCase()} · ${loc.translate('based_on_profile')}'
            : loc.translate('special_scheme_cta'));
    final bool hasSearch = searchController.text.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: MediaQuery.of(context).padding.top + 18,
        bottom: 32,
      ),
      decoration: const BoxDecoration(
        gradient: schemeBlueGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const _LogoBadge(),
              const Spacer(),
              _IconCircleButton(
                icon: Icons.bookmark_border_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const BookmarksScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _IconCircleButton(
                icon: Icons.notifications_none_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SearchBar(
            controller: searchController,
            hint: loc.translate('search_placeholder'),
            hasText: hasSearch,
            onChanged: onSearchChanged,
            onClear: onClearSearch,
          ),
          const SizedBox(height: 24),
          Text(
            loc.translate('special_scheme_title'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white70, letterSpacing: 0.4),
          ),
          const SizedBox(height: 12),
          _SpecialSchemeBanner(
            scheme: featuredScheme,
            loc: loc,
            profileLabel: profileLabel,
          ),
          const SizedBox(height: 24),
          _SegmentedFilterBar(
            filters: <_FilterTab>[
              _FilterTab(
                icon: Icons.auto_awesome,
                label: loc.translate('quick_action_recommended'),
                selected: true,
              ),
              _FilterTab(
                icon: Icons.category_rounded,
                label: loc.translate('quick_action_categories'),
                onTap: onOpenBrowse,
              ),
              _FilterTab(
                icon: Icons.flag_circle_outlined,
                label: loc.translate('state_filters'),
                onTap: onOpenBrowse,
              ),
              _FilterTab(
                icon: Icons.view_comfy_alt_rounded,
                label: loc.translate('view_all'),
                onTap: onOpenBrowse,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x331234FF), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
            const Icon(Icons.layers_rounded, color: primaryBlue, size: 28),
          const SizedBox(width: 10),
          Text(
            'SchemePlus',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: primaryBlueDark,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(64),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x1A1234FF), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search, color: mutedText),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              onChanged: onChanged,
            ),
          ),
          if (hasText)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                icon: const Icon(Icons.close, size: 18, color: mutedText),
                onPressed: onClear,
                splashRadius: 18,
              ),
            ),
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: accentLightBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tune_rounded, color: primaryBlue, size: 20),
          ),
        ],
      ),
    );
  }
}

class _SpecialSchemeBanner extends StatelessWidget {
  const _SpecialSchemeBanner({
    required this.scheme,
    required this.loc,
    required this.profileLabel,
  });

  final Scheme? scheme;
  final AppLocalizations loc;
  final String profileLabel;

  @override
  Widget build(BuildContext context) {
    final String title = scheme != null
        ? scheme!.title['en']?.toString() ?? ''
        : loc.translate('featured_scheme_default_title');
    final String subtitle = scheme != null
        ? (scheme!.shortDescription['en']?.toString() ?? '')
        : loc.translate('special_scheme_description');
    final String badge = scheme?.category ?? loc.translate('special_scheme_title');

    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[primaryBlue, primaryBlueDark],
                ),
              ),
            ),
            if (scheme?.imageUrl != null && scheme!.imageUrl!.isNotEmpty)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 180,
                    child: Opacity(
                      opacity: 0.20,
                      child: Image.network(
                        scheme!.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      badge.toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.85), height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        child: const Icon(Icons.person_outline, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          profileLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedFilterBar extends StatelessWidget {
  const _SegmentedFilterBar({required this.filters});

  final List<_FilterTab> filters;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < filters.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i == filters.length - 1 ? 0 : 12),
              child: _FilterChip(tab: filters[i]),
            ),
        ],
      ),
    );
  }
}

class _FilterTab {
  const _FilterTab({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.tab});

  final _FilterTab tab;

  @override
  Widget build(BuildContext context) {
    final bool selected = tab.selected;
    return GestureDetector(
      onTap: tab.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.white : Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              tab.icon,
              size: 18,
              color: selected ? primaryBlue : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              tab.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? primaryBlue : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700, color: neutralText),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: mutedText, height: 1.4),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _RecommendationCarousel extends StatelessWidget {
  const _RecommendationCarousel({
    required this.schemes,
    required this.bookmarksProvider,
  });

  final List<Scheme> schemes;
  final BookmarksProvider bookmarksProvider;

  @override
  Widget build(BuildContext context) {
    if (schemes.isEmpty) {
      return const _EmptyState();
    }
    return SizedBox(
      height: 360,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: schemes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (BuildContext context, int index) {
          final Scheme scheme = schemes[index];
          return _RecommendationCard(
            scheme: scheme,
            isBookmarked: bookmarksProvider.isBookmarked(scheme.id),
            onBookmark: () => bookmarksProvider.toggleBookmark(scheme),
          );
        },
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.scheme,
    required this.isBookmarked,
    required this.onBookmark,
  });

  final Scheme scheme;
  final bool isBookmarked;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    final String title = scheme.title['en']?.toString() ?? '';
    final String description = scheme.shortDescription['en']?.toString() ?? '';
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => SchemeDetailScreen(scheme: scheme)),
      ),
      child: Container(
        width: 220,
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: scheme.imageUrl != null && scheme.imageUrl!.isNotEmpty
                    ? Image.network(
                        scheme.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ImageFallback(category: scheme.category),
                      )
                    : _ImageFallback(category: scheme.category),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentLightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            scheme.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: primaryBlue, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onBookmark,
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                          color: isBookmarked ? primaryBlue : mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: mutedText, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.schedule, size: 16, color: mutedText),
                      const SizedBox(width: 6),
                      Text(
                        scheme.lastDate != null
                            ? '${loc.translate('deadline')}: ${_formatDate(scheme.lastDate!)}'
                            : loc.translate('apply_now'),
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: mutedText, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final IconData icon = categoryIconMap[category] ?? Icons.approval_rounded;
    final List<Color> gradient = categoryGradientMap[category] ?? <Color>[primaryBlue, secondaryBlue];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white70, size: 48),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onCategoryTap});

  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: categories.length,
      itemBuilder: (BuildContext context, int index) {
        final String category = categories[index];
        return _CategoryTile(
          category: category,
          onTap: () => onCategoryTap(category),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final IconData icon = categoryIconMap[category] ?? Icons.layers_outlined;
    final List<Color> gradient = categoryGradientMap[category] ?? <Color>[primaryBlue, secondaryBlue];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                category,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: neutralText, fontWeight: FontWeight.w600, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestSchemesList extends StatelessWidget {
  const _LatestSchemesList({required this.schemes, required this.bookmarksProvider});

  final List<Scheme> schemes;
  final BookmarksProvider bookmarksProvider;

  @override
  Widget build(BuildContext context) {
    if (schemes.isEmpty) {
      return const _EmptyState();
    }
    return Column(
      children: schemes
          .map((Scheme scheme) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CompactSchemeTile(
                  scheme: scheme,
                  isBookmarked: bookmarksProvider.isBookmarked(scheme.id),
                  onBookmark: () => bookmarksProvider.toggleBookmark(scheme),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => SchemeDetailScreen(scheme: scheme)),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _CompactSchemeTile extends StatelessWidget {
  const _CompactSchemeTile({
    required this.scheme,
    required this.isBookmarked,
    required this.onBookmark,
    required this.onTap,
  });

  final Scheme scheme;
  final bool isBookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    final IconData icon = categoryIconMap[scheme.category] ?? Icons.layers_outlined;
    final String title = scheme.title['en']?.toString() ?? '';
    final String subtitle = scheme.highlight ?? scheme.shortDescription['en']?.toString() ?? '';
  final String location = scheme.state.trim().isEmpty
    ? loc.translate('state_placeholder')
    : scheme.state;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dividerColor),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x081234FF), blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: accentPaleBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: primaryBlueDark, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700, color: neutralText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: mutedText, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Icon(Icons.location_on_outlined, size: 16, color: mutedText.withValues(alpha: 0.85)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: mutedText, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  onPressed: onBookmark,
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: isBookmarked ? primaryBlue : mutedText,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
                const SizedBox(height: 6),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primaryBlue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SchemesForYouCTA extends StatelessWidget {
  const _SchemesForYouCTA({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.3),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsSection extends StatelessWidget {
  const _SearchResultsSection({
    required this.results,
    required this.loc,
    required this.bookmarksProvider,
    required this.isLoading,
  });

  final List<Scheme> results;
  final AppLocalizations loc;
  final BookmarksProvider bookmarksProvider;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && results.isEmpty) {
      return const _LoadingState();
    }
    if (results.isEmpty) {
      return const _EmptyState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          loc.translate('search_results'),
          style:
              Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: neutralText),
        ),
        const SizedBox(height: 16),
        ...results.map((Scheme scheme) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SchemeCard(
                scheme: scheme,
                isBookmarked: bookmarksProvider.isBookmarked(scheme.id),
                onBookmark: () => bookmarksProvider.toggleBookmark(scheme),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => SchemeDetailScreen(scheme: scheme)),
                ),
              ),
            )),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2DD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFBF7100)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFFBF7100), fontWeight: FontWeight.w600),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: accentLightBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.inbox_outlined, color: primaryBlue, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            loc.translate('empty_results'),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: neutralText),
          ),
          const SizedBox(height: 8),
          Text(
            loc.translate('browse_empty_hint'),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: mutedText, height: 1.5),
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
          const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              loc.translate('loading'),
              style: const TextStyle(fontWeight: FontWeight.w600, color: neutralText),
            ),
          ),
        ],
      ),
    );
  }
}
