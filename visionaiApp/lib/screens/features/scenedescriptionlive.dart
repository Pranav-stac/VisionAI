import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class SceneDescriptionlive extends StatefulWidget {
  const SceneDescriptionlive({super.key});

  @override
  State<SceneDescriptionlive> createState() => _SceneDescriptionliveState();
}

class _SceneDescriptionliveState extends State<SceneDescriptionlive> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  final String _webUrl = 'https://voice.praanav.in';

  @override
  void initState() {
    super.initState();
    
    // Request camera and microphone permissions at startup
    _requestPermissions();
  }

  // Request camera and microphone permissions
  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: Uri.parse(_webUrl)),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                mediaPlaybackRequiresUserGesture: false,
                useShouldOverrideUrlLoading: true,
                useOnLoadResource: true,
                javaScriptEnabled: true,
                javaScriptCanOpenWindowsAutomatically: true,
              ),
            ),
            onWebViewCreated: (InAppWebViewController controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
            },
            onLoadError: (controller, url, code, message) {
              print('WebView error: $message');
            },
            androidOnPermissionRequest: (controller, origin, resources) async {
              // Auto-grant camera and microphone permissions
              return PermissionRequestResponse(
                resources: resources,
                action: PermissionRequestResponseAction.GRANT,
              );
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
