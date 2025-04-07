import 'package:flutter/material.dart';
import 'package:visionai/screens/auth/login_screen.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final List<String> _tabTitles = ['Personal', 'Settings', 'Activity'];
  int _selectedTabIndex = 0;
  
  // Controllers
  late TabController _tabController;
  
  // Single animation controller for simpler management
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();
  
  // Remove the duplicate _userData declaration and combine with hardcoded values
  final Map<String, dynamic> _userData = {
    'fullName': 'Tom Stark',
    'email': 'tomstark159@gmail.com',
    'type': 'User',
    'createdAt': "2025-03-23T10:43:35.569636",
    'verified': true,
    'online': true,
    'photo_url': "https://lh3.googleusercontent.com/a/ACg8ocIbAr9hUpJBe6Xoa7WhbpP5Q-vmPgWkRz2_QtnNa8H6MESpjQ=s96-c",
  };
  
  bool _isLoading = false; // Changed to false since we're using hardcoded data

  @override
  void initState() {
    super.initState();
    
    // Setup tab controller
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
        // Trigger animation when tab changes
        _animationController.forward(from: 0.0);
      }
    });
    
    // Setup animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Start initial animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    // Dark theme colors
    final backgroundColor = Colors.black;
    final cardColor = const Color(0xFF121212);
    final primaryColor = Colors.blueAccent;
    final secondaryColor = Colors.white.withOpacity(0.8);
    final accentColor = Colors.blue;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      _userData['fullName'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    _userData['photo_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverFillRemaining(
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Tab Bar
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          height: 50,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: primaryColor,
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white70,
                            dividerColor: Colors.transparent,
                            splashBorderRadius: BorderRadius.circular(25),
                            tabs: _tabTitles.map((title) => 
                              Tab(text: title)
                            ).toList(),
                          ),
                        ),

                        const SizedBox(height: 16),
                        
                        // Tab content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: child,
                                );
                              },
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // Personal Tab
                                  _buildTabContent(_buildPersonalTab(context)),
                                  
                                  // Settings Tab
                                  _buildTabContent(_buildSettingsTab(context)),
                                  
                                  // Activity Tab
                                  _buildTabContent(_buildActivityTab(context)),
                                ],
                              ),
                            ),
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

  // Create consistent container for tab content
  Widget _buildTabContent(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  // Personal Tab
  Widget _buildPersonalTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildSectionTitle(context, 'Account Information'),
          _buildSettingItem(
            context,
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: 'Name, email, phone number',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.security,
            title: 'Security',
            subtitle: 'Password, 2FA, privacy',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English (US)',
            onTap: () {},
          ),
          
          const SizedBox(height: 16),
          _buildSectionTitle(context, 'Linked Accounts'),
          _buildSettingItem(
            context,
            icon: Icons.facebook,
            title: 'Facebook',
            subtitle: 'Not connected',
            isSwitch: true,
            switchValue: false,
            onSwitchChanged: (value) {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.g_mobiledata_rounded,
            title: 'Google',
            subtitle: 'Connected',
            isSwitch: true,
            switchValue: true,
            onSwitchChanged: (value) {},
          ),
          
          // Logout Button
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                // Logout confirmation
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  // Settings Tab
  Widget _buildSettingsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildSectionTitle(context, 'App Preferences'),
          _buildSettingItem(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage all notifications',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            isSwitch: true,
            switchValue: true,
            onSwitchChanged: (value) {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.volume_up_outlined,
            title: 'Sound Effects',
            isSwitch: true,
            switchValue: true,
            onSwitchChanged: (value) {},
          ),
          
          const SizedBox(height: 16),
          _buildSectionTitle(context, 'Accessibility'),
          _buildSettingItem(
            context,
            icon: Icons.visibility,
            title: 'Visual Preferences',
            subtitle: 'Font size, contrast, animations',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.hearing,
            title: 'Audio Preferences',
            subtitle: 'Volume levels, closed captions',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.touch_app,
            title: 'Touch & Interaction',
            subtitle: 'Haptics, gestures, sensitivity',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            isSwitch: true,
            switchValue: true,
            onSwitchChanged: (value) {},
          ),
        ],
      ),
    );
  }
  
  // Activity Tab
  Widget _buildActivityTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildSectionTitle(context, 'Recent Activity'),
          
          // Empty state with better styling
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history,
                    size: 40,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your activity will appear here once you start using the app features.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to features
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Explore Features'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          _buildSectionTitle(context, 'Support'),
          _buildSettingItem(
            context,
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'FAQs and troubleshooting',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.feedback_outlined,
            title: 'Feedback',
            subtitle: 'Help us improve the app',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: Colors.grey[800],
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool isSwitch = false,
    bool? switchValue,
    Function(bool)? onSwitchChanged,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSwitch ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Switch or arrow
                  isSwitch
                      ? Switch(
                          value: switchValue ?? false,
                          onChanged: onSwitchChanged,
                          activeColor: Colors.blue,
                          inactiveThumbColor: Colors.grey[600],
                          inactiveTrackColor: Colors.grey[800],
                        )
                      : const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}