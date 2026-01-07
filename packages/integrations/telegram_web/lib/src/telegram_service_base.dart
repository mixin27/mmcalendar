abstract class TelegramService {
  void initialize();
  bool get isTelegram;
  String? getUserName();
  String? getUserFirstName();
  int? getUserId();
  void setMainButton({required String text, required void Function() onTap});
  void hideMainButton();
  void showAlert(String message);
  void close();
  String getThemeBackgroundColor();

  // Haptics
  void hapticImpact(String style); // light, medium, heavy, rigid, soft
  void hapticNotification(String type); // error, success, warning
  void hapticSelectionChanged();

  // Cloud Storage (simplified for now)
  Future<void> setCloudItem(String key, String value);
  Future<String?> getCloudItem(String key);

  // Bot interaction
  void sendData(String data);
}
