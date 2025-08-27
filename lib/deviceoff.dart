import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeviceOffScreen extends StatefulWidget {
  const DeviceOffScreen({Key? key}) : super(key: key);

  @override
  State<DeviceOffScreen> createState() => _DeviceOffScreenState();
}

class _DeviceOffScreenState extends State<DeviceOffScreen> {
  bool _isAttemptingReconnect = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E0F),
              Color(0xFF1A3A1A),
            ],
            stops: [0.1, 0.9],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Indicator
                _buildStatusIndicator(),
                const SizedBox(height: 40),

                // Title with proper text scaling
                _buildTitle(),
                const SizedBox(height: 20),

                // Description text
                _buildDescription(),
                const SizedBox(height: 50),

                // Reconnect button with state management
                _buildReconnectButton(context),
                const SizedBox(height: 30),

                // Troubleshooting link
                _buildTroubleshootingLink(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.4;
        return SizedBox(
          width: size,
          height: size,
          child: EnhancedPulseAnimation(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFA000).withOpacity(0.8),
                    const Color(0xFFFF6D00),
                  ],
                  stops: const [0.4, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6D00).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              padding: EdgeInsets.all(size * 0.2),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/icons/warning-sign.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return SlideInAnimation(
      delay: 300,
      child: Text(
        'DEVICE OFFLINE',
        style: TextStyle(
          fontSize: 28, // Reduced from 30 for better proportion
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return FadeInAnimation(
      delay: 500,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Please ensure your device is properly connected to power and turned on',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.85),
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildReconnectButton(BuildContext context) {
    return BounceAnimation(
      child: ScaleOnTapAnimation(
        onTap: _isAttemptingReconnect ? null : () => _attemptReconnection(context),
        child: Container(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _isAttemptingReconnect
                    ? Colors.grey
                    : const Color(0xFF00E676),
                _isAttemptingReconnect
                    ? Colors.grey.shade600
                    : const Color(0xFF00C853),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: _isAttemptingReconnect
                ? null
                : [
              BoxShadow(
                color: const Color(0xFF00C853).withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isAttemptingReconnect)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Image.asset(
                    'assets/icons/on-off-button.png',
                    height: 24,
                    width: 24,
                    color: Colors.white,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isAttemptingReconnect
                      ? 'CONNECTING...'
                      : 'POWER ON DEVICE',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTroubleshootingLink(BuildContext context) {
    return FadeInAnimation(
      delay: 700,
      child: TextButton(
        onPressed: () => _showTroubleshootingGuide(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Need help? ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: 'View troubleshooting guide',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _attemptReconnection(BuildContext context) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAttemptingReconnect = true;
      _reconnectAttempts++;
    });

    try {
      // Get the device status from Firebase
      final databaseRef = FirebaseDatabase.instance.ref().child('device/status');
      final statusSnapshot = await databaseRef.get();

      if (!mounted) return;

      if (statusSnapshot.exists) {
        final status = statusSnapshot.value as String?;
        if (status == "on") {
          // Device is on, navigate back to home screen
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }
      }

      // If we get here, device is still offline
      _showConnectionStatus(
        context,
        success: false,
        attempts: _reconnectAttempts,
        maxAttempts: _maxReconnectAttempts,
      );
    } catch (e) {
      // Handle any errors that occur during the Firebase query
      if (!mounted) return;
      _showConnectionStatus(
        context,
        success: false,
        attempts: _reconnectAttempts,
        maxAttempts: _maxReconnectAttempts,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isAttemptingReconnect = false);
      }
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _showMaxAttemptsReached(context);
    }
  }

  void _showConnectionStatus(
      BuildContext context, {
        required bool success,
        required int attempts,
        required int maxAttempts,
        String? errorMessage,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2B1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              Icon(
                success ? Icons.check_circle : Icons.error,
                size: 50,
                color: success ? const Color(0xFF00E676) : const Color(0xFFFF6D00),
              ),
              const SizedBox(height: 15),
              Text(
                success ? 'Connection Successful!' : 'Connection Failed',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage ??
                    (success
                        ? 'Your device is now online'
                        : 'Attempt $attempts of $maxAttempts failed'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              LinearProgressIndicator(
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  success
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFF6D00),
                ),
                value: success ? 1.0 : null,
                minHeight: 6,
              ),
              const SizedBox(height: 30),
              ScaleOnTapAnimation(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'DISMISS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMaxAttemptsReached(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2B1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber, color: Color(0xFFFF6D00)),
              const SizedBox(width: 10),
              Text(
                'Connection Failed',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Unable to establish connection after $_maxReconnectAttempts attempts. '
                'Please check your device and network settings.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showTroubleshootingGuide(context);
              },
              child: const Text(
                'TROUBLESHOOT',
                style: TextStyle(color: Color(0xFF00E676)),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _reconnectAttempts = 0);
                Navigator.pop(context);
              },
              child: const Text(
                'TRY AGAIN',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

// ... [Keep all other existing methods like _showTroubleshootingGuide, _buildTroubleshootingStep]
// ... [Keep all animation widgets at the bottom]
}

// ... [Keep all animation widget classes unchanged]

    void _showTroubleshootingGuide(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: EdgeInsets.all(20),
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E3A1E),
                    Color(0xFF0F1A0F),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              padding: EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Troubleshooting Guide',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      ScaleOnTapAnimation(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/icons/close-icon.png',
                          height: 24,
                          width: 24,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildTroubleshootingStep(
                    iconPath: 'assets/icons/power-icon.png',
                    title: 'Power Check',
                    description: 'Ensure the device is properly plugged in and the power switch is on',
                  ),
                  _buildTroubleshootingStep(
                    iconPath: 'assets/icons/cable-icon.png',
                    title: 'Cable Connection',
                    description: 'Check all cables are securely connected at both ends',
                  ),
                  _buildTroubleshootingStep(
                    iconPath: 'assets/icons/wifi-icon.png',
                    title: 'Network Status',
                    description: 'Verify your network connection is active and stable',
                  ),
                  _buildTroubleshootingStep(
                    iconPath: 'assets/icons/reset.png',
                    title: 'Restart Device',
                    description: 'Try power cycling the device by turning it off and on again',
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: ScaleOnTapAnimation(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        child: Text(
                          'GOT IT, THANKS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    Widget _buildTroubleshootingStep({
      required String iconPath,
      required String title,
      required String description,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF00C853).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  iconPath,
                  height: 20,
                  width: 20,
                  color: Color(0xFF00E676),
                ),
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }


  // Animation Widgets
  class FadeInAnimation extends StatefulWidget {
    final Widget child;
    final int delay;
    final Duration duration;

    const FadeInAnimation({
      Key? key,
      required this.child,
      this.delay = 0,
      this.duration = const Duration(milliseconds: 800),
    }) : super(key: key);

    @override
    _FadeInAnimationState createState() => _FadeInAnimationState();
  }

  class _FadeInAnimationState extends State<FadeInAnimation>
      with SingleTickerProviderStateMixin {
    late AnimationController _controller;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: widget.duration,
        vsync: this,
      );
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _controller.forward();
      });
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return FadeTransition(
        opacity: _controller,
        child: widget.child,
      );
    }
  }

  class SlideInAnimation extends StatefulWidget {
    final Widget child;
    final int delay;
    final Duration duration;
    final Offset beginOffset;

    const SlideInAnimation({
      Key? key,
      required this.child,
      this.delay = 0,
      this.duration = const Duration(milliseconds: 600),
      this.beginOffset = const Offset(0, 0.5),
    }) : super(key: key);

    @override
    _SlideInAnimationState createState() => _SlideInAnimationState();
  }

  class _SlideInAnimationState extends State<SlideInAnimation>
      with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<Offset> _animation;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: widget.duration,
        vsync: this,
      );
      _animation = Tween<Offset>(
        begin: widget.beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.fastOutSlowIn,
      ));
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _controller.forward();
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
        child: widget.child,
      );
    }
  }

  class EnhancedPulseAnimation extends StatefulWidget {
    final Widget child;
    final Duration duration;
    final double minScale;
    final double maxScale;

    const EnhancedPulseAnimation({
      Key? key,
      required this.child,
      this.duration = const Duration(milliseconds: 2000),
      this.minScale = 0.95,
      this.maxScale = 1.05,
    }) : super(key: key);

    @override
    _EnhancedPulseAnimationState createState() => _EnhancedPulseAnimationState();
  }

  class _EnhancedPulseAnimationState extends State<EnhancedPulseAnimation>
      with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<double> _scaleAnimation;
    late Animation<double> _opacityAnimation;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: widget.duration,
        vsync: this,
      )..repeat(reverse: true);
      _scaleAnimation = Tween<double>(begin: widget.minScale, end: widget.maxScale)
          .animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ));
      _opacityAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.0, 0.5, curve: Curves.easeOut),
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
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      );
    }
  }

  class BounceAnimation extends StatefulWidget {
    final Widget child;
    final Duration duration;
    final double bounceHeight;

    const BounceAnimation({
      Key? key,
      required this.child,
      this.duration = const Duration(milliseconds: 1500),
      this.bounceHeight = 0.05,
    }) : super(key: key);

    @override
    _BounceAnimationState createState() => _BounceAnimationState();
  }

  class _BounceAnimationState extends State<BounceAnimation>
      with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<double> _animation;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: widget.duration,
        vsync: this,
      )..repeat(reverse: true);
      _animation = Tween<double>(begin: 0, end: widget.bounceHeight).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.elasticOut,
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
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_animation.value * 100),
            child: child,
          );
        },
        child: widget.child,
      );
    }
  }

  class ScaleOnTapAnimation extends StatefulWidget {
    final Widget child;
    final VoidCallback? onTap;
    final double scale;
    final Duration duration;

    const ScaleOnTapAnimation({
      Key? key,
      required this.child,
      this.onTap,
      this.scale = 0.98,
      this.duration = const Duration(milliseconds: 100),
    }) : super(key: key);

    @override
    _ScaleOnTapAnimationState createState() => _ScaleOnTapAnimationState();
  }

  class _ScaleOnTapAnimationState extends State<ScaleOnTapAnimation>
      with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<double> _scaleAnimation;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: widget.duration,
        vsync: this,
      );
      _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale)
          .animate(_controller);
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
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      );
    }
  }