import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pocketmind/api/auth_pm_service.dart';
import 'package:pocketmind/api/resource_pm_service.dart';
import 'package:pocketmind/providers/http_providers.dart';

part 'pm_service_providers.g.dart';

@Riverpod(keepAlive: true)
AuthPmService authPmService(Ref ref) {
  final http = ref.watch(httpClientProvider);
  return AuthPmService(http);
}

@Riverpod(keepAlive: true)
ResourcePmService resourcePmService(Ref ref) {
  final http = ref.watch(httpClientProvider);
  return ResourcePmService(http);
}
