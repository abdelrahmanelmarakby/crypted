import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypted_app/core/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:giphy_get/giphy_get.dart';

/// Result returned when user picks a GIF or sticker.
class GiphyPickResult {
  /// `'gif'` or `'sticker'`
  final String type;

  /// Full-size URL (original or fixed-height).
  final String url;

  /// Lower-res preview (for list thumbnails in chat).
  final String? previewUrl;

  /// Giphy content identifier.
  final String? giphyId;

  /// Human-readable title / alt-text.
  final String? title;

  /// Original width in pixels.
  final int? width;

  /// Original height in pixels.
  final int? height;

  const GiphyPickResult({
    required this.type,
    required this.url,
    this.previewUrl,
    this.giphyId,
    this.title,
    this.width,
    this.height,
  });
}

/// Bottom sheet that presents a tabbed Giphy picker (GIFs + Stickers).
///
/// Usage:
/// ```dart
/// final result = await GiphyPickerSheet.show(context);
/// if (result != null) { /* send result */ }
/// ```
class GiphyPickerSheet extends StatefulWidget {
  const GiphyPickerSheet({super.key});

  /// Convenience method to present the picker and return a result.
  static Future<GiphyPickResult?> show(BuildContext context) {
    return showModalBottomSheet<GiphyPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GiphyPickerSheet(),
    );
  }

  @override
  State<GiphyPickerSheet> createState() => _GiphyPickerSheetState();
}

class _GiphyPickerSheetState extends State<GiphyPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Separate state for each tab
  List<GiphyGif> _gifs = [];
  List<GiphyGif> _stickers = [];
  bool _isLoadingGifs = true;
  bool _isLoadingStickers = true;
  String _searchQuery = '';

  GiphyClient? _client;
  String? _randomId;

  Future<GiphyClient> _getClient() async {
    if (_client != null) return _client!;
    final tempClient = GiphyClient(
      apiKey: AppConstants.giphyApiKey,
      randomId: '',
    );
    try {
      _randomId = await tempClient.getRandomId();
    } catch (_) {
      _randomId = 'crypted_${DateTime.now().millisecondsSinceEpoch}';
    }
    _client = GiphyClient(
      apiKey: AppConstants.giphyApiKey,
      randomId: _randomId!,
    );
    return _client!;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTrending();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    // Reload if the new tab has no data yet
    if (_tabController.index == 0 && _gifs.isEmpty) {
      _loadTrending();
    } else if (_tabController.index == 1 && _stickers.isEmpty) {
      _loadTrending();
    }
  }

  Future<void> _loadTrending() async {
    setState(() {
      _isLoadingGifs = true;
      _isLoadingStickers = true;
    });

    try {
      final client = await _getClient();
      final gifCollection = await client.trending(
        offset: 0,
        limit: 30,
        rating: GiphyRating.g,
        type: GiphyType.gifs,
      );
      final stickerCollection = await client.trending(
        offset: 0,
        limit: 30,
        rating: GiphyRating.g,
        type: GiphyType.stickers,
      );

      if (mounted) {
        setState(() {
          _gifs = gifCollection.data;
          _stickers = stickerCollection.data;
          _isLoadingGifs = false;
          _isLoadingStickers = false;
        });
      }
    } catch (e) {
      debugPrint('Giphy trending error: $e');
      if (mounted) {
        setState(() {
          _isLoadingGifs = false;
          _isLoadingStickers = false;
        });
      }
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _searchQuery = '';
      _loadTrending();
      return;
    }

    _searchQuery = query.trim();

    setState(() {
      _isLoadingGifs = true;
      _isLoadingStickers = true;
    });

    try {
      final client = await _getClient();
      final gifResult = await client.search(
        _searchQuery,
        offset: 0,
        limit: 30,
        rating: GiphyRating.g,
        type: GiphyType.gifs,
      );
      final stickerResult = await client.search(
        _searchQuery,
        offset: 0,
        limit: 30,
        rating: GiphyRating.g,
        type: GiphyType.stickers,
      );

      if (mounted) {
        setState(() {
          _gifs = gifResult.data;
          _stickers = stickerResult.data;
          _isLoadingGifs = false;
          _isLoadingStickers = false;
        });
      }
    } catch (e) {
      debugPrint('Giphy search error: $e');
      if (mounted) {
        setState(() {
          _isLoadingGifs = false;
          _isLoadingStickers = false;
        });
      }
    }
  }

  void _onGifTapped(GiphyGif gif) {
    final images = gif.images;
    if (images == null) return;

    // Prefer fixed_height for consistent sizing; fall back to original
    final fullUrl = images.fixedHeight?.url ?? images.original?.url ?? '';
    final previewUrl =
        images.fixedHeightSmall?.url ?? images.fixedHeightDownsampled?.url;
    final width =
        int.tryParse(images.fixedHeight?.width ?? images.original?.width ?? '');
    final height = int.tryParse(
        images.fixedHeight?.height ?? images.original?.height ?? '');

    if (fullUrl.isEmpty) return;

    Navigator.of(context).pop(GiphyPickResult(
      type: 'gif',
      url: fullUrl,
      previewUrl: previewUrl,
      giphyId: gif.id,
      title: gif.title,
      width: width,
      height: height,
    ));
  }

  void _onStickerTapped(GiphyGif sticker) {
    final images = sticker.images;
    if (images == null) return;

    // For stickers, use fixed_height or original
    final fullUrl = images.fixedHeight?.url ?? images.original?.url ?? '';
    final width =
        int.tryParse(images.fixedHeight?.width ?? images.original?.width ?? '');
    final height = int.tryParse(
        images.fixedHeight?.height ?? images.original?.height ?? '');

    if (fullUrl.isEmpty) return;

    Navigator.of(context).pop(GiphyPickResult(
      type: 'sticker',
      url: fullUrl,
      giphyId: sticker.id,
      title: sticker.title,
      width: width,
      height: height,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? ColorsManager.darkBottomSheet : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorsManager.dividerAdaptive(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Paddings.large,
                vertical: Paddings.xSmall,
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _search,
                onChanged: (v) {
                  if (v.isEmpty) _search('');
                },
                decoration: InputDecoration(
                  hintText: 'Search GIFs & Stickers',
                  hintStyle: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                  prefixIcon:
                      const Icon(Icons.search, color: ColorsManager.grey),
                  filled: true,
                  fillColor: ColorsManager.inputBg(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: ColorsManager.primary,
              unselectedLabelColor: ColorsManager.grey,
              indicatorColor: ColorsManager.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: StylesManager.semiBold(fontSize: FontSize.small),
              unselectedLabelStyle:
                  StylesManager.regular(fontSize: FontSize.small),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'GIFs'),
                Tab(text: 'Stickers'),
              ],
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // GIFs grid
                  _buildGrid(
                    items: _gifs,
                    isLoading: _isLoadingGifs,
                    onTap: _onGifTapped,
                    scrollController: scrollController,
                  ),
                  // Stickers grid
                  _buildGrid(
                    items: _stickers,
                    isLoading: _isLoadingStickers,
                    onTap: _onStickerTapped,
                    scrollController: scrollController,
                    isSticker: true,
                  ),
                ],
              ),
            ),

            // Giphy attribution
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Powered by GIPHY',
                style: StylesManager.regular(
                  fontSize: FontSize.xXSmall,
                  color: ColorsManager.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid({
    required List<GiphyGif> items,
    required bool isLoading,
    required void Function(GiphyGif) onTap,
    required ScrollController scrollController,
    bool isSticker = false,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ColorsManager.primary),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty ? 'No results found' : 'Nothing to show',
          style: StylesManager.regular(
            fontSize: FontSize.medium,
            color: ColorsManager.grey,
          ),
        ),
      );
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSticker ? 4 : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: isSticker ? 1.0 : 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final gif = items[index];
        final previewUrl = gif.images?.fixedHeightSmall?.url ??
            gif.images?.fixedHeight?.url ??
            gif.images?.original?.url ??
            '';

        if (previewUrl.isEmpty) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => onTap(gif),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isSticker ? 8 : 12),
            child: CachedNetworkImage(
              imageUrl: previewUrl,
              fit: isSticker ? BoxFit.contain : BoxFit.cover,
              placeholder: (_, __) => Container(
                color: ColorsManager.lightGrey.withValues(alpha: 0.15),
              ),
              errorWidget: (_, __, ___) => Container(
                color: ColorsManager.lightGrey.withValues(alpha: 0.15),
                child: const Icon(Icons.broken_image, size: 24),
              ),
            ),
          ),
        );
      },
    );
  }
}
