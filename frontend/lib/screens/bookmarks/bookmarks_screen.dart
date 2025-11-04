import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/scheme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/schemes_provider.dart';
import '../../widgets/scheme_card.dart';
import '../scheme_detail/scheme_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    final BookmarksProvider provider = context.read<BookmarksProvider>();
    Future.microtask(provider.restoreFromCache);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    final BookmarksProvider bookmarksProvider = context.watch<BookmarksProvider>();
    final SchemesProvider schemesProvider = context.watch<SchemesProvider>();
    final List<Scheme> bookmarks = bookmarksProvider.bookmarks;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('bookmarks_title')),
      ),
      body: bookmarks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 42),
                child: Text(
                  loc.translate('empty_bookmarks'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF6B7AA0)),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: bookmarks.length,
              itemBuilder: (BuildContext context, int index) {
                final Scheme scheme = bookmarks[index];
                final bool offline = schemesProvider.isOffline;
                return Column(
                  children: <Widget>[
                    if (offline && index == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: _OfflineInfo(message: loc.translate('offline_warning')),
                      ),
                    SchemeCard(
                      scheme: scheme,
                      isBookmarked: true,
                      onBookmark: () => bookmarksProvider.toggleBookmark(scheme),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SchemeDetailScreen(scheme: scheme)),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _OfflineInfo extends StatelessWidget {
  const _OfflineInfo({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline, color: Color(0xFF176BFB)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF176BFB)),
            ),
          ),
        ],
      ),
    );
  }
}
