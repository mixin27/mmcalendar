// ignore_for_file: non_constant_identifier_names

import 'dart:js_interop';

// Main Telegram WebApp object
@JS('Telegram.WebApp')
extension type TelegramWebApp(JSObject _) implements JSObject {
  external WebAppInitData get initDataUnsafe;
  external ThemeParams get themeParams;
  external String get version;
  external String get platform;
  external String get colorScheme;
  external bool get isExpanded;
  external double get viewportHeight;
  external double get viewportStableHeight;
  external MainButton get mainButton;
  external BackButton get backButton;

  external void ready();
  external void expand();
  external void close();
  external void showAlert(String message);
  external void showConfirm(String message, JSFunction callback);
  external void showPopup(PopupParams params, JSFunction? callback);
  external void sendData(String data);
}

// WebApp Init Data
@JS()
extension type WebAppInitData(JSObject _) implements JSObject {
  external WebAppUser? get user;
  external WebAppChat? get chat;
  external String? get query_id;
  external String? get auth_date;
  external String? get hash;
}

// User object
@JS()
extension type WebAppUser(JSObject _) implements JSObject {
  external int get id;
  external bool? get is_bot;
  external String get first_name;
  external String? get last_name;
  external String? get username;
  external String? get language_code;
  external bool? get is_premium;
  external String? get photo_url;
}

// Chat object
@JS()
extension type WebAppChat(JSObject _) implements JSObject {
  external int get id;
  external String get type;
  external String get title;
  external String? get username;
  external String? get photo_url;
}

// Theme Parameters
@JS()
extension type ThemeParams(JSObject _) implements JSObject {
  external String? get bg_color;
  external String? get text_color;
  external String? get hint_color;
  external String? get link_color;
  external String? get button_color;
  external String? get button_text_color;
  external String? get secondary_bg_color;
}

// Main Button
@JS()
extension type MainButton(JSObject _) implements JSObject {
  external String get text;
  external String get color;
  external String get textColor;
  external bool get isVisible;
  external bool get isActive;
  external bool get isProgressVisible;

  external void setText(String text);
  external void onClick(JSFunction callback);
  external void offClick(JSFunction callback);
  external void show();
  external void hide();
  external void enable();
  external void disable();
  external void showProgress(bool leaveActive);
  external void hideProgress();
  external void setParams(MainButtonParams params);
}

// Back Button
@JS()
extension type BackButton(JSObject _) implements JSObject {
  external bool get isVisible;
  external void onClick(JSFunction callback);
  external void offClick(JSFunction callback);
  external void show();
  external void hide();
}

// Popup Parameters
@JS()
@anonymous
extension type PopupParams._(JSObject _) implements JSObject {
  external factory PopupParams({
    String? title,
    String message,
    JSArray<PopupButton>? buttons,
  });
}

// Popup Button
@JS()
@anonymous
extension type PopupButton._(JSObject _) implements JSObject {
  external factory PopupButton({String? id, String type, String? text});
}

// Main Button Parameters
@JS()
@anonymous
extension type MainButtonParams._(JSObject _) implements JSObject {
  external factory MainButtonParams({
    String? text,
    String? color,
    String? text_color,
    bool? is_active,
    bool? is_visible,
  });
}

// Access the global Telegram.WebApp object
@JS('Telegram.WebApp')
external TelegramWebApp get telegramWebApp;
