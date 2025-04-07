import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LearningResourcesScreen extends StatefulWidget {
  const LearningResourcesScreen({super.key});

  @override
  State<LearningResourcesScreen> createState() => _LearningResourcesScreenState();
}

class _LearningResourcesScreenState extends State<LearningResourcesScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    'All',
    'Visual Learning',
    'Audio Learning',
    'Interactive',
    'AR/VR',
    'Tutorials',
    'Exercises',
  ];

  final String _youtubeApiKey = 'AIzaSyAdLio3yM6yxC9jDz0BA9LKhhXh0hbDts4';
  bool _isLoading = true;
  
  List<LearningResource>? _resources;

  @override
  void initState() {
    super.initState();
    _fetchYouTubeVideos();
  }

  Future<void> _fetchYouTubeVideos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final Map<String, String> searchQueries = {
        'Visual Learning': 'visual learning techniques for disabilities',
        'Audio Learning': 'audio learning accessibility education',
        'Interactive': 'interactive learning disabilities',
        'AR/VR': 'augmented reality learning disabilities',
        'Tutorials': 'accessibility tutorials',
        'Exercises': 'accessibility exercises learning',
      };
      
      List<LearningResource> allResources = [];
      
      for (var entry in searchQueries.entries) {
        final String category = entry.key;
        final String query = entry.value;
        
        final response = await http.get(
          Uri.parse(
            'https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=3&q=$query&type=video&key=$_youtubeApiKey'
          ),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final items = data['items'] as List;
          
          for (var item in items) {
            final videoId = item['id']['videoId'];
            final snippet = item['snippet'];
            
            final videoResponse = await http.get(
              Uri.parse(
                'https://www.googleapis.com/youtube/v3/videos?part=contentDetails,statistics&id=$videoId&key=$_youtubeApiKey'
              ),
            );
            
            if (videoResponse.statusCode == 200) {
              final videoData = json.decode(videoResponse.body);
              final videoItems = videoData['items'] as List;
              
              if (videoItems.isNotEmpty) {
                final contentDetails = videoItems[0]['contentDetails'];
                final statistics = videoItems[0]['statistics'];
                
                final iso8601Duration = contentDetails['duration'];
                final duration = _parseDuration(iso8601Duration);
                
                final resource = LearningResource(
                  id: videoId,
                  title: snippet['title'],
                  description: snippet['description'],
                  type: category,
                  imageUrl: snippet['thumbnails']['high']['url'],
                  duration: duration,
                  level: _determineLevel(int.parse(statistics['viewCount'] ?? '0')),
                  isNew: _isVideoNew(snippet['publishedAt']),
                  isPopular: int.parse(statistics['viewCount'] ?? '0') > 10000,
                  youtubeId: videoId,
                );
                
                allResources.add(resource);
              }
            }
          }
        }
      }
      
      allResources.add(
        LearningResource(
          id: '9',
          title: 'Dyslexic Learning in AR',
          description: 'Interactive 3D models to help dyslexic children learn letters, numbers, and concepts with AR technology.',
          type: 'AR/VR',
          imageUrl: 'https://i.ytimg.com/vi/9vJRopau0g0/hqdefault.jpg',
          duration: '30 min',
          level: 'All Levels',
          isNew: true,
          isPopular: true,
          youtubeId: '9vJRopau0g0',
        ),
      );
      
      setState(() {
        _resources = allResources;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching YouTube videos: $e');
      setState(() {
        _resources = _getStaticResources();
        _isLoading = false;
      });
    }
  }
  
  String _parseDuration(String iso8601Duration) {
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(iso8601Duration);
    
    if (match != null) {
      final hours = match.group(1) != null ? int.parse(match.group(1)!) : 0;
      final minutes = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      final seconds = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      
      if (hours > 0) {
        return '$hours hr ${minutes} min';
      } else {
        return '$minutes min';
      }
    }
    
    return '0 min';
  }
  
  String _determineLevel(int viewCount) {
    if (viewCount > 100000) {
      return 'Beginner';
    } else if (viewCount > 50000) {
      return 'Intermediate';
    } else {
      return 'All Levels';
    }
  }
  
  bool _isVideoNew(String publishedAt) {
    final publishDate = DateTime.parse(publishedAt);
    final now = DateTime.now();
    final difference = now.difference(publishDate);
    
    return difference.inDays < 90;
  }
  
  List<LearningResource> _getStaticResources() {
    return [
      LearningResource(
        id: '1',
        title: 'Understanding Colors Through Sound',
        description: 'An interactive experience that translates colors into unique sounds, helping visually impaired users understand color concepts.',
        type: 'Interactive',
        imageUrl: 'https://i.ytimg.com/vi/sxwn1w7MJvk/hqdefault.jpg',
        duration: '15 min',
        level: 'Beginner',
        isNew: true,
        isPopular: true,
        youtubeId: 'sxwn1w7MJvk',
      ),
      LearningResource(
        id: '2',
        title: 'Navigating Public Transport',
        description: 'A step-by-step guide to using public transportation independently, with audio descriptions and tactile feedback.',
        type: 'Tutorial',
        imageUrl: null,
        duration: '30 min',
        level: 'Intermediate',
        isNew: false,
        isPopular: true,
        youtubeId: null,
      ),
      LearningResource(
        id: '3',
        title: 'Sign Language Basics',
        description: 'Learn essential sign language phrases with AI-generated visual guides and practice exercises.',
        type: 'Visual Learning',
        imageUrl: null,
        duration: '45 min',
        level: 'Beginner',
        isNew: true,
        isPopular: false,
        youtubeId: null,
      ),
      LearningResource(
        id: '4',
        title: 'Virtual Museum Tour',
        description: 'Experience famous artworks through detailed audio descriptions and tactile feedback using AR technology.',
        type: 'AR/VR',
        imageUrl: null,
        duration: '60 min',
        level: 'All Levels',
        isNew: false,
        isPopular: true,
        youtubeId: null,
      ),
      LearningResource(
        id: '5',
        title: 'Cooking with Audio Guidance',
        description: 'Learn to cook delicious meals with step-by-step audio instructions designed for visually impaired users.',
        type: 'Audio Learning',
        imageUrl: null,
        duration: '40 min',
        level: 'Intermediate',
        isNew: true,
        isPopular: false,
        youtubeId: null,
      ),
      LearningResource(
        id: '6',
        title: 'Tactile Mathematics',
        description: 'Explore mathematical concepts through tactile diagrams and interactive exercises.',
        type: 'Interactive',
        imageUrl: null,
        duration: '25 min',
        level: 'Beginner',
        isNew: false,
        isPopular: false,
        youtubeId: null,
      ),
      LearningResource(
        id: '7',
        title: 'Virtual Nature Walk',
        description: 'Experience the sounds and sensations of different natural environments through immersive VR.',
        type: 'AR/VR',
        imageUrl: null,
        duration: '30 min',
        level: 'All Levels',
        isNew: true,
        isPopular: true,
        youtubeId: null,
      ),
      LearningResource(
        id: '8',
        title: 'Accessible Yoga Practice',
        description: 'A guided yoga session with audio instructions and haptic feedback for proper positioning.',
        type: 'Exercise',
        imageUrl: null,
        duration: '20 min',
        level: 'Beginner',
        isNew: false,
        isPopular: true,
        youtubeId: null,
      ),
    ];
  }

  List<LearningResource> get _filteredResources {
    if (_resources == null) {
      return [];
    }
    
    if (_selectedCategoryIndex == 0) {
      return _resources!;
    } else {
      final category = _categories[_selectedCategoryIndex];
      return _resources!.where((resource) => resource.type == category).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Resources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // Navigate to saved resources
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchYouTubeVideos,
          ),
        ],
      ),
      body: _isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading YouTube videos...'),
                ],
              ),
            ) 
          : Column(
              children: [
                // Categories
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedCategoryIndex;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                _categories[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : null,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search resources...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Featured Resource
                if (_filteredResources.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Featured',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeaturedResourceCard(_filteredResources.first),
                      ],
                    ),
                  ),

                // Resources List
                Expanded(
                  child: _filteredResources.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No resources found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try selecting a different category',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              'All Resources',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...List.generate(
                              _filteredResources.length - 1,
                              (index) => _buildResourceCard(_filteredResources[index + 1]),
                            ),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showGenerateContentDialog(context);
        },
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFeaturedResourceCard(LearningResource resource) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // YouTube Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: resource.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: resource.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.error),
                    ),
                    colorBlendMode: BlendMode.darken,
                    color: Colors.black.withOpacity(0.3),
                  )
                : Image.asset(
                    'assets/images/placeholder.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    resource.type,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  resource.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Info
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      resource.duration,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.bar_chart,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      resource.level,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Play Button
          Positioned.fill(
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.play_arrow,
                    size: 36,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _openResource(resource);
                  },
                ),
              ),
            ),
          ),
          // YouTube Logo
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_arrow, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'YouTube',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(LearningResource resource) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openResource(resource),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // YouTube Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: resource.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: resource.imageUrl!,
                          fit: BoxFit.cover,
                          height: 180,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: Icon(Icons.error),
                          ),
                        )
                      : Container(
                          height: 180,
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                ),
                // YouTube Play Button
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Badges
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      if (resource.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (resource.isNew && resource.isPopular)
                        const SizedBox(width: 8),
                      if (resource.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Duration Badge
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      resource.duration,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      resource.type,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    resource.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    resource.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            resource.duration,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.bar_chart,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            resource.level,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.bookmark_border,
                          size: 20,
                        ),
                        onPressed: () {
                          // Save resource
                        },
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

  void _openResource(LearningResource resource) {
    // Check if this is our special dyslexic learning resource
    if (resource.id == '9') {
      // Navigate to the dyslexic learning screen
      GoRouter.of(context).go('/dyslexic-learning');
      return;
    }
    
    // Open YouTube video player for resources with youtubeId
    if (resource.youtubeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => YouTubePlayerScreen(
            resource: resource,
          ),
        ),
      );
      return;
    }
    
    // Original dialog for resources without youtubeId
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resource.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.description,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Type: ${resource.type}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Duration: ${resource.duration}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Level: ${resource.level}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Start the resource
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Learning'),
          ),
        ],
      ),
    );
  }

  void _showGenerateContentDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Custom Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our AI can create personalized learning content based on your needs.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'What would you like to learn about?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the topic you want to learn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Preferred format:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Visual'),
                  selected: true,
                  selectedColor: colorScheme.primaryContainer,
                  onSelected: (selected) {},
                ),
                ChoiceChip(
                  label: const Text('Audio'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                ChoiceChip(
                  label: const Text('Interactive'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                ChoiceChip(
                  label: const Text('AR/VR'),
                  selected: false,
                  onSelected: (selected) {},
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generating your custom learning content...'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}

class YouTubePlayerScreen extends StatefulWidget {
  final LearningResource resource;
  
  const YouTubePlayerScreen({
    Key? key,
    required this.resource,
  }) : super(key: key);
  
  @override
  _YouTubePlayerScreenState createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  late YoutubePlayerController _controller;
  late TextEditingController _noteController;
  List<String> _notes = [];
  bool _isFullScreen = false;
  
  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.resource.youtubeId!,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        captionLanguage: 'en',
        enableCaption: true,
      ),
    );
    
    _noteController = TextEditingController();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
        onReady: () {
          // Player is ready
        },
        topActions: [
          IconButton(
            icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: () {
              setState(() {
                _isFullScreen = !_isFullScreen;
              });
              
              if (_isFullScreen) {
                _controller.toggleFullScreenMode();
              }
            },
          ),
        ],
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: _isFullScreen 
              ? null 
              : AppBar(
                  title: Text(widget.resource.title),
                  backgroundColor: Colors.black,
                ),
          body: _isFullScreen
              ? Center(child: player)
              : Column(
                  children: [
                    player,
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.resource.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.resource.type,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.access_time, size: 16),
                                SizedBox(width: 4),
                                Text(widget.resource.duration),
                                SizedBox(width: 8),
                                Icon(Icons.bar_chart, size: 16),
                                SizedBox(width: 4),
                                Text(widget.resource.level),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              widget.resource.description,
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Your Notes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _noteController,
                                    decoration: InputDecoration(
                                      hintText: 'Add a note...',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_noteController.text.isNotEmpty) {
                                      setState(() {
                                        _notes.add(_noteController.text);
                                        _noteController.clear();
                                      });
                                    }
                                  },
                                  child: Text('Add'),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Expanded(
                              child: _notes.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No notes yet. Add your first note!',
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _notes.length,
                                      itemBuilder: (context, index) {
                                        return Card(
                                          margin: EdgeInsets.only(bottom: 8),
                                          child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(_notes[index]),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () {
                                                    setState(() {
                                                      _notes.removeAt(index);
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class LearningResource {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? imageUrl;
  final String duration;
  final String level;
  final bool isNew;
  final bool isPopular;
  final String? youtubeId;

  LearningResource({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.imageUrl,
    required this.duration,
    required this.level,
    required this.isNew,
    required this.isPopular,
    this.youtubeId,
  });
} 