import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/scheme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/bookmarks_provider.dart';
import '../../utils/constants.dart';
import '../../utils/url_launcher_util.dart';

class SchemeDetailScreen extends StatelessWidget {
  const SchemeDetailScreen({super.key, required this.scheme});

  final Scheme scheme;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    final BookmarksProvider bookmarks = context.watch<BookmarksProvider>();
    final bool isBookmarked = bookmarks.isBookmarked(scheme.id);
    final String title = _localizedText(scheme.title, loc);
    final String description = _localizedText(scheme.shortDescription, loc);
    final String benefits = _localizedText(scheme.benefits, loc);
    final String applyUrl = bookmarks.quickApplyUrl(scheme);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
            onPressed: () => bookmarks.toggleBookmark(scheme),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[primaryBlue, secondaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  scheme.category,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFFEAF1FF),
                        letterSpacing: 1.1,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    const Icon(Icons.location_on_outlined, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scheme.state,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFEAF1FF)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
          const SizedBox(height: 24),
          _DetailSection(
            title: loc.translate('benefits'),
            child: Text(
              benefits,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: loc.translate('eligibility'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _EligibilityRow(label: loc.translate('age'), value: _formatAge(scheme)),
                _EligibilityRow(label: loc.translate('gender'), value: scheme.eligibility.gender ?? 'Any'),
                if (scheme.eligibility.incomeMax != null)
                  _EligibilityRow(
                    label: loc.translate('income'),
                    value: '≤ ₹${scheme.eligibility.incomeMax}',
                  ),
                if (scheme.eligibility.occupations.isNotEmpty)
                  _EligibilityRow(
                    label: loc.translate('occupation'),
                    value: scheme.eligibility.occupations.join(', '),
                  ),
                if (scheme.eligibility.states.isNotEmpty)
                  _EligibilityRow(
                    label: loc.translate('state'),
                    value: scheme.eligibility.states.join(', '),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (scheme.lastDate != null)
            _DetailSection(
              title: loc.translate('deadline'),
              child: Text(
                _formatDate(scheme.lastDate!),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await launchExternalUrl(applyUrl);
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.translate('apply_link_unavailable'))),
                );
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: Text(loc.translate('apply_now')),
          ),
        ],
      ),
    );
  }

  String _localizedText(Map<String, dynamic> map, AppLocalizations loc) {
    if (loc.locale.languageCode == 'ta') {
      final String? ta = map['ta'] as String?;
      if (ta != null && ta.isNotEmpty) return ta;
    }
    return map['en']?.toString() ?? '';
  }

  String _formatAge(Scheme scheme) {
    final List<int?>? range = scheme.eligibility.ageRange;
    if (range == null || range.isEmpty) return '—';
    final int? min = range.first;
    final int? max = range.length > 1 ? range[1] : null;
    if (min != null && max != null) {
      return '$min - $max';
    }
    if (min != null) {
      return '≥ $min';
    }
    if (max != null) {
      return '≤ $max';
    }
    return '—';
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EligibilityRow extends StatelessWidget {
  const _EligibilityRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5B6C94),
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
