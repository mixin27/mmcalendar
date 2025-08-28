import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: ".env")
abstract class Env {
  @EnviedField(varName: 'ONESIGNAL_APP_ID', obfuscate: true)
  static final String onesignalAppId = _Env.onesignalAppId;
}
