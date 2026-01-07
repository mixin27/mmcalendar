import 'dart:async';
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
  bool get isTelegram => webApp.platform != 'unknown' && webApp.platform != '';

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

  @override
  void hapticImpact(String style) {
    webApp.hapticFeedback.impactOccurred(style);
  }

  @override
  void hapticNotification(String type) {
    webApp.hapticFeedback.notificationOccurred(type);
  }

  @override
  void hapticSelectionChanged() {
    webApp.hapticFeedback.selectionChanged();
  }

  @override
  Future<void> setCloudItem(String key, String value) {
    final completer = Completer<void>();
    webApp.cloudStorage.setItem(
      key,
      value,
      (JSBoolean error, JSBoolean success) {
        if (success.toDart) {
          completer.complete();
        } else {
          completer.completeError('Failed to set cloud item');
        }
      }.toJS,
    );
    return completer.future;
  }

  @override
  Future<String?> getCloudItem(String key) {
    final completer = Completer<String?>();
    webApp.cloudStorage.getItem(
      key,
      (JSBoolean error, JSString? value) {
        if (value != null) {
          completer.complete(value.toDart);
        } else {
          completer.complete(null);
        }
      }.toJS,
    );
    return completer.future;
  }

  @override
  void sendData(String data) {
    webApp.sendData(data);
  }
}
