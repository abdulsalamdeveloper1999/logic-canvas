import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'REVENUE_CAT', obfuscate: true)
  static final String revenueCatApiKey = _Env.revenueCatApiKey;
}
