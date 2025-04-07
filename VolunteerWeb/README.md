# Vision AI Volunteer Portal

A volunteer-based website for specially-abled individuals, enabling connections between volunteers and those in need of assistance. The portal is designed to address challenges faced by individuals with visual, hearing, speech, mobility impairments, and cognitive disabilities.

## Features

- **Individual & Organization Registration**: Secure registration process with identity verification
- **Real-time Volunteer Matching**: Connect specially-abled individuals with appropriate volunteers
- **Multiple Assistance Categories**: Support for visual, hearing, speech, mobility, cognitive, and emotional assistance
- **Intuitive Dashboard**: Easy management of requests and volunteer activities
- **Profile Management**: Comprehensive profile customization for volunteers and organizations
- **Real-time Updates**: Firebase integration for instant notifications and updates

## Technology Stack

- **Frontend**: HTML, CSS, JavaScript, Bootstrap 5
- **Backend**: Flask (Python)
- **Database**: Firebase Realtime Database
- **Authentication**: Firebase Authentication
- **Storage**: Firebase Storage (for document uploads)

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/your-username/vision-ai-volunteer.git
   cd vision-ai-volunteer
   ```

2. Set up a virtual environment:
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

4. Set up your Firebase project:
   - Create a new project on [Firebase Console](https://console.firebase.google.com/)
   - Set up Authentication (Email/Password)
   - Set up Realtime Database
   - Set up Storage
   - Copy your Firebase configuration

5. Create a `.env` file in the root directory with your Firebase configuration:
   ```
   FIREBASE_API_KEY=your_api_key
   FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
   FIREBASE_DATABASE_URL=https://your_project_id.firebaseio.com
   FIREBASE_PROJECT_ID=your_project_id
   FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com
   FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
   FIREBASE_APP_ID=your_app_id
   
   FLASK_SECRET_KEY=generate_a_secure_random_key_here
   FLASK_ENV=development
   ```

6. Run the application:
   ```
   flask run
   ```

7. Open your browser and navigate to `http://127.0.0.1:5000`

## Project Structure

- `app.py` - Main Flask application
- `templates/` - HTML templates
- `static/` - Static files (CSS, JS, images)
- `instance/` - Temporary storage for file uploads

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

Your Name - your.email@example.com

Project Link: [https://github.com/your-username/vision-ai-volunteer](https://github.com/your-username/vision-ai-volunteer)