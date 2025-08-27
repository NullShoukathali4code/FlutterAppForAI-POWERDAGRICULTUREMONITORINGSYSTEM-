import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> with TickerProviderStateMixin {
  final databaseRef = FirebaseDatabase.instance.ref();
  double _soilMoistureThreshold = 30.0;
  bool _enableFireAlerts = true;
  bool _enableAnimalAlerts = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fetchSettings();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: const Color(0xFF006400),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _fetchSettings() async {
    try {
      final snapshot = await databaseRef.child('/settings').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _soilMoistureThreshold = data['soil_moisture_threshold']?.toDouble() ?? 30.0;
          _enableFireAlerts = data['enable_fire_alerts'] ?? true;
          _enableAnimalAlerts = data['enable_animal_alerts'] ?? true;
        });
      }
    } catch (e) {
      print("Error fetching settings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF006400),
                Color(0xFF4CAF50),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header for General Settings
              _buildSectionHeader("General Settings", delay: 100),
              const SizedBox(height: 16),
              _buildSettingTile(
                title: "Soil Moisture Threshold",
                subtitle: "Alert when moisture drops below this level",
                iconPath: 'assets/icons/moisture.png',
                value: _soilMoistureThreshold,
                onChanged: (value) {
                  setState(() {
                    _soilMoistureThreshold = value;
                  });
                  databaseRef.child('/settings').update({'soil_moisture_threshold': value});
                  _showSnackBar("Soil moisture threshold updated to ${value.toInt()}%");
                },
                delay: 200,
              ),
              const SizedBox(height: 16),

              // Section Header for Alerts
              _buildSectionHeader("Alert Preferences", delay: 300),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: "Fire Alerts",
                subtitle: "Receive notifications for fire detection",
                iconPath: 'assets/icons/fire.png',
                value: _enableFireAlerts,
                onChanged: (value) {
                  setState(() {
                    _enableFireAlerts = value;
                  });
                  databaseRef.child('/settings').update({'enable_fire_alerts': value});
                  _showSnackBar(value ? "Fire alerts enabled" : "Fire alerts disabled");
                },
                delay: 400,
              ),
              _buildSwitchTile(
                title: "Animal Alerts",
                subtitle: "Receive notifications for animal detection",
                iconPath: 'assets/icons/paws.png',
                value: _enableAnimalAlerts,
                onChanged: (value) {
                  setState(() {
                    _enableAnimalAlerts = value;
                  });
                  databaseRef.child('/settings').update({'enable_animal_alerts': value});
                  _showSnackBar(value ? "Animal alerts enabled" : "Animal alerts disabled");
                },
                delay: 500,
              ),
              const SizedBox(height: 24),

              // Reset Button
              Center(
                child: ScaleOnTapAnimation(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _soilMoistureThreshold = 30.0;
                        _enableFireAlerts = true;
                        _enableAnimalAlerts = true;
                      });
                      databaseRef.child('/settings').update({
                        'soil_moisture_threshold': 30.0,
                        'enable_fire_alerts': true,
                        'enable_animal_alerts': true,
                      });
                      _showSnackBar("Settings reset to default");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006400),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/reset.png',
                          height: 24,
                          width: 24,
                          color: Colors.white,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.restore, size: 24, color: Colors.white);
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Reset to Defaults",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {int delay = 0}) {
    return SlideInAnimation(
      delay: delay,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006400),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required String iconPath,
    required double value,
    required Function(double) onChanged,
    int delay = 0,
  }) {
    return SlideInAnimation(
      delay: delay,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF5F5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF006400), Color(0xFF4CAF50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        iconPath,
                        height: 24,
                        width: 24,
                        color: Colors.white,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.settings, size: 24, color: Colors.white);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Current: ${value.toInt()}%",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF006400),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${value.toInt()}%",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006400),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF006400),
                        inactiveTrackColor: const Color(0xFFBDBDBD),
                        trackHeight: 4,
                        thumbColor: const Color(0xFF006400),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        overlayColor: const Color(0x1A006400),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        valueIndicatorColor: const Color(0xFF006400),
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      child: Slider(
                        value: value,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: "${value.toInt()}%",
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required String iconPath,
    required bool value,
    required Function(bool) onChanged,
    int delay = 0,
  }) {
    return SlideInAnimation(
      delay: delay,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF5F5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006400), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                iconPath,
                height: 24,
                width: 24,
                color: Colors.white,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.notifications, size: 24, color: Colors.white);
                },
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
              ),
            ),
            trailing: Transform.scale(
              scale: 1.2,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF006400),
                activeTrackColor: const Color(0xFF81C784),
                inactiveThumbColor: const Color(0xFFBDBDBD),
                inactiveTrackColor: const Color(0xFFE0E0E0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Animation Widgets
class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final int delay;

  const SlideInAnimation({Key? key, required this.child, this.delay = 0}) : super(key: key);

  @override
  _SlideInAnimationState createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<SlideInAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: FadeTransition(
        opacity: _controller,
        child: widget.child,
      ),
    );
  }
}

class ScaleOnTapAnimation extends StatefulWidget {
  final Widget child;

  const ScaleOnTapAnimation({Key? key, required this.child}) : super(key: key);

  @override
  _ScaleOnTapAnimationState createState() => _ScaleOnTapAnimationState();
}

class _ScaleOnTapAnimationState extends State<ScaleOnTapAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _animation,
        child: widget.child,
      ),
    );
  }
}