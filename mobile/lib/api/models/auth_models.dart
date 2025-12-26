import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class AuthRegisterRequest {
  final String username;
  final String password;

  const AuthRegisterRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => _$AuthRegisterRequestToJson(this);
}

@JsonSerializable()
class AuthLoginRequest {
  final String username;
  final String password;

  const AuthLoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => _$AuthLoginRequestToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final String userId;
  final String token;
  final int expiresInSeconds;

  const AuthResponse({
    required this.userId,
    required this.token,
    required this.expiresInSeconds,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
