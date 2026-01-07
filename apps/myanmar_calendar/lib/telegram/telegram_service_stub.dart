import 'telegram_service_base.dart';

class TelegramServiceImpl implements TelegramService {
  static final TelegramServiceImpl _instance = TelegramServiceImpl._internal();
  factory TelegramServiceImpl() => _instance;
  TelegramServiceImpl._internal();

  @override
  void initialize() {
    // Stub implementation
  }

  @override
  String? getUserName() => null;

  @override
  String? getUserFirstName() => null;

  @override
  int? getUserId() => null;

  @override
  void setMainButton({required String text, required void Function() onTap}) {
    // Stub implementation
  }

  @override
  void hideMainButton() {
    // Stub implementation
  }

  @override
  void showAlert(String message) {
    // Stub implementation
  }

  @override
  void close() {
    // Stub implementation
  }

  @override
  String getThemeBackgroundColor() => '#ffffff';
}
