import 'dart:js_interop';
import 'telegram_service_base.dart';
import 'telegram_web_app.dart';

class TelegramServiceImpl implements TelegramService {
  static final TelegramServiceImpl _instance = TelegramServiceImpl._internal();
  factory TelegramServiceImpl() => _instance;
  TelegramServiceImpl._internal();

  late final TelegramWebApp webApp;

  @override
  void initialize() {
    webApp = telegramWebApp;
    webApp.ready();
    webApp.expand();
  }

  @override
  String? getUserName() {
    return webApp.initDataUnsafe.user?.username;
  }

  @override
  String? getUserFirstName() {
    return webApp.initDataUnsafe.user?.first_name;
  }

  @override
  int? getUserId() {
    return webApp.initDataUnsafe.user?.id;
  }

  @override
  void setMainButton({required String text, required void Function() onTap}) {
    webApp.mainButton.setText(text);
    webApp.mainButton.onClick(onTap.toJS);
    webApp.mainButton.show();
  }

  @override
  void hideMainButton() {
    webApp.mainButton.hide();
  }

  @override
  void showAlert(String message) {
    webApp.showAlert(message);
  }

  @override
  void close() {
    webApp.close();
  }

  @override
  String getThemeBackgroundColor() {
    return webApp.themeParams.bg_color ?? '#ffffff';
  }
}
