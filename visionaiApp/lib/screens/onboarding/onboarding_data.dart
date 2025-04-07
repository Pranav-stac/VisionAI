import 'package:flutter/material.dart';

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

final List<OnboardingItem> onboardingData = [
  OnboardingItem(
    title: 'Real-Time Captioning',
    description: 'Instantly convert speech to text for seamless communication, helping audio-impaired users stay connected in any conversation.',
    icon: Icons.closed_caption,
  ),
  OnboardingItem(
    title: 'AI Voice Generation',
    description: 'Empower non-verbal users with natural-sounding speech generation from text input, breaking communication barriers.',
    icon: Icons.record_voice_over,
  ),
  OnboardingItem(
    title: 'Audio Description',
    description: 'Provide visually impaired users with AI-powered scene recognition and voice-based guidance for better navigation.',
    icon: Icons.surround_sound,
  ),
  OnboardingItem(
    title: 'Mental Health Support',
    description: 'Access AI-driven emotional support through sentiment analysis, helping you maintain mental well-being.',
    icon: Icons.favorite,
  ),
  OnboardingItem(
    title: 'Volunteer Network',
    description: 'Connect with nearby volunteers for real-time assistance when you need it most, building a supportive community.',
    icon: Icons.people,
  ),
  OnboardingItem(
    title: 'Learning Resources',
    description: 'Explore personalized educational content with AI-generated images and interactive AR/VR experiences.',
    icon: Icons.school,
  ),
]; 