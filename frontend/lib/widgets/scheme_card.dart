import 'package:flutter/material.dart';

import '../data/models/scheme.dart';
import '../l10n/app_localizations.dart';

class SchemeCard extends StatelessWidget {
  const SchemeCard({
    super.key,
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
    final String title = _localizedText(scheme.title, loc);
    final String description = _localizedText(scheme.shortDescription, loc);
    final String benefits = _localizedText(scheme.benefits, loc);
    final DateTime? deadline = scheme.lastDate;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            scheme.category,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF2F6BFF),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
                    color: isBookmarked ? const Color(0xFF176BFB) : const Color(0xFF90A4C7),
                    onPressed: onBookmark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF5B6C94)),
                  const SizedBox(width: 6),
                  Text(
                    scheme.state,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5B6C94)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF516091),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.card_giftcard, color: Color(0xFF176BFB)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        benefits,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF2550A6)),
                      ),
                    ),
                  ],
                ),
              ),
              if (deadline != null) ...<Widget>[
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    const Icon(Icons.schedule, size: 18, color: Color(0xFF5B6C94)),
                    const SizedBox(width: 6),
                    Text(
                      '${loc.translate('deadline')}: ${_formatDate(deadline)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5B6C94)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _localizedText(Map<String, dynamic> map, AppLocalizations loc) {
    if (loc.locale.languageCode == 'ta') {
      final String? value = map['ta'] as String?;
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return map['en']?.toString() ?? '';
  }

  static String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}
