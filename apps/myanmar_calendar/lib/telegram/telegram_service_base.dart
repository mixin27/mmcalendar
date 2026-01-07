abstract class TelegramService {
  void initialize();
  String? getUserName();
  String? getUserFirstName();
  int? getUserId();
  void setMainButton({required String text, required void Function() onTap});
  void hideMainButton();
  void showAlert(String message);
  void close();
  String getThemeBackgroundColor();
}
