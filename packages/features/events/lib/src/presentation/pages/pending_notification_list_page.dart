import 'package:integrations_database/integrations_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';

import '../../services/notification_service.dart';
import '../../utils/database_event_checker.dart';

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
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              final checker = DatabaseEventChecker(GetIt.I<AppDatabase>());

              // Check for duplicates
              await checker.checkRecurringEvents();
            },
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(
            onPressed: () async {
              final checker = DatabaseEventChecker(GetIt.I<AppDatabase>());

              // If duplicates found, clean them up
              await checker.cleanupDuplicateRecurringEvents();
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(index.toString())),
                  title: Text(item.title ?? "No title"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.body ?? "No body"),
                      const SizedBox(height: 4),
                      Text(item.payload ?? "No payload"),
                    ],
                  ),
                  trailing: Text(item.id.toString()),
                );
              },
            ),
    );
  }
}
