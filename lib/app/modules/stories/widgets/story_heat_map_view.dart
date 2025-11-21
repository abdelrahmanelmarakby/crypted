import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/data/models/story_cluster.dart';
import 'package:crypted_app/app/services/story_clustering_service.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/app/widgets/network_image.dart';

/// Epic Story Heat Map View - Better than Snapchat! 🔥
class StoryHeatMapView extends StatefulWidget {
  final List<StoryModel> stories;
  final VoidCallback? onCreateStory;

  const StoryHeatMapView({
    super.key,
    required this.stories,
    this.onCreateStory,
  });

  @override
  State<StoryHeatMapView> createState() => _StoryHeatMapViewState();
}

class _StoryHeatMapViewState extends State<StoryHeatMapView>
    with TickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _pulseController;
  late AnimationController _appearController;

  List<StoryCluster> clusters = [];
  StoryCluster? selectedCluster;
  Offset? mapCenter;
  double zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    // Pulse animation for active clusters
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Appear animation for clusters
    _appearController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _initializeClusters();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pulseController.dispose();
    _appearController.dispose();
    super.dispose();
  }

  void _initializeClusters() {
    // Create clusters with adaptive radius
    final radius = StoryClusteringService.getAdaptiveRadius(zoomLevel);
    clusters = StoryClusteringService.clusterStories(
      widget.stories,
      clusterRadiusKm: radius,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorsManager.primary.withValues(alpha: 0.1),
                  Colors.purple.withValues(alpha: 0.05),
                  Colors.pink.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),

          // Interactive Map Canvas
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            onInteractionUpdate: (details) {
              setState(() {
                final matrix = _transformationController.value;
                zoomLevel = matrix.getMaxScaleOnAxis();
              });
            },
            child: SizedBox(
              width: Get.width * 3,
              height: Get.height * 3,
              child: CustomPaint(
                painter: HeatMapPainter(
                  clusters: clusters,
                  selectedCluster: selectedCluster,
                  pulseAnimation: _pulseController,
                  appearAnimation: _appearController,
                ),
                child: Stack(
                  children: clusters.asMap().entries.map((entry) {
                    final index = entry.key;
                    final cluster = entry.value;
                    return _buildClusterMarker(cluster, index);
                  }).toList(),
                ),
              ),
            ),
          ),

          // Top Bar
          _buildTopBar(),

          // Selected Cluster Preview
          if (selectedCluster != null) _buildClusterPreview(),

          // Create Story FAB
          _buildCreateStoryButton(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map, color: ColorsManager.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              '${widget.stories.length} Stories • ${clusters.length} Locations',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterMarker(StoryCluster cluster, int index) {
    final delay = index * 50;
    final isSelected = selectedCluster?.id == cluster.id;

    return AnimatedBuilder(
      animation: _appearController,
      builder: (context, child) {
        final animation = CurvedAnimation(
          parent: _appearController,
          curve: Interval(
            (delay / 1000).clamp(0.0, 0.8),
            ((delay + 200) / 1000).clamp(0.2, 1.0),
            curve: Curves.elasticOut,
          ),
        );

        return Transform.scale(
          scale: animation.value,
          child: Positioned(
            left: Get.width + (cluster.centerLatitude * 500),
            top: Get.height + (cluster.centerLongitude * 500),
            child: GestureDetector(
              onTap: () => _onClusterTap(cluster),
              child: _buildClusterWidget(cluster, isSelected),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClusterWidget(StoryCluster cluster, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      transform: Matrix4.identity()..scale(isSelected ? 1.2 : 1.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Pulse effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.3),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getClusterColor(cluster).withValues(alpha: 
                      0.3 * (1 - _pulseController.value),
                    ),
                  ),
                ),
              );
            },
          ),

          // Main cluster circle
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getClusterColor(cluster),
                  _getClusterColor(cluster).withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _getClusterColor(cluster).withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: cluster.previewStories.isNotEmpty &&
                    cluster.previewStories.first.user?.imageUrl != null
                ? ClipOval(
                    child: AppCachedNetworkImage(
                      imageUrl: cluster.previewStories.first.user!.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
          ),

          // Story count badge
          if (cluster.size > 1)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getClusterColor(cluster),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '${cluster.size}',
                  style: TextStyle(
                    color: _getClusterColor(cluster),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClusterPreview() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 300, end: 0),
        builder: (context, double offset, child) {
          return Transform.translate(
            offset: Offset(0, offset),
            child: child,
          );
        },
        child: Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 16),

              // Location info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.place, color: ColorsManager.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCluster!.locationString,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${selectedCluster!.size} ${selectedCluster!.size == 1 ? 'Story' : 'Stories'} • ${selectedCluster!.uniqueUserCount} ${selectedCluster!.uniqueUserCount == 1 ? 'Person' : 'People'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          selectedCluster = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Story previews
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedCluster!.stories.length,
                  itemBuilder: (context, index) {
                    final story = selectedCluster!.stories[index];
                    return _buildStoryPreviewCard(story, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryPreviewCard(StoryModel story, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _openStoryViewer(story),
        child: Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Story background
                if (story.storyType == StoryType.image &&
                    story.storyFileUrl != null)
                  Image.network(
                    story.storyFileUrl!,
                    fit: BoxFit.cover,
                  )
                else if (story.storyType == StoryType.text)
                  Container(
                    color: Color(
                      int.parse(story.backgroundColor?.replaceAll('#', '0xFF') ??
                          '0xFF000000'),
                    ),
                    child: Center(
                      child: Text(
                        story.storyText ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),

                // User info
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (story.user?.imageUrl != null)
                        CircleAvatar(
                          radius: 12,
                          backgroundImage:
                              NetworkImage(story.user!.imageUrl!),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        story.user?.fullName ?? 'Unknown',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateStoryButton() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: FloatingActionButton.extended(
          onPressed: widget.onCreateStory,
          backgroundColor: ColorsManager.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Create Story',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 8,
        ),
      ),
    );
  }

  Color _getClusterColor(StoryCluster cluster) {
    // Color intensity based on cluster size
    if (cluster.size >= 10) return Colors.red;
    if (cluster.size >= 5) return Colors.orange;
    if (cluster.size >= 3) return Colors.amber;
    return ColorsManager.primary;
  }

  void _onClusterTap(StoryCluster cluster) {
    setState(() {
      selectedCluster = cluster;
    });
  }

  void _openStoryViewer(StoryModel story) {
    // Navigate to story viewer
    Get.toNamed('/story-viewer', arguments: {
      'story': story,
      'cluster': selectedCluster,
    });
  }
}

/// Custom painter for heat map background
class HeatMapPainter extends CustomPainter {
  final List<StoryCluster> clusters;
  final StoryCluster? selectedCluster;
  final Animation<double> pulseAnimation;
  final Animation<double> appearAnimation;

  HeatMapPainter({
    required this.clusters,
    this.selectedCluster,
    required this.pulseAnimation,
    required this.appearAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw heat map connections
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < clusters.length; i++) {
      for (var j = i + 1; j < clusters.length; j++) {
        final cluster1 = clusters[i];
        final cluster2 = clusters[j];

        final distance = StoryModel.calculateDistance(
          StoryModel(latitude: cluster1.centerLatitude, longitude: cluster1.centerLongitude),
          StoryModel(latitude: cluster2.centerLatitude, longitude: cluster2.centerLongitude),
        );

        if (distance < 5.0) {
          // Draw connection line
          paint.color = ColorsManager.primary.withValues(alpha: 0.1 * appearAnimation.value);

          final p1 = Offset(
            size.width / 2 + (cluster1.centerLatitude * 500),
            size.height / 2 + (cluster1.centerLongitude * 500),
          );
          final p2 = Offset(
            size.width / 2 + (cluster2.centerLatitude * 500),
            size.height / 2 + (cluster2.centerLongitude * 500),
          );

          canvas.drawLine(p1, p2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(HeatMapPainter oldDelegate) => true;
}
