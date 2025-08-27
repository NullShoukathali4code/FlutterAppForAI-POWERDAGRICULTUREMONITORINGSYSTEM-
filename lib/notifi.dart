import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  const NotificationsScreen({Key? key, required this.notifications}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _notifications;
  late List<Map<String, dynamic>> _filteredNotifications;
  late List<Map<String, dynamic>> _clearedNotifications = [];
  bool _isLoading = false;
  bool _showCleared = false;
  String _currentFilter = 'All';
  late DatabaseReference _alertsRef;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _notifications = List.from(widget.notifications);
    _filteredNotifications = List.from(_notifications);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _initializeFirebase();
    _fadeController.forward();
  }

  void _initializeFirebase() {
    _alertsRef = FirebaseDatabase.instance.reference().child('alerts');
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });
    // Implement your Firebase data fetching logic here
    setState(() {
      _isLoading = false;
    });
  }

  void _handleDismiss(Map<String, dynamic> notification) {
    // Remove the notification from the active list and add it to cleared notifications
    setState(() {
      _notifications.remove(notification);
      _clearedNotifications.add(notification);
      _applyFilter(_currentFilter);
    });
  }

  void _toggleShowCleared() {
    setState(() {
      _showCleared = !_showCleared;
      _applyFilter(_currentFilter);
    });
  }

  void _clearAllNotifications() {
    setState(() {
      _clearedNotifications.addAll(_notifications);
      _notifications.clear();
      _applyFilter(_currentFilter);
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Alerts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ...['All', 'Urgent', 'Animals', 'Birds', 'Moisture', 'Fire'].map((filter) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Image.asset(
                      _currentFilter == filter
                          ? 'assets/icons/radio_selected.png'
                          : 'assets/icons/radio_unselected.png',
                      width: 24,
                      height: 24,
                    ),
                    title: Text(
                      filter,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: _currentFilter == filter
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      _applyFilter(filter);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006400),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 0,
                  ),
                  child: const Text('Apply Filter'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      if (_showCleared) {
        _filteredNotifications = _clearedNotifications.where((notification) {
          return filter == 'All' ||
              (filter == 'Urgent' && notification['isUrgent'] == true) ||
              (notification['message']?.toString().toLowerCase().contains(filter.toLowerCase()) ?? false);
        }).toList();
      } else {
        _filteredNotifications = _notifications.where((notification) {
          return filter == 'All' ||
              (filter == 'Urgent' && notification['isUrgent'] == true) ||
              (notification['message']?.toString().toLowerCase().contains(filter.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  Widget _getNotificationIcon(String message, bool isUrgent) {
    if (isUrgent) {
      return Image.asset('assets/icons/warning-sign.png', width: 24, height: 24, color: Colors.white);
    }
    if (message.toLowerCase().contains('animal')) {
      return Image.asset('assets/icons/paws.png', width: 24, height: 24, color: Colors.white);
    }
    if (message.toLowerCase().contains('bird')) {
      return Image.asset('assets/icons/bird.png', width: 24, height: 24, color: Colors.white);
    }
    if (message.toLowerCase().contains('moisture')) {
      return Image.asset('assets/icons/moisture.png', width: 24, height: 24, color: Colors.white);
    }
    if (message.toLowerCase().contains('fire')) {
      return Image.asset('assets/icons/fire.png', width: 24, height: 24, color: Colors.white);
    }
    return Image.asset('assets/icons/noti.png', width: 24, height: 24, color: Colors.white);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Alerts',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 22,
                letterSpacing: 0.5
            )
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF006400),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/filter_icon.png',
              width: 24,
              height: 24,
              color: Colors.white,
            ),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _fetchNotifications,
          color: const Color(0xFF006400),
          backgroundColor: Colors.white,
          displacement: 40,
          edgeOffset: 20,
          strokeWidth: 2.5,
          child: CustomScrollView(
            slivers: [
              if (_filteredNotifications.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final notification = _filteredNotifications[index];
                        return Dismissible(
                          key: Key('${notification['timestamp']}-${notification['message']}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red[400],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: Image.asset(
                              'assets/icons/delete.png',
                              width: 30,
                              height: 30,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) => _handleDismiss(notification),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: _buildNotificationCard(notification),
                          ),
                        );
                      },
                      childCount: _filteredNotifications.length,
                    ),
                  ),
                )
              else
                SliverFillRemaining(
                  child: _buildEmptyState(),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final String message = notification['message']?.toString() ?? 'Unknown Notification';
    final String timestamp = notification['timestamp']?.toString() ?? 'No timestamp';
    final bool isUrgent = notification['isUrgent'] == true;
    final DateTime? dateTime = DateTime.tryParse(timestamp);
    return GestureDetector(
      onTap: () => _showNotificationDetails(notification),
      child: Container(
        decoration: BoxDecoration(
          color: isUrgent ? Colors.red[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red[400] : const Color(0xFF006400),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _getNotificationIcon(message, isUrgent),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isUrgent ? Colors.red[800] : Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateTime != null
                          ? '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} • ${dateTime.day}/${dateTime.month}/${dateTime.year}'
                          : timestamp,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUrgent ? Colors.red[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(
                isUrgent ? 'assets/icons/warning.png' : 'assets/icons/noti.png',
                width: 20,
                height: 20,
                color: isUrgent ? Colors.red[400] : const Color(0xFF006400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/icons/noti.png',
              width: 48,
              height: 48,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _showCleared
              ? 'No cleared notifications'
              : _currentFilter == 'All'
              ? 'No notifications yet'
              : 'No ${_currentFilter.toLowerCase()} notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'You will see important alerts here when they occur in your field',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: Image.asset(
            'assets/icons/refresh_icon.png',
            width: 20,
            height: 20,
            color: Colors.white,
          ),
          label: const Text('Refresh'),
          onPressed: _fetchNotifications,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'archive_btn',
          onPressed: _toggleShowCleared,
          mini: true,
          backgroundColor: _showCleared ? Colors.orange : const Color(0xFF006400),
          elevation: 2,
          child: Image.asset(
            _showCleared ? 'assets/icons/unarchive_icon.png' : 'assets/icons/archive_icon.png',
            width: 20,
            height: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'clear_btn',
          onPressed: _clearAllNotifications,
          backgroundColor: const Color(0xFF006400),
          elevation: 2,
          child: Image.asset(
            'assets/icons/clear_icon.png',
            width: 24,
            height: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'filter_btn',
          onPressed: _showFilterOptions,
          mini: true,
          backgroundColor: const Color(0xFF006400),
          elevation: 2,
          child: Image.asset(
            'assets/icons/filter_icon.png',
            width: 20,
            height: 20,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    final String message = notification['message']?.toString() ?? 'Unknown Notification';
    final bool isUrgent = notification['isUrgent'] == true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isUrgent ? Colors.red[50] : const Color(0xFF006400).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isUrgent
                          ? Image.asset(
                        'assets/icons/urgent_icon.png',
                        width: 40,
                        height: 40,
                        color: const Color(0xFF006400),
                      )
                          : _getNotificationIcon(message, isUrgent),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    notification['timestamp']?.toString() ?? 'No timestamp',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (isUrgent) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/warning.png',
                          width: 20,
                          height: 20,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'URGENT ALERT',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This requires your immediate attention. Please check your field as soon as possible.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF006400),
                          side: const BorderSide(color: Color(0xFF006400)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    if (isUrgent) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Add your action handling here
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: const Text('Take Action'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}