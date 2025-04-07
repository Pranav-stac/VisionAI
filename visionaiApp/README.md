# Vision AI

An assistive technology application that leverages AI to provide inclusive experiences for users with visual impairments.

## Features

### Speech to Image
The app now includes a powerful Speech to Image generation feature that creates visual representations of spoken words in real-time.

#### How it works:
1. Navigate to the "Speech to Image" feature from the home screen
2. Tap the microphone button to start listening
3. Speak clearly to describe what image you'd like to generate
4. After you finish speaking, the app will process your speech and generate a corresponding image
5. The generated image will be displayed on the screen along with your spoken text
6. You can tap the microphone again to generate a new image with different speech input

#### Technical details:
- Uses Flutter's speech_to_text package for voice recognition
- Supports multiple languages including English and Hindi
- Converts speech to text and sends the text to a generative AI API
- The API (pranavai.onrender.com/generate) creates an image based on the text description
- Images are displayed in real-time as they are generated

### Real-Time Captioning
Convert speech to text instantly for better communication.

### Voice Generation
Generate natural speech from text for better accessibility.

### Scene Description
Audio description of surroundings using camera input.

### Mental Health Support
AI-driven emotional support and resources.

### Volunteer Network
Connect with nearby helpers for assistance.

### Learning Resources
Educational content optimized for accessibility.

## Installation

```bash
flutter pub get
flutter run
```

## Requirements
- Flutter 3.0+
- Dart 2.17+
- Android 6.0+ or iOS 11.0+

## Troubleshooting
If you encounter Firebase-related errors when running the app, you may need to:
1. Update Firebase dependencies to the latest versions
2. Ensure you have the correct Firebase configuration in your project
3. Try running on a specific platform (e.g., `flutter run -d android` or `flutter run -d ios`)

## Technology Stack

- **Frontend**: Flutter for cross-platform mobile app development
- **Backend**: Flask for API services
- **Database**: Firebase for real-time data storage and authentication
- **AI Models**:
  - Paligenma model for scene detection, assisting blind users with navigation
  - Fal.AI Model for real-time visual image generation
  - Real-time, multilingual GenAI-powered Voicebot for personalized assistance
- **AR/VR**: Google ARKit for creating engaging, interactive educational experiences

## Project Structure

```
lib/
├── main.dart                  # Entry point of the application
├── theme/                     # Theme configuration
├── screens/                   # All app screens
│   ├── auth/                  # Authentication screens
│   ├── features/              # Feature-specific screens
│   ├── home/                  # Home screen
│   ├── onboarding/            # Onboarding screens
│   └── profile/               # User profile screens
├── widgets/                   # Reusable widgets
├── models/                    # Data models
├── services/                  # API and other services
└── utils/                     # Utility functions and constants
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Special thanks to all contributors and supporters of this project
- Inspired by the needs of specially-abled individuals in Mumbai and beyond
