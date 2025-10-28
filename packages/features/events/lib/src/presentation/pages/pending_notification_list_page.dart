import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';

import '../../services/notification_service.dart';

class PendingNotificationListPage extends StatefulWidget {
  const PendingNotificationListPage({super.key});

  @override
  State<PendingNotificationListPage> createState() =>
      _PendingNotificationListPageState();
}

class _PendingNotificationListPageState
    extends State<PendingNotificationListPage> {
  List<PendingNotificationRequest> _items = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notificationService = GetIt.I<NotificationService>();
    final pendingNotifications = await notificationService
        .getPendingNotifications();
    setState(() {
      _items = pendingNotifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item.id.toString()),
                  subtitle: Column(
                    children: [
                      Text(item.title ?? "No title"),
                      const SizedBox(height: 4),
                      Text(item.body ?? "No body"),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
