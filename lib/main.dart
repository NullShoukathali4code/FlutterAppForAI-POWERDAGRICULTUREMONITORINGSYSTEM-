import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'notifi.dart';
import 'settings.dart';
import 'deviceoff.dart';
import 'stream.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        appId: "1:763888345095:android:d69516cc06baf591f84aa2",
        apiKey: "AIzaSyAAB1caYC1mRcmvHmXcol6BQBUZc3OLY6E",
        messagingSenderId: "763888345095",
        projectId: "farmy-198d4",
        databaseURL: "https://farmy-198d4-default-rtdb.asia-southeast1.firebasedatabase.app",
        storageBucket: "farmy-198d4.appspot.com",
      ),
    );
    print("Firebase initialized successfully.");
  } catch (e) {
    print("Firebase initialization error: $e");
  }
  runApp(const MyApp());
}

class AppConstants {
  static const primaryColor = Color(0xFF006400);
  static const secondaryColor = Color(0xFF4CAF50);
  static const backgroundColor = Color(0xFFF8F9FA);
  static const textColorDark = Color(0xFF333333);
  static const textColorLight = Color(0xFF757575);

  static const animalTypes = ['cat', 'dog'];
  static const birdType = 'bird';

  static const detectionCardColors = [Color(0xFFFF5252), Color(0xFFFF867F)];
  static const noDetectionCardColors = [Color(0xFFE0E0E0), Color(0xFFEEEEEE)];

  static const Map<String, Map<String, dynamic>> moistureLevels = {
    'low': {'threshold': 30, 'color': Color(0xFFEF5350)},
    'medium': {'threshold': 60, 'color': Color(0xFFFFA726)},
    'optimal': {'color': Color(0xFF66BB6A)},
  };
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FERMY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      final databaseRef = FirebaseDatabase.instance.ref().child('device/status');
      final statusSnapshot = await databaseRef.get();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => (statusSnapshot.value as String?) == "on"
                ? const HomeScreen()
                : const DeviceOffScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DeviceOffScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FERMY',
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppConstants.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Connecting to your device...',
              style: TextStyle(
                color: AppConstants.textColorLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isDeviceOn = false;
  final Map<String, dynamic> _latestData = {
    'animal': {'status': 'NO Detection', 'timestamp': null},
    'bird': {'status': 'NO Detection', 'timestamp': null},
    'fire': {'status': 'NO Detection', 'timestamp': null},
    'moisture': {'level': 0, 'timestamp': null},
  };
  final List<Map<String, dynamic>> _notifications = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  StreamSubscription<DatabaseEvent>? _dataSubscription;
  StreamSubscription<DatabaseEvent>? _statusSubscription;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _initializeData();
    _fadeController.forward();
  }

  void _initializeData() {
    _statusSubscription = FirebaseDatabase.instance
        .ref()
        .child('device/status')
        .onValue
        .listen((event) {
      if (mounted) {
        final isOn = (event.snapshot.value as String?) == "on";
        setState(() {
          _isDeviceOn = isOn;
        });
        if (!isOn) {
          _clearAllDetections();
        }
      }
    });

    _dataSubscription = FirebaseDatabase.instance
        .ref()
        .child('agriculture_data')
        .onChildAdded
        .listen((event) {
      if (mounted && _isDeviceOn) {
        _processNewData(event.snapshot.value as Map<dynamic, dynamic>);
      }
    });
  }

  void _clearAllDetections() {
    setState(() {
      _latestData['animal'] = {'status': 'NO Detection', 'timestamp': null};
      _latestData['bird'] = {'status': 'NO Detection', 'timestamp': null};
      _latestData['fire'] = {'status': 'NO Detection', 'timestamp': null};
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _dataSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    try {
      final statusSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('device/status')
          .get();

      if (mounted) {
        setState(() {
          _isDeviceOn = (statusSnapshot.value as String?) == "on";
          if (!_isDeviceOn) {
            _clearAllDetections();
          }
        });
      }

      final dataSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('agriculture_data')
          .limitToLast(1)
          .get();

      if (dataSnapshot.exists && mounted) {
        final latestData = dataSnapshot.value as Map<dynamic, dynamic>;
        if (latestData.isNotEmpty) {
          final key = latestData.keys.first;
          _processNewData(latestData[key] as Map<dynamic, dynamic>);
        } else {
          setState(() {
            _clearAllDetections();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _processNewData(Map<dynamic, dynamic> data) {
    if (data['data'] == null) return;

    final detectionData = data['data'] as Map<dynamic, dynamic>;
    final timestamp = data['timestamp'] as String? ?? '';

    setState(() {
      // Handle fire detection first as it's independent
      if (detectionData['fire_detected'] == true) {
        _latestData['fire'] = {
          'status': 'Detected',
          'timestamp': timestamp,
        };
        _addNotification('FIRE detected in your field!', timestamp, isUrgent: true);
      } else {
        _latestData['fire'] = {
          'status': 'NO Detection',
          'timestamp': timestamp,
        };
      }

      // Handle moisture data
      if (detectionData['moisture_level'] != null) {
        _latestData['moisture'] = {
          'level': detectionData['moisture_level'],
          'timestamp': timestamp,
        };
        if (detectionData['moisture_alert'] == true) {
          _addNotification('Low moisture level detected!', timestamp);
        }
      }

      // Handle animal/bird detections
      if (detectionData['has_detection'] == false) {
        // Clear all detections when has_detection is false
        _latestData['animal'] = {
          'status': 'NO Detection',
          'timestamp': timestamp,
        };
        _latestData['bird'] = {
          'status': 'NO Detection',
          'timestamp': timestamp,
        };
      } else if (detectionData['detected_objects'] != null) {
        final objects = List<dynamic>.from(detectionData['detected_objects']);

        // Reset all detections first
        _latestData['animal'] = {
          'status': 'NO Detection',
          'timestamp': timestamp,
        };
        _latestData['bird'] = {
          'status': 'NO Detection',
          'timestamp': timestamp,
        };

        // Update specific detections if any
        if (objects.contains(AppConstants.birdType)) {
          _latestData['bird'] = {
            'status': 'Detected',
            'timestamp': timestamp,
          };
          _addNotification('Bird detected in your field!', timestamp);
        }

        if (objects.any((obj) => AppConstants.animalTypes.contains(obj))) {
          _latestData['animal'] = {
            'status': 'Detected',
            'timestamp': timestamp,
          };
          _addNotification('Animal detected in your field!', timestamp);
        }
      }
    });
  }

  void _addNotification(String message, String timestamp, {bool isUrgent = false}) {
    if (_notifications.any((n) => n['message'] == message && n['timestamp'] == timestamp)) {
      return;
    }

    setState(() {
      _notifications.insert(0, {
        'message': message,
        'timestamp': timestamp,
        'isUrgent': isUrgent,
        'isRead': false,
      });

      if (_notifications.length > 100) {
        _notifications.removeRange(100, _notifications.length);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final routes = [
      null,
      const VideoStreamScreen(),
      NotificationsScreen(notifications: _notifications),
      const Settings(),
    ];

    if (routes[index] != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => routes[index]!,
          transitionsBuilder: (context, animation, _, child) {
            if (index == 1) {
              return FadeTransition(opacity: animation, child: child);
            } else if (index == 2) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutQuart,
                )),
                child: child,
              );
            } else {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            }
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('FERMY'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isDeviceOn ? _buildOnlineContent() : _buildOfflineContent(),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildOfflineContent() {
    return ScaleTransition(
      scale: _scaleController,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20), // Added margin for better spacing
          decoration: BoxDecoration(
            color: Colors.white, // Changed to solid white for better contrast
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Replace with your custom icon - example using Image.asset
              Image.asset(
                'assets/icons/warning-sign.png', // Your custom icon path
                width: 80,
                height: 80,
                color: AppConstants.primaryColor, // Optional: tint to match theme
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.power_off_rounded, // Fallback if custom icon fails to load
                  size: 64,
                  color: Color(0xFF616161),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Device Offline',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your device connection',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14), // Increased padding
                  elevation: 2,
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.7),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppConstants.primaryColor,
          elevation: 10,
          items: [
            _buildNavItem(0, 'assets/icons/home.png', 'Home'),
            _buildNavItem(1, 'assets/icons/video-cam.png', 'Live'),
            _buildNavItem(2, 'assets/icons/noti.png', 'Alerts'),
            _buildNavItem(3, 'assets/icons/settings.png', 'Settings'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(int index, String iconPath, String label) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: _selectedIndex == index
              ? const LinearGradient(
            colors: [AppConstants.secondaryColor, Color(0xFF81C784)],
          )
              : null,
        ),
        child: Badge(
          isLabelVisible: index == 2 && _notifications.any((n) => !n['isRead']),
          child: Image.asset(
            iconPath,
            height: 24,
            width: 24,
            color: Colors.white,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                _getFallbackIcon(index),
                size: 24,
                color: Colors.white,
              );
            },
          ),
        ),
      ),
      label: label,
    );
  }

  // MODIFIED: Updated to fix overflow issues
  Widget _buildOnlineContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppConstants.primaryColor,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced padding from 16 to 12
        child: Column(
          children: [
            const SizedBox(height: 4), // Reduced from 8
            const Text(
              'Field Status Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColorDark,
              ),
            ),
            const SizedBox(height: 12), // Reduced from 16
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12, // Reduced from 16
                crossAxisSpacing: 12, // Reduced from 16
                childAspectRatio: 1.05, // Increased from 0.9 for more height
                children: [
                  _buildStatusCard(
                    title: 'Animal',
                    status: _latestData['animal']?['status'] ?? 'NO Detection',
                    iconPath: 'assets/icons/pa.png',
                    timestamp: _latestData['animal']?['timestamp'],
                  ),
                  _buildStatusCard(
                    title: 'Bird',
                    status: _latestData['bird']?['status'] ?? 'NO Detection',
                    iconPath: 'assets/icons/bird.png',
                    timestamp: _latestData['bird']?['timestamp'],
                  ),
                  _buildStatusCard(
                    title: 'Fire',
                    status: _latestData['fire']?['status'] ?? 'NO Detection',
                    iconPath: 'assets/icons/firess.png',
                    timestamp: _latestData['fire']?['timestamp'],
                  ),
                  _buildMoistureCard(
                    level: (_latestData['moisture']?['level'] ?? 0).toDouble(),
                    timestamp: _latestData['moisture']?['timestamp'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MODIFIED: Updated to fix overflow issues
  Widget _buildStatusCard({
    required String title,
    required String status,
    required String iconPath,
    required String? timestamp,
  }) {
    final isDetected = status.toLowerCase() != 'no detection';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Reduced from 20
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16), // Reduced from 20
        onTap: () => _showStatusDialog(title, status),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDetected
                  ? AppConstants.detectionCardColors
                  : AppConstants.noDetectionCardColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16), // Reduced from 20
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isDetected
                    ? ShakeAnimation(
                  child: _buildStatusIcon(iconPath, isDetected),
                )
                    : _buildStatusIcon(iconPath, isDetected),
              ),
              const SizedBox(height: 4), // Reduced from implicit spacing
              Column(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDetected ? Colors.white : AppConstants.textColorDark,
                    ),
                  ),
                  const SizedBox(height: 2), // Reduced from 4
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isDetected
                        ? PulseAnimation(
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                        : Text(
                      status,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppConstants.textColorLight,
                      ),
                    ),
                  ),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2), // Reduced from 4
                      child: Text(
                        'Updated: ${_formatTimestamp(timestamp)}',
                        style: TextStyle(
                          fontSize: 10, // Reduced from 12
                          color: isDetected
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MODIFIED: Smaller icon sizes
  Widget _buildStatusIcon(String iconPath, bool isDetected) {
    return Image.asset(
      iconPath,
      height: 50, // Reduced from 60
      width: 50, // Reduced from 60
      color: isDetected ? Colors.white : const Color(0xFF616161),
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          isDetected ? Icons.warning : Icons.check_circle,
          size: 50, // Reduced from 60
          color: isDetected ? Colors.white : const Color(0xFF616161),
        );
      },
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  void _showStatusDialog(String title, String status) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Status: $status',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MODIFIED: Optimized moisture card to prevent overflow
  Widget _buildMoistureCard({required double level, required String? timestamp}) {
    final int lowThreshold = AppConstants.moistureLevels['low']!['threshold'] as int;
    final int mediumThreshold = AppConstants.moistureLevels['medium']!['threshold'] as int;

    final moistureStatus = level < lowThreshold
        ? 'low'
        : level < mediumThreshold
        ? 'medium'
        : 'optimal';

    final moistureColor = AppConstants.moistureLevels[moistureStatus]!['color'] as Color;
    final moistureText = moistureStatus == 'low'
        ? 'Low Moisture'
        : moistureStatus == 'medium'
        ? 'Moderate'
        : 'Optimal';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Reduced from 20
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16), // Reduced from 20
        onTap: () => _showMoistureDialog(level),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                moistureColor.withOpacity(0.8),
                moistureColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16), // Reduced from 20
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60, // Reduced from 80
                    height: 60, // Reduced from 80
                    child: CircularProgressIndicator(
                      value: level / 100,
                      strokeWidth: 6, // Reduced from 8
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  Text(
                    '${level.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 18, // Reduced from 24
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4), // Added explicit spacing
              const Text(
                'Soil Moisture',
                style: TextStyle(
                  fontSize: 16, // Reduced from 18
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2), // Added explicit spacing
              Text(
                moistureText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              if (timestamp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2), // Reduced from 4
                  child: Text(
                    'Updated: ${_formatTimestamp(timestamp)}',
                    style: TextStyle(
                      fontSize: 10, // Reduced from 12
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoistureDialog(double level) {
    final int lowThreshold = AppConstants.moistureLevels['low']!['threshold'] as int;
    final int mediumThreshold = AppConstants.moistureLevels['medium']!['threshold'] as int;

    final moistureStatus = level < lowThreshold
        ? 'low'
        : level < mediumThreshold
        ? 'medium'
        : 'optimal';

    final moistureColor = AppConstants.moistureLevels[moistureStatus]!['color'] as Color;
    final moistureMessage = moistureStatus == 'low'
        ? 'Your soil needs watering!'
        : moistureStatus == 'medium'
        ? 'Soil moisture is acceptable'
        : 'Soil moisture is perfect';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppConstants.primaryColor.withOpacity(0.9),
                AppConstants.secondaryColor.withOpacity(0.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Soil Moisture Level',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: level / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(moistureColor),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${level.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          moistureStatus.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                moistureMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFallbackIcon(int index) {
    switch (index) {
      case 0: return Icons.home;
      case 1: return Icons.videocam;
      case 2: return Icons.notifications;
      case 3: return Icons.settings;
      default: return Icons.error;
    }
  }
}

class ShakeAnimation extends StatefulWidget {
  final Widget child;

  const ShakeAnimation({Key? key, required this.child}) : super(key: key);

  @override
  _ShakeAnimationState createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -0.05, end: 0.05)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class PulseAnimation extends StatefulWidget {
  final Widget child;

  const PulseAnimation({Key? key, required this.child}) : super(key: key);

  @override
  _PulseAnimationState createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}