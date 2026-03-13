import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// ===========================================================================
// Shared Markdown accordion — used by POCUS player and Clinical Guide detail.
//
// Both screens share the same parser, accordion card, and style sheet.
// The parser splits Markdown on `### ` (H3) headers into sections.
// ===========================================================================

/// A parsed section from Markdown (split by `### ` headers).
class ParsedSection {
  const ParsedSection({required this.title, required this.body});

  final String title;
  final String body;

  /// Whether this section contains a clinical risk/alert keyword.
  bool get isCritical =>
      title.contains('⚠️') ||
      title.toLowerCase().contains('contraindicaç') ||
      title.toLowerCase().contains('red flag') ||
      title.toLowerCase().contains('alarme');

  /// Whether the section title or body contains [query].
  bool matchesQuery(String query) =>
      title.toLowerCase().contains(query) ||
      body.toLowerCase().contains(query);
}

/// Splits a Markdown string on `### ` headers into an intro + sections.
///
/// - `intro`: everything before the first `### `.
/// - `sections`: one [ParsedSection] per `### ` header.
({String intro, List<ParsedSection> sections}) parseMarkdownBody(String raw) {
  final pattern = RegExp(r'^### ', multiLine: true);
  final parts = raw.split(pattern);

  final intro = parts.first.trim();

  final sections = <ParsedSection>[];
  for (int i = 1; i < parts.length; i++) {
    final block = parts[i];
    final newline = block.indexOf('\n');
    if (newline == -1) {
      sections.add(ParsedSection(title: block.trim(), body: ''));
    } else {
      sections.add(ParsedSection(
        title: block.substring(0, newline).trim(),
        body: block.substring(newline + 1).trim(),
      ));
    }
  }

  return (intro: intro, sections: sections);
}

/// Shared [MarkdownStyleSheet] for accordion body content.
///
/// Uses the AMPLE brand palette (Deep Teal #004D40, Coral #FF6F61).
MarkdownStyleSheet sharedMarkdownStyle() => MarkdownStyleSheet(
      h2: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF004D40),
        height: 2.0,
      ),
      h3: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        height: 2.0,
      ),
      h4: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF546E7A),
        height: 1.8,
      ),
      p: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
      strong: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
      listBullet: const TextStyle(fontSize: 14, color: Colors.black87),
      listIndent: 16,
      blockquote: const TextStyle(
        fontSize: 13,
        color: Color(0xFF37474F),
        height: 1.5,
      ),
      blockquoteDecoration: const BoxDecoration(
        color: Color(0xFFFFF8E1),
        border: Border(
          left: BorderSide(color: Color(0xFFFF6F61), width: 4),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      code: const TextStyle(
        fontSize: 12.5,
        backgroundColor: Color(0xFFF5F5F5),
        fontFamily: 'monospace',
        color: Color(0xFF004D40),
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
    );

// ---------------------------------------------------------------------------
// MarkdownSectionCard — shared accordion card for a single section
// ---------------------------------------------------------------------------

class MarkdownSectionCard extends StatelessWidget {
  const MarkdownSectionCard({
    super.key,
    required this.section,
    required this.index,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.imageBuilder,
    this.hasSearchMatch = false,
  });

  final ParsedSection section;
  final int index;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  /// Optional image builder for inline video/image rendering (e.g. POCUS).
  final Widget Function(MarkdownImageConfig)? imageBuilder;

  /// Whether this section has a search match (shows blue dot).
  final bool hasSearchMatch;

  @override
  Widget build(BuildContext context) {
    final isCritical = section.isCritical;

    final card = Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCritical
                ? const Color(0xFFE53935).withValues(alpha: 0.10)
                : const Color(0xFF004D40).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isCritical
                    ? const Color(0xFFE53935)
                    : const Color(0xFF004D40),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                section.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isCritical ? const Color(0xFFE53935) : Colors.black87,
                ),
              ),
            ),
            if (hasSearchMatch)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF004D40),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        iconColor: Colors.grey[600],
        collapsedIconColor: Colors.grey[400],
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
          const SizedBox(height: 12),
          if (section.body.isNotEmpty)
            MarkdownBody(
              data: section.body,
              selectable: true,
              softLineBreak: true,
              sizedImageBuilder: imageBuilder,
              styleSheet: sharedMarkdownStyle(),
            ),
        ],
      ),
    );

    // Critical sections get a red left border.
    if (isCritical) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: const Color(0xFFE53935)),
              Expanded(child: card),
            ],
          ),
        ),
      );
    }

    return card;
  }
}
