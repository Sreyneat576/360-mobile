import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/formatters.dart';

/// Signed-in user snapshot built from `AuthResponse`
/// (dto/response/users/AuthResponse.java). `roles` are role codes such as
/// `ROLE_ADMIN`; `permissions` are the codes checked by `@PreAuthorize`.
class AuthUser {
  const AuthUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.roles,
    required this.permissions,
    this.firstName,
    this.lastName,
    this.phone,
    this.profileImage,
  });

  final int userId;
  final String username;
  final String email;
  final List<String> roles;
  final List<String> permissions;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? profileImage;

  String get displayName {
    final name = [firstName, lastName]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' ');
    return name.isNotEmpty ? name : username;
  }

  String get initials => Fmt.initials(displayName);

  /// Human-readable primary role ("Super Admin", "Admin", "User").
  String get roleLabel {
    if (roles.isEmpty) return 'User';
    final code = roles.first.replaceFirst('ROLE_', '');
    return code
        .split('_')
        .map((p) => p.isEmpty ? p : p[0] + p.substring(1).toLowerCase())
        .join(' ');
  }

  bool get isSuperAdmin => roles.contains('ROLE_SUPER_ADMIN');

  /// Same rule as the web `utils/Auth.hasPermission`: super admin bypasses.
  bool can(String permission) =>
      isSuperAdmin || permissions.contains(permission);

  bool canAny(List<String> codes) => codes.any(can);

  AuthUser copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
    String? email,
  }) =>
      AuthUser(
        userId: userId,
        username: username,
        email: email ?? this.email,
        roles: roles,
        permissions: permissions,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phone: phone ?? this.phone,
        profileImage: profileImage ?? this.profileImage,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'email': email,
        'roles': roles,
        'permissions': permissions,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'profileImage': profileImage,
      };

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        userId: j.intOf('userId') ?? 0,
        username: j.stringOf('username') ?? '',
        email: j.stringOf('email') ?? '',
        roles: j.stringListOf('roles'),
        permissions: j.stringListOf('permissions'),
        firstName: j.stringOf('firstName'),
        lastName: j.stringOf('lastName'),
        phone: j.stringOf('phone'),
        profileImage: j.stringOf('profileImage'),
      );
}

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState {
  const AuthState({required this.status, this.user, this.expiredNotice = false});

  final AuthStatus status;
  final AuthUser? user;

  /// Set when the refresh token was rejected so the login page can explain.
  final bool expiredNotice;

  bool get isSignedIn => status == AuthStatus.signedIn && user != null;

  AuthState copyWith({AuthStatus? status, AuthUser? user, bool? expiredNotice}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        expiredNotice: expiredNotice ?? this.expiredNotice,
      );
}

class AuthController extends Notifier<AuthState> {
  ApiClient get _api => ApiClient.instance;

  @override
  AuthState build() {
    _api.onSessionExpired = _onSessionExpired;
    return const AuthState(status: AuthStatus.unknown);
  }

  /// Restore a previous session from secure storage at app start.
  Future<void> restore() async {
    final access = await TokenStorage.readAccessToken();
    final refresh = await TokenStorage.readRefreshToken();
    final userJson = await TokenStorage.readUser();
    final remember = await TokenStorage.readRememberMe();
    if (!remember || refresh == null || refresh.isEmpty || userJson == null) {
      await TokenStorage.clear();
      state = const AuthState(status: AuthStatus.signedOut);
      return;
    }
    _api.setTokens(accessToken: access, refreshToken: refresh);
    state = AuthState(status: AuthStatus.signedIn, user: AuthUser.fromJson(userJson));
  }

  Future<void> login({
    required String usernameOrEmail,
    required String password,
    bool rememberMe = true,
  }) async {
    final payload = await _api.post(
      '/auth/login',
      body: {'usernameOrEmail': usernameOrEmail.trim(), 'password': password},
      auth: false,
    ) as Map<String, dynamic>;
    await _applyAuthPayload(payload, rememberMe: rememberMe);
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    await _api.post(
      '/auth/register',
      body: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'username': username.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'confirmPassword': confirmPassword,
      },
      auth: false,
    );
  }

  Future<void> forgotPassword(String emailOrUsername) async {
    await _api.post(
      '/auth/forgot-password',
      body: {'emailOrUsername': emailOrUsername.trim()},
      auth: false,
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> logout() async {
    final refresh = _api.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _api.post('/auth/logout', body: {'refreshToken': refresh});
      } on ApiException {
        // Ignore: the token is cleared locally regardless.
      }
    }
    await _clearSession();
  }

  /// Update the locally cached profile (after PUT /users/{id}).
  Future<void> updateLocalUser(AuthUser user) async {
    await TokenStorage.saveUser(user.toJson());
    state = state.copyWith(user: user);
  }

  void clearExpiredNotice() {
    if (state.expiredNotice) state = state.copyWith(expiredNotice: false);
  }

  Future<void> _applyAuthPayload(Map<String, dynamic> payload, {required bool rememberMe}) async {
    final access = payload['accessToken']?.toString() ?? '';
    final refresh = payload['refreshToken']?.toString() ?? '';
    if (access.isEmpty) {
      throw ApiException(message: 'Login response did not include a token');
    }
    final user = AuthUser.fromJson(payload);
    _api.setTokens(accessToken: access, refreshToken: refresh);
    await TokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
    await TokenStorage.saveUser(user.toJson());
    await TokenStorage.saveRememberMe(rememberMe);
    state = AuthState(status: AuthStatus.signedIn, user: user);
  }

  Future<void> _clearSession({bool expired = false}) async {
    _api.clearTokens();
    await TokenStorage.clear();
    state = AuthState(status: AuthStatus.signedOut, expiredNotice: expired);
  }

  void _onSessionExpired() {
    if (state.status == AuthStatus.signedIn) {
      _clearSession(expired: true);
    }
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Convenience: current user or null.
final currentUserProvider = Provider<AuthUser?>((ref) => ref.watch(authProvider).user);
