import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

class Community {
  final String name;
  final String description;
  final String imageUrl;
  final String memberCount;
  final List<String> tags;
  final String category;
  final String foundedDate;
  final String adminName;
  final int eventsCount;
  final int postsCount;

  Community({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.memberCount,
    required this.tags,
    required this.category,
    required this.foundedDate,
    required this.adminName,
    required this.eventsCount,
    required this.postsCount,
  });
}

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = "All";
  final List<String> _filters = [
    "All",
    "Visual Impairment",
    "Hearing Impairment",
    "Physical Disability",
    "Cognitive Disability",
  ];

  final List<Community> communities = [
    // Visual Impairment Communities
    Community(
      name: "Visual Artists United",
      description: "A community for visually impaired artists to share their work and experiences",
      imageUrl: "https://images.unsplash.com/photo-1596727147705-61a532a659bd",
      memberCount: "2.5k",
      tags: ["Art", "Creativity", "Support"],
      category: "Visual Impairment",
      foundedDate: "Jan 2022",
      adminName: "Sarah Johnson",
      eventsCount: 45,
      postsCount: 1200,
    ),
    Community(
      name: "Tech Accessibility Hub",
      description: "Discussing and sharing the latest in accessible technology",
      imageUrl: "https://images.unsplash.com/photo-1518770660439-4636190af475",
      memberCount: "1.8k",
      tags: ["Technology", "Innovation", "Accessibility"],
      category: "Visual Impairment",
      foundedDate: "Mar 2022",
      adminName: "Mike Chen",
      eventsCount: 32,
      postsCount: 890,
    ),
    Community(
      name: "Braille Book Club",
      description: "Monthly book discussions and braille literacy support",
      imageUrl: "https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8",
      memberCount: "3.2k",
      tags: ["Books", "Education", "Braille"],
      category: "Visual Impairment",
      foundedDate: "Feb 2021",
      adminName: "Lisa Wong",
      eventsCount: 56,
      postsCount: 2300,
    ),
    Community(
      name: "Guide Dog Friends",
      description: "Support network for guide dog handlers and enthusiasts",
      imageUrl: "https://images.unsplash.com/photo-1558929996-da64ba858215",
      memberCount: "4.1k",
      tags: ["Guide Dogs", "Support", "Training"],
      category: "Visual Impairment",
      foundedDate: "Apr 2021",
      adminName: "David Miller",
      eventsCount: 78,
      postsCount: 3400,
    ),

    // Hearing Impairment Communities
    Community(
      name: "Sign Language Society",
      description: "Learn and practice sign language with our vibrant community",
      imageUrl: "https://images.unsplash.com/photo-1615839170544-24a8943244ff",
      memberCount: "4.2k",
      tags: ["Education", "Communication", "Culture"],
      category: "Hearing Impairment",
      foundedDate: "Dec 2021",
      adminName: "Emma Davis",
      eventsCount: 89,
      postsCount: 4500,
    ),
    Community(
      name: "Deaf Musicians Club",
      description: "Celebrating deaf and hard of hearing musicians",
      imageUrl: "https://images.unsplash.com/photo-1511379938547-c1f69419868d",
      memberCount: "2.9k",
      tags: ["Music", "Arts", "Performance"],
      category: "Hearing Impairment",
      foundedDate: "Jun 2022",
      adminName: "James Wilson",
      eventsCount: 42,
      postsCount: 1800,
    ),
    Community(
      name: "Silent Cinema Lovers",
      description: "Discussing and organizing accessible movie screenings",
      imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba",
      memberCount: "1.5k",
      tags: ["Movies", "Entertainment", "Accessibility"],
      category: "Hearing Impairment",
      foundedDate: "Sep 2022",
      adminName: "Maria Garcia",
      eventsCount: 24,
      postsCount: 750,
    ),
    Community(
      name: "Deaf Tech Hub",
      description: "Technology solutions and innovations for the deaf community",
      imageUrl: "https://images.unsplash.com/photo-1550751827-4bd374c3f58b",
      memberCount: "3.3k",
      tags: ["Technology", "Innovation", "Support"],
      category: "Hearing Impairment",
      foundedDate: "Jul 2021",
      adminName: "Alex Kim",
      eventsCount: 67,
      postsCount: 2800,
    ),

    // Physical Disability Communities
    Community(
      name: "Adaptive Sports League",
      description: "Connect with athletes and sports enthusiasts",
      imageUrl: "https://images.unsplash.com/photo-1591343395902-1adcb454c4e2",
      memberCount: "3.8k",
      tags: ["Sports", "Fitness", "Competition"],
      category: "Physical Disability",
      foundedDate: "May 2021",
      adminName: "Chris Thompson",
      eventsCount: 120,
      postsCount: 5600,
    ),
    Community(
      name: "Wheelchair Warriors",
      description: "Support and resources for wheelchair users",
      imageUrl: "https://images.unsplash.com/photo-1532629345422-7515f3d16bb6",
      memberCount: "5.2k",
      tags: ["Support", "Lifestyle", "Resources"],
      category: "Physical Disability",
      foundedDate: "Mar 2021",
      adminName: "Rachel Green",
      eventsCount: 95,
      postsCount: 4200,
    ),
    Community(
      name: "Accessible Travel Club",
      description: "Sharing travel tips and organizing accessible trips",
      imageUrl: "https://images.unsplash.com/photo-1488646953014-85cb44e25828",
      memberCount: "2.7k",
      tags: ["Travel", "Adventure", "Tips"],
      category: "Physical Disability",
      foundedDate: "Aug 2022",
      adminName: "Tom Parker",
      eventsCount: 38,
      postsCount: 1600,
    ),
    Community(
      name: "DIY Accessibility",
      description: "Sharing home modification tips and tricks",
      imageUrl: "https://images.unsplash.com/photo-1558910894-0fd4889b2e42",
      memberCount: "1.9k",
      tags: ["DIY", "Home", "Tips"],
      category: "Physical Disability",
      foundedDate: "Oct 2022",
      adminName: "Sam Lee",
      eventsCount: 28,
      postsCount: 920,
    ),

    // Cognitive Disability Communities
    Community(
      name: "Memory Masters",
      description: "Support group for memory enhancement and cognitive exercises",
      imageUrl: "https://images.unsplash.com/photo-1519682337058-a94d519337bc",
      memberCount: "2.4k",
      tags: ["Memory", "Support", "Exercise"],
      category: "Cognitive Disability",
      foundedDate: "Nov 2021",
      adminName: "Dr. Emily White",
      eventsCount: 52,
      postsCount: 1800,
    ),
    Community(
      name: "Learning Together",
      description: "Educational support and resources for cognitive challenges",
      imageUrl: "https://images.unsplash.com/photo-1522202176988-66273c2fd55f",
      memberCount: "3.1k",
      tags: ["Education", "Support", "Resources"],
      category: "Cognitive Disability",
      foundedDate: "Jan 2022",
      adminName: "Prof. Mark Brown",
      eventsCount: 64,
      postsCount: 2400,
    ),
    Community(
      name: "Brain Games Club",
      description: "Fun cognitive exercises and social activities",
      imageUrl: "https://images.unsplash.com/photo-1553481187-be93c21490a9",
      memberCount: "1.7k",
      tags: ["Games", "Social", "Activities"],
      category: "Cognitive Disability",
      foundedDate: "Apr 2022",
      adminName: "Linda Martinez",
      eventsCount: 45,
      postsCount: 980,
    ),
    Community(
      name: "Focus Friends",
      description: "Support network for attention and focus improvement",
      imageUrl: "https://images.unsplash.com/photo-1521737604893-d14cc237f11d",
      memberCount: "2.2k",
      tags: ["Focus", "Support", "Strategies"],
      category: "Cognitive Disability",
      foundedDate: "Jun 2022",
      adminName: "Peter Zhang",
      eventsCount: 36,
      postsCount: 1500,
    ),

    // Hearing Impairment Communities (add new ones)
    Community(
      name: "ASL Learning Network",
      description: "Interactive community for learning American Sign Language",
      imageUrl: "https://images.unsplash.com/photo-1596727147705-61a532a659bd",
      memberCount: "3.1k",
      tags: ["ASL", "Education", "Language"],
      category: "Hearing Impairment",
      foundedDate: "Aug 2022",
      adminName: "Robert Chen",
      eventsCount: 42,
      postsCount: 1500,
    ),
    Community(
      name: "Deaf Culture Hub",
      description: "Celebrating and sharing deaf culture and heritage",
      imageUrl: "https://images.unsplash.com/photo-1518770660439-4636190af475",
      memberCount: "2.8k",
      tags: ["Culture", "Community", "Events"],
      category: "Hearing Impairment",
      foundedDate: "Sep 2022",
      adminName: "Sarah Martinez",
      eventsCount: 38,
      postsCount: 1200,
    ),

    // Physical Disability Communities (add new ones)
    Community(
      name: "Adaptive Fitness Club",
      description: "Sharing adaptive workout routines and fitness tips",
      imageUrl: "https://images.unsplash.com/photo-1591343395902-1adcb454c4e2",
      memberCount: "2.5k",
      tags: ["Fitness", "Health", "Adaptive Sports"],
      category: "Physical Disability",
      foundedDate: "Oct 2022",
      adminName: "Mike Thompson",
      eventsCount: 45,
      postsCount: 1800,
    ),
    Community(
      name: "Mobility Innovation",
      description: "Discussing and sharing latest mobility solutions and technology",
      imageUrl: "https://images.unsplash.com/photo-1532629345422-7515f3d16bb6",
      memberCount: "3.3k",
      tags: ["Technology", "Innovation", "Mobility"],
      category: "Physical Disability",
      foundedDate: "Nov 2022",
      adminName: "Lisa Park",
      eventsCount: 32,
      postsCount: 1400,
    ),

    // Cognitive Disability Communities (add new ones)
    Community(
      name: "ADHD Support Network",
      description: "Support and strategies for adults with ADHD",
      imageUrl: "https://images.unsplash.com/photo-1519682337058-a94d519337bc",
      memberCount: "4.2k",
      tags: ["ADHD", "Support", "Strategies"],
      category: "Cognitive Disability",
      foundedDate: "Dec 2022",
      adminName: "David Wilson",
      eventsCount: 56,
      postsCount: 2100,
    ),
    Community(
      name: "Dyslexia Champions",
      description: "Resources and support for individuals with dyslexia",
      imageUrl: "https://images.unsplash.com/photo-1522202176988-66273c2fd55f",
      memberCount: "2.9k",
      tags: ["Dyslexia", "Education", "Support"],
      category: "Cognitive Disability",
      foundedDate: "Jan 2023",
      adminName: "Emma Taylor",
      eventsCount: 41,
      postsCount: 1600,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      "Communities",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          "https://images.unsplash.com/photo-1517486808906-6ca8b3f04846",
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_filters[index]),
                            selected: _selectedFilter == _filters[index],
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = _filters[index];
                              });
                            },
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            selectedColor: Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: _selectedFilter == _filters[index]
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 100,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final filteredCommunities = _selectedFilter == "All"
                            ? communities
                            : communities.where((c) => c.category == _selectedFilter).toList();

                        if (index >= filteredCommunities.length) {
                          return null;
                        }

                        return CommunityCard(
                          community: filteredCommunities[index],
                          onTap: _showCommunityDetails,
                        );
                      },
                      childCount: _selectedFilter == "All"
                          ? communities.length
                          : communities.where((c) => c.category == _selectedFilter).toList().length,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () {
            _showCreateCommunityDialog();
          },
          icon: const Icon(Icons.add),
          label: const Text("Create Community"),
        ),
      ),
    );
  }

  void _showCommunityDetails(Community community) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      community.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () {
                              // Implement share functionality
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      community.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      community.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      "Founded",
                      community.foundedDate,
                      Icons.calendar_today,
                    ),
                    _buildInfoRow(
                      "Admin",
                      community.adminName,
                      Icons.person,
                    ),
                    _buildInfoRow(
                      "Members",
                      community.memberCount,
                      Icons.people,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          "Events",
                          community.eventsCount.toString(),
                          Icons.event,
                        ),
                        _buildStatCard(
                          "Posts",
                          community.postsCount.toString(),
                          Icons.post_add,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Tags",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: community.tags.map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Implement join community functionality
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Join Community"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCommunityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Community'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Community Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _filters.map((filter) => DropdownMenuItem(
                  value: filter,
                  child: Text(filter),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement create community functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Community created successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class CommunityCard extends StatelessWidget {
  final Community community;
  final Function(Community) onTap;

  const CommunityCard({
    super.key, 
    required this.community,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => onTap(community),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                community.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    community.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        community.memberCount,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
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