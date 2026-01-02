import 'dart:js_interop';

import 'telegram_web_app.dart';

class TelegramService {
  static final TelegramService _instance = TelegramService._internal();
  factory TelegramService() => _instance;
  TelegramService._internal();

  late final TelegramWebApp webApp;

  void initialize() {
    webApp = telegramWebApp;
    webApp.ready();
    webApp.expand();
  }

  String? getUserName() {
    return webApp.initDataUnsafe.user?.username;
  }

  String? getUserFirstName() {
    return webApp.initDataUnsafe.user?.first_name;
  }

  int? getUserId() {
    return webApp.initDataUnsafe.user?.id;
  }

  void setMainButton({required String text, required void Function() onTap}) {
    webApp.mainButton.setText(text);
    webApp.mainButton.onClick(onTap.toJS);
    webApp.mainButton.show();
  }

  void hideMainButton() {
    webApp.mainButton.hide();
  }

  void showAlert(String message) {
    webApp.showAlert(message);
  }

  void close() {
    webApp.close();
  }

  String getThemeBackgroundColor() {
    return webApp.themeParams.bg_color ?? '#ffffff';
  }
}
