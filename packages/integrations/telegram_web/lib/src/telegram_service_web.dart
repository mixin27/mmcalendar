import 'dart:async';
import 'dart:js_interop';
import 'telegram_service_base.dart';
import 'telegram_web_app.dart';

class TelegramServiceImpl implements TelegramService {
  static final TelegramServiceImpl _instance = TelegramServiceImpl._internal();
  factory TelegramServiceImpl() => _instance;
  TelegramServiceImpl._internal();

  TelegramWebApp? _webApp;

  @override
  void initialize() {
    try {
      final app = telegramWebApp;
      if (app.isDefinedAndNotNull) {
        _webApp = app;
        _webApp?.ready();
        _webApp?.expand();
      }
    } catch (e) {
      // Not in Telegram environment or script not loaded
    }
  }

  @override
  bool get isTelegram {
    if (_webApp != null) return true;
    try {
      final app = telegramWebApp;
      return app.isDefinedAndNotNull &&
          app?.platform != null &&
          app?.platform != 'unknown' &&
          app?.platform != '';
    } catch (e) {
      return false;
    }
  }

  TelegramWebApp? get webApp => isTelegram ? (_webApp ?? telegramWebApp) : null;

  @override
  String? getUserName() {
    return webApp?.initDataUnsafe.user?.username;
  }

  @override
  String? getUserFirstName() {
    return webApp?.initDataUnsafe.user?.first_name;
  }

  @override
  int? getUserId() {
    return webApp?.initDataUnsafe.user?.id;
  }

  @override
  void setMainButton({required String text, required void Function() onTap}) {
    final button = webApp?.mainButton;
    if (button != null) {
      button.setText(text);
      button.onClick(onTap.toJS);
      button.show();
    }
  }

  @override
  void hideMainButton() {
    webApp?.mainButton?.hide();
  }

  @override
  void showAlert(String message) {
    webApp?.showAlert(message);
  }

  @override
  void close() {
    webApp?.close();
  }

  @override
  String getThemeBackgroundColor() {
    return webApp?.themeParams.bg_color ?? '#ffffff';
  }

  @override
  void hapticImpact(String style) {
    webApp?.hapticFeedback?.impactOccurred(style);
  }

  @override
  void hapticNotification(String type) {
    webApp?.hapticFeedback?.notificationOccurred(type);
  }

  @override
  void hapticSelectionChanged() {
    webApp?.hapticFeedback?.selectionChanged();
  }

  @override
  Future<void> setCloudItem(String key, String value) {
    final storage = webApp?.cloudStorage;
    if (storage == null) return Future.value();

    final completer = Completer<void>();
    storage.setItem(
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
    final storage = webApp?.cloudStorage;
    if (storage == null) return Future.value(null);

    final completer = Completer<String?>();
    storage.getItem(
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
    webApp?.sendData(data);
  }
}
