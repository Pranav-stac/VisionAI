import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visionai/screens/features/captioning_screen.dart';
import 'package:visionai/screens/features/voice_generation_screen.dart';

import 'package:visionai/screens/features/volunteer_network_screen.dart';
import 'package:visionai/screens/features/learning_resources_screen.dart';
import 'package:visionai/screens/features/image_captioning_screen.dart';
import 'package:visionai/screens/features/mental_health_screen.dart';
import 'package:visionai/widgets/feature_card.dart';
import 'package:visionai/screens/profile/profile_screen.dart';
import 'package:visionai/screens/features/communities_screen.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const HomeContent(),
    const VolunteerNetworkScreen(),
    const CommunitiesScreen(),
    const ProfileScreen(),
    
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : const Color(0xFF1C1C1E),
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Volunteers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: 'Communities',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'How can we assist you today?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: colorScheme.primary,
                        onPressed: () {
                          // Navigate to notifications
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuickActionCard(
                    context,
                    icon: Icons.mic,
                    title: 'Voice to Text',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CaptioningScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.image,
                    title: 'Realtime Captioning',
                    color: Colors.amber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImageCaptioningScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.record_voice_over,
                    title: 'Text to Voice',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VoiceGenerationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.camera_alt,
                    title: 'Scene Description',
                    color: Colors.purple,
                    onTap: () async {
                      try {
                        final Uri url = Uri.parse('https://useful-herring-radically.ngrok-free.app');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not launch the URL')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.help_outline,
                    title: 'Get Help',
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VolunteerNetworkScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Main Features
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Text(
                'Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: [
           
                  FeatureCard(
                    title: 'Realtime Captioning',
                    description: 'Generate images from speech',
                    icon: Icons.image,
                    color: Colors.amber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImageCaptioningScreen(),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    title: 'Voice Generation',
                    description: 'Generate natural speech from text',
                    icon: Icons.record_voice_over,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VoiceGenerationScreen(),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    title: 'Scene Description',
                    description: 'Audio description of surroundings',
                    icon: Icons.camera_alt,
                    color: Colors.purple,
                    onTap: () async {
                      final Uri url = Uri.parse('https://useful-herring-radically.ngrok-free.app');
                      try {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                          webViewConfiguration: const WebViewConfiguration(
                            enableJavaScript: true,
                            enableDomStorage: true,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not launch scene description: ${e.toString()}')),
                        );
                      }
                    },
                  ),
                  FeatureCard(
                    title: 'Mental Health',
                    description: 'AI-driven emotional support',
                    icon: Icons.favorite,
                    color: Colors.red,
                    onTap: () async {
                      final Uri url = Uri.parse('https://useful-herring-radically.ngrok-free.app');
                      try {
                        // Use a more reliable approach for launching URLs
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                          webViewConfiguration: const WebViewConfiguration(
                            enableJavaScript: true,
                            enableDomStorage: true,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not launch mental health support: ${e.toString()}')),
                        );
                      }
                    },
                  ),
                  FeatureCard(
                    title: 'Volunteer Network',
                    description: 'Connect with nearby helpers',
                    icon: Icons.people,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VolunteerNetworkScreen(),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    title: 'Learning Resources',
                    description: 'Educational content & AR/VR',
                    icon: Icons.school,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LearningResourcesScreen(),
                        ),
                      );
                    },
                  ),
                 
                ],
              ),
            ),

          
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required String title,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Used $title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
} 