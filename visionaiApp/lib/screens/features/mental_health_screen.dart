import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MentalHealthScreen extends StatefulWidget {
  const MentalHealthScreen({super.key});

  @override
  State<MentalHealthScreen> createState() => _MentalHealthScreenState();
}

class _MentalHealthScreenState extends State<MentalHealthScreen> {
  late WebViewController _webViewController;
  final String _url = 'https://useful-herring-radically.ngrok-free.app';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _requestMicrophoneAccessInWebView();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (JavaScriptMessage message) {
          // Handle messages from JavaScript
          debugPrint('Message from JS: ${message.message}');
        },
      );
    
    // Request microphone permission and load URL
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _loadUrl();
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Microphone permission is required for the mental health service';
      });
    }
  }

  void _loadUrl() {
    if (!_initialized) {
      _webViewController.loadRequest(Uri.parse(_url));
      _initialized = true;
    }
  }

  void _requestMicrophoneAccessInWebView() {
    // Add JavaScript to request microphone access
    _webViewController.runJavaScript('''
      navigator.mediaDevices.getUserMedia({ audio: true })
        .then(function(stream) {
          console.log('Microphone access granted in WebView');
          // Stop the stream since we just wanted to request permission
          stream.getTracks().forEach(track => track.stop());
        })
        .catch(function(err) {
          console.error('Error accessing microphone in WebView:', err);
          window.Flutter.postMessage('Microphone access error: ' + err.message);
        });
    ''');
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _loadUrl();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Wellbeing'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wellbeing Resources',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Placeholder content
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mental Health Support',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Our AI-driven emotional support system is designed to help you maintain mental wellness.',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Implementation for accessing mental health resources
                        },
                        child: Text('Explore Resources'),
                      ),
                    ],
                  ),
                ),
              ),
              // Add more wellbeing resources
            ],
          ),
        ),
      ),
    );
  }
} 