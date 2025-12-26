import 'package:pocketmind/api/api_constants.dart';
import 'package:pocketmind/api/http_client.dart';
import 'package:pocketmind/api/models/auth_models.dart';
import 'package:pocketmind/util/logger_service.dart';

final String _tag = 'AuthPmService';

class AuthPmService {
  final HttpClient _http;

  AuthPmService(this._http);

  Future<AuthResponse> register({
    required String username,
    required String password,
  }) async {
    final req = AuthRegisterRequest(username: username, password: password);
    final data = await _http.post<Map<String, dynamic>>(
      ApiConstants.authRegister,
      data: req.toJson(),
    );
    return AuthResponse.fromJson(data);
  }

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    final req = AuthLoginRequest(username: username, password: password);
    final data = await _http.post<Map<String, dynamic>>(
      ApiConstants.authLogin,
      data: req.toJson(),
    );
    return AuthResponse.fromJson(data);
  }

  Future<void> logout() async {
    // 当前后端无 logout 接口，客户端只清 token
    PMlog.d(_tag, 'logout: no-op on backend');
  }
}
