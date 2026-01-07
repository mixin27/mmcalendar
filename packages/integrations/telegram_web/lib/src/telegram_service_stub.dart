import 'telegram_service_base.dart';

class TelegramServiceImpl implements TelegramService {
  static final TelegramServiceImpl _instance = TelegramServiceImpl._internal();
  factory TelegramServiceImpl() => _instance;
  TelegramServiceImpl._internal();

  @override
  void initialize() {}

  @override
  bool get isTelegram => false;

  @override
  String? getUserName() => null;

  @override
  String? getUserFirstName() => null;

  @override
  int? getUserId() => null;

  @override
  void setMainButton({required String text, required void Function() onTap}) {}

  @override
  void hideMainButton() {}

  @override
  void showAlert(String message) {}

  @override
  void close() {}

  @override
  String getThemeBackgroundColor() => '#ffffff';

  @override
  void hapticImpact(String style) {}

  @override
  void hapticNotification(String type) {}

  @override
  void hapticSelectionChanged() {}

  @override
  Future<void> setCloudItem(String key, String value) async {}

  @override
  Future<String?> getCloudItem(String key) async => null;

  @override
  void sendData(String data) {}
}
