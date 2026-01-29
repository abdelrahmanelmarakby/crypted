import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:shimmer/shimmer.dart';

/// Link preview card with shimmer loading state
///
/// **Features:**
/// - Auto-detects URLs in text
/// - Fetches OpenGraph metadata (title, description, image)
/// - Shimmer loading animation
/// - Cached results to avoid refetching
/// - Tap to open in browser
class LinkPreviewCard extends StatefulWidget {
  final String url;
  final bool compact;

  const LinkPreviewCard({
    super.key,
    required this.url,
    this.compact = false,
  });

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  LinkMetadata? _metadata;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    // Check cache first
    final cached = LinkPreviewCache.get(widget.url);
    if (cached != null) {
      setState(() {
        _metadata = cached;
        _isLoading = false;
      });
      return;
    }

    try {
      final metadata = await LinkMetadataFetcher.fetch(widget.url);
      LinkPreviewCache.set(widget.url, metadata);
      if (mounted) {
        setState(() {
          _metadata = metadata;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openUrl() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildMinimalLink();
    }

    if (_isLoading) {
      return _buildShimmer();
    }

    if (_metadata == null) {
      return _buildMinimalLink();
    }

    return _buildPreviewCard();
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: widget.compact ? 60 : 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  // Description placeholder
                  Container(
                    height: 12,
                    width: 200,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return GestureDetector(
      onTap: _openUrl,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: ColorsManager.offWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ColorsManager.lightGrey.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (_metadata!.imageUrl != null && !widget.compact)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(_metadata!.imageUrl!),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
                child: _metadata!.imageUrl == null
                    ? Container(
                        color: ColorsManager.primary.withValues(alpha: 0.1),
                        child: Center(
                          child: Icon(
                            Icons.link,
                            color: ColorsManager.primary,
                            size: 32,
                          ),
                        ),
                      )
                    : null,
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Favicon + text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Site name / domain
                        Row(
                          children: [
                            if (_metadata!.favicon != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  _metadata!.favicon!,
                                  width: 16,
                                  height: 16,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.public,
                                    size: 16,
                                    color: ColorsManager.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                _metadata!.siteName ?? _getDomain(widget.url),
                                style: StylesManager.regular(
                                  fontSize: FontSize.xSmall,
                                  color: ColorsManager.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Title
                        if (_metadata!.title != null)
                          Text(
                            _metadata!.title!,
                            style: StylesManager.semiBold(
                              fontSize: FontSize.small,
                              color: ColorsManager.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                        // Description
                        if (_metadata!.description != null && !widget.compact) ...[
                          const SizedBox(height: 4),
                          Text(
                            _metadata!.description!,
                            style: StylesManager.regular(
                              fontSize: FontSize.xSmall,
                              color: ColorsManager.darkGrey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Compact image on right
                  if (widget.compact && _metadata!.imageUrl != null) ...[
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _metadata!.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: ColorsManager.lightGrey,
                          child: Icon(Icons.image, color: ColorsManager.grey),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalLink() {
    return GestureDetector(
      onTap: _openUrl,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ColorsManager.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link,
              size: 14,
              color: ColorsManager.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _getDomain(widget.url),
                style: StylesManager.medium(
                  fontSize: FontSize.xSmall,
                  color: ColorsManager.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}

/// Link metadata model
class LinkMetadata {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final String? favicon;

  LinkMetadata({
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.favicon,
  });
}

/// Simple in-memory cache for link metadata
class LinkPreviewCache {
  static final Map<String, LinkMetadata> _cache = {};
  static const int _maxEntries = 100;

  static LinkMetadata? get(String url) => _cache[url];

  static void set(String url, LinkMetadata metadata) {
    // Evict oldest entries if cache is full
    if (_cache.length >= _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[url] = metadata;
  }

  static void clear() => _cache.clear();
}

/// Fetches link metadata by parsing HTML OpenGraph tags
class LinkMetadataFetcher {
  static Future<LinkMetadata> fetch(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; LinkPreview/1.0)',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch URL');
      }

      final html = response.body;
      return _parseHtml(html, url);
    } catch (e) {
      // Return minimal metadata on error
      return LinkMetadata(
        title: _getDomain(url),
      );
    }
  }

  static LinkMetadata _parseHtml(String html, String originalUrl) {
    String? getMetaContent(String property) {
      // Try og: prefix first
      final ogPattern = RegExp(
        '<meta[^>]*property=["\']og:$property["\'][^>]*content=["\']([^"\']*)["\']',
        caseSensitive: false,
      );
      var match = ogPattern.firstMatch(html);
      if (match != null) return _decodeHtml(match.group(1));

      // Try reverse order (content before property)
      final ogPatternAlt = RegExp(
        '<meta[^>]*content=["\']([^"\']*)["\'][^>]*property=["\']og:$property["\']',
        caseSensitive: false,
      );
      match = ogPatternAlt.firstMatch(html);
      if (match != null) return _decodeHtml(match.group(1));

      // Try name attribute
      final namePattern = RegExp(
        '<meta[^>]*name=["\']$property["\'][^>]*content=["\']([^"\']*)["\']',
        caseSensitive: false,
      );
      match = namePattern.firstMatch(html);
      if (match != null) return _decodeHtml(match.group(1));

      return null;
    }

    // Get title from og:title or <title> tag
    String? title = getMetaContent('title');
    if (title == null) {
      final titlePattern = RegExp(r'<title[^>]*>([^<]*)</title>', caseSensitive: false);
      final match = titlePattern.firstMatch(html);
      if (match != null) title = _decodeHtml(match.group(1));
    }

    // Get image URL and make absolute if relative
    String? imageUrl = getMetaContent('image');
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      final uri = Uri.parse(originalUrl);
      imageUrl = '${uri.scheme}://${uri.host}$imageUrl';
    }

    // Get favicon
    String? favicon;
    final faviconPattern = RegExp(
      '<link[^>]*rel=["\'](?:shortcut )?icon["\'][^>]*href=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final faviconMatch = faviconPattern.firstMatch(html);
    if (faviconMatch != null) {
      favicon = faviconMatch.group(1);
      if (favicon != null && !favicon.startsWith('http')) {
        final uri = Uri.parse(originalUrl);
        favicon = '${uri.scheme}://${uri.host}$favicon';
      }
    }

    return LinkMetadata(
      title: title,
      description: getMetaContent('description'),
      imageUrl: imageUrl,
      siteName: getMetaContent('site_name'),
      favicon: favicon,
    );
  }

  static String? _decodeHtml(String? text) {
    if (text == null) return null;
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  static String _getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}

/// URL detection utility
class UrlDetector {
  static final RegExp _urlPattern = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  /// Extract first URL from text
  static String? extractFirstUrl(String text) {
    final match = _urlPattern.firstMatch(text);
    return match?.group(0);
  }

  /// Extract all URLs from text
  static List<String> extractAllUrls(String text) {
    return _urlPattern.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// Check if text contains a URL
  static bool containsUrl(String text) {
    return _urlPattern.hasMatch(text);
  }
}
