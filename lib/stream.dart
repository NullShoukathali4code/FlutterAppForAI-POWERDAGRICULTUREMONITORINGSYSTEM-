import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

class VideoStreamScreen extends StatefulWidget {
  const VideoStreamScreen({Key? key}) : super(key: key);

  @override
  State<VideoStreamScreen> createState() => _VideoStreamScreenState();
}

class _VideoStreamScreenState extends State<VideoStreamScreen> {
  bool isLoading = true;
  bool _isDeviceOn = false;

  final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (String url) {},
      ),
    );

  @override
  void initState() {
    super.initState();
    _checkDeviceStatus();

    // Set a timeout to hide the loading spinner just in case
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => isLoading = false);
    });

    // Set the correct video stream URL
    _controller.loadRequest(Uri.parse('http://192.168.223.122:5000/video'));
  }

  void _checkDeviceStatus() async {
    final databaseRef = FirebaseDatabase.instance.ref().child('device/status');
    final statusSnapshot = await databaseRef.get();
    String? status = statusSnapshot.value as String?;
    if (mounted) {
      setState(() {
        _isDeviceOn = (status == "on");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Camera',
          style: TextStyle(
            color: Color(0xFF006400),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF006400)),
      ),
      body: _isDeviceOn
          ? Column(
        children: [
          if (isLoading)
            const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF006400)),
            ),
          Expanded(
            child: WebViewWidget(
              controller: _controller,
            ),
          ),
        ],
      )
          : const Center(
        child: Text(
          'Camera Not Detected',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
